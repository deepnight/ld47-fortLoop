class Entity {
    public static var ALL : Array<Entity> = [];
    public static var GC : Array<Entity> = [];

	// Various getters to access all important stuff easily
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;
	public var destroyed(default,null) = false;
	public var ftime(get,never) : Float; inline function get_ftime() return game.ftime;
	var tmod(get,never) : Float; inline function get_tmod() return Game.ME.tmod;
	var utmod(get,never) : Float; inline function get_utmod() return Game.ME.utmod;
	public var hud(get,never) : ui.Hud; inline function get_hud() return Game.ME.hud;
	public var camera(get,never) : Camera; inline function get_camera() return Game.ME.camera;
	public var hero(get,never) : en.Hero; inline function get_hero() return Game.ME.hero;

	public var onGround(get,never): Bool;
		inline function get_onGround() return dy==0 && level.hasCollision(cx,cy+1) && yr==1;

	/** Cooldowns **/
	public var cd : dn.Cooldown;

	/** Cooldowns, unaffected by slowmo (ie. always in realtime) **/
	public var ucd : dn.Cooldown;

	/** Temporary gameplay affects **/
	var affects : Map<Affect,Float> = new Map();

	/** Unique identifier **/
	public var uid : Int;

	// Position in the game world
    public var cx = 0;
    public var cy = 0;
    public var xr = 0.5;
    public var yr = 1.0;

	// Velocities
    public var dx = 0.;
	public var dy = 0.;

	public var gravityMul = 1.0;

	// Uncontrollable bump velocities, usually applied by external
	// factors (think of a bumper in Sonic for example)
    public var bdx = 0.;
	public var bdy = 0.;

	// Velocities + bump velocities
	public var dxTotal(get,never) : Float; inline function get_dxTotal() return dx+bdx;
	public var dyTotal(get,never) : Float; inline function get_dyTotal() return dy+bdy;

	// Multipliers applied on each frame to normal velocities
	public var frictX = 0.82;
	public var frictY = 0.82;

	// Multiplier applied on each frame to bump velocities
	public var bumpFrict = 0.93;

	public var hei(default,set) : Float = Const.GRID;
	inline function set_hei(v) { invalidateDebugBounds=true;  return hei=v; }

	public var radius(default,set) = Const.GRID*0.3;
	inline function set_radius(v) { invalidateDebugBounds=true;  return radius=v; }

	public var circularCollisions = false;

	/** Horizontal direction, can only be -1 or 1 **/
	public var dir(default,set) = 1;

	// Sprite transformations
	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;
	public var sprSquashX = 1.0;
	public var sprSquashY = 1.0;
	public var entityVisible = true;

	// Hit points
	public var life(default,null) : Int;
	public var maxLife(default,null) : Int;
	public var lastDmgSource(default,null) : Null<Entity>;

	public var lastHitDirFromSource(get,never) : Int;
	inline function get_lastHitDirFromSource() return lastDmgSource==null ? -dir : -dirTo(lastDmgSource);

	public var lastHitDirToSource(get,never) : Int;
	inline function get_lastHitDirToSource() return lastDmgSource==null ? dir : dirTo(lastDmgSource);

	// Visual components
    public var spr : HSprite;
	public var baseColor : h3d.Vector;
	public var blinkColor : h3d.Vector;
	public var colorMatrix(get,set) : Null<h3d.Matrix>;

	// Debug stuff
	var debugLabel : Null<h2d.Text>;
	var debugBounds : Null<h2d.Graphics>;
	var invalidateDebugBounds = false;

	// Coordinates getters, for easier gameplay coding
	public var footX(get,never) : Float; inline function get_footX() return (cx+xr)*Const.GRID;
	public var footY(get,never) : Float; inline function get_footY() return (cy+yr)*Const.GRID;
	public var headX(get,never) : Float; inline function get_headX() return footX;
	public var headY(get,never) : Float; inline function get_headY() return footY-hei;
	public var centerX(get,never) : Float; inline function get_centerX() return footX;
	public var centerY(get,never) : Float; inline function get_centerY() return footY-hei*0.5;
	public var prevFrameFootX : Float = -Const.INFINITE;
	public var prevFrameFootY : Float = -Const.INFINITE;
	var fallHighestCy = 0.;

	public var darkMode = Destroy;
	public var climbing = false;
	var grabbedItem : Null<en.Item>;

	var actions : Array<{ id:String, cb:Void->Void, t:Float }> = [];

    public function new(x:Int, y:Int) {
        uid = Const.NEXT_UNIQ;
		ALL.push(this);

		cd = new dn.Cooldown(Const.FPS);
		ucd = new dn.Cooldown(Const.FPS);
        setPosCase(x,y);

        spr = new HSprite(Assets.tiles);
		Game.ME.scroller.add(spr, Const.DP_MAIN);
		spr.colorAdd = new h3d.Vector();
		baseColor = new h3d.Vector();
		blinkColor = new h3d.Vector();
		spr.setCenterRatio(0.5,1);
		colorMatrix = h3d.Matrix.I();

		initLife(1);

		if( ui.Console.ME.hasFlag("bounds") )
			enableBounds();
	}

	public function isOutOfTheGame() {
		return game.dark && darkMode!=Stay;
	}

	inline function set_colorMatrix(m) {
		return destroyed ? null : spr.colorMatrix = m;
	}

	inline function get_colorMatrix() {
		return destroyed ? null : spr.colorMatrix;
	}

	public function initLife(v) {
		life = maxLife = v;
	}

	public function hit(dmg:Int, from:Null<Entity>) {
		if( !isAlive() || dmg<=0 )
			return;

		life = M.iclamp(life-dmg, 0, maxLife);
		lastDmgSource = from;
		onDamage(dmg, from);
		if( life<=0 )
			onDie();
	}

	public function kill(by:Null<Entity>) {
		if( isAlive() )
			hit(life,by);
	}

	function onDamage(dmg:Int, from:Entity) {
	}

	function onDie() {
		destroy();
	}

	inline function set_dir(v) {
		return dir = v>0 ? 1 : v<0 ? -1 : dir;
	}

	public inline function isAlive() {
		return !destroyed && life>0;
	}

	public function setPosCase(x:Int, y:Int) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
		onPosManuallyChanged();
	}

	public function setPosPixel(x:Float, y:Float) {
		cx = Std.int(x/Const.GRID);
		cy = Std.int(y/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;
		yr = (y-cy*Const.GRID)/Const.GRID;
		onPosManuallyChanged();
	}

	function onPosManuallyChanged() {
		if( M.dist(footX,footY,prevFrameFootX,prevFrameFootY) > Const.GRID*2 ) {
			prevFrameFootX = footX;
			prevFrameFootY = footY;
		}
	}

	public function bump(x:Float,y:Float) {
		bdx+=x;
		bdy+=y;
	}

	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public function is<T:Entity>(c:Class<T>) return Std.is(this, c);
	public function as<T:Entity>(c:Class<T>) : T return Std.downcast(this, c);

	public inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	public inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);
	public inline function pretty(v,?p=1) return M.pretty(v,p);

	public inline function dirTo(e:Entity) return e.centerX<centerX ? -1 : 1;
	public inline function dirToAng() return dir==1 ? 0. : M.PI;
	public inline function getMoveAng() return Math.atan2(dyTotal,dxTotal);

	public inline function distCase(e:Entity) return M.dist(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
	public inline function distCaseFree(tcx:Int, tcy:Int, ?txr=0.5, ?tyr=0.5) return M.dist(cx+xr, cy+yr, tcx+txr, tcy+tyr);
	public inline function distCaseX(e:Entity) return M.fabs( (cx+xr) - (e.cx+e.xr) );
	public inline function distCaseY(e:Entity) return M.fabs( (cy+yr) - (e.cy+e.yr) );

	function canSeeThrough(x,y) {
		return !level.hasCollision(x,y);
	}
	public function sightCheck(e:Entity) {
		if( destroyed || e.destroyed )
			return false;
		return dn.Bresenham.checkThinLine(cx,cy,e.cx,e.cy, canSeeThrough);
	}

	public inline function distPx(e:Entity) return M.dist(footX, footY, e.footX, e.footY);
	public inline function distPxFree(x:Float, y:Float) return M.dist(footX, footY, x, y);

	public function makePoint() return new CPoint(cx,cy, xr,yr);

    public inline function destroy() {
        if( !destroyed ) {
            destroyed = true;
            GC.push(this);
        }
    }

    public function dispose() {
        ALL.remove(this);

		baseColor = null;
		blinkColor = null;
		colorMatrix = null;

		spr.remove();
		spr = null;

		if( debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}

		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}

		cd.destroy();
		cd = null;
    }

	public inline function debugFloat(v:Float, ?c=0xffffff) {
		debug( pretty(v), c );
	}
	public inline function debug(?v:Dynamic, ?c=0xffffff) {
		if( v==null && debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}
		if( v!=null ) {
			if( debugLabel==null )
				debugLabel = new h2d.Text(Assets.fontTiny, Game.ME.scroller);
			debugLabel.text = Std.string(v);
			debugLabel.textColor = c;
		}
	}

	public function disableBounds() {
		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}
	}


	public function enableBounds() {
		if( debugBounds==null ) {
			debugBounds = new h2d.Graphics();
			game.scroller.add(debugBounds, Const.DP_TOP);
		}
		invalidateDebugBounds = true;
	}

	function renderBounds() {
		var c = Color.makeColorHsl((uid%20)/20, 1, 1);
		debugBounds.clear();

		// Radius
		debugBounds.lineStyle(1, c, 0.8);
		debugBounds.drawCircle(0,-radius,radius);

		// Hei
		debugBounds.lineStyle(1, c, 0.5);
		debugBounds.drawRect(-radius,-hei,radius*2,hei);

		// Feet
		debugBounds.lineStyle(1, 0xffffff, 1);
		var d = Const.GRID*0.2;
		debugBounds.moveTo(-d,0);
		debugBounds.lineTo(d,0);
		debugBounds.moveTo(0,-d);
		debugBounds.lineTo(0,0);

		// Center
		debugBounds.lineStyle(1, c, 0.3);
		debugBounds.drawCircle(0, -hei*0.5, 3);

		// Head
		debugBounds.lineStyle(1, c, 0.3);
		debugBounds.drawCircle(0, headY-footY, 3);
	}

	function chargeAction(id:String, sec:Float, cb:Void->Void) {
		if( isChargingAction(id) )
			cancelAction(id);
		if( sec<=0 )
			cb();
		else
			actions.push({ id:id, cb:cb, t:sec});
	}

	public function isChargingAction(?id:String) {
		if( id==null )
			return actions.length>0;

		for(a in actions)
			if( a.id==id )
				return true;

		return false;
	}

	public function cancelAction(?id:String) {
		if( id==null )
			actions = [];
		else {
			var i = 0;
			while( i<actions.length ) {
				if( actions[i].id==id )
					actions.splice(i,1);
				else
					i++;
			}
		}
	}

	function updateActions() {
		var i = 0;
		while( i<actions.length ) {
			var a = actions[i];
			a.t -= tmod/Const.FPS;
			if( a.t<=0 ) {
				actions.splice(i,1);
				if( isAlive() )
					a.cb();
			}
			else
				i++;
		}
	}


	public inline function hasAffect(k:Affect) {
		return affects.exists(k) && affects.get(k)>0;
	}

	public inline function getAffectDurationS(k:Affect) {
		return hasAffect(k) ? affects.get(k) : 0.;
	}

	public function setAffectS(k:Affect, t:Float, ?allowLower=false) {
		if( affects.exists(k) && affects.get(k)>t && !allowLower )
			return;

		if( t<=0 )
			clearAffect(k);
		else {
			var isNew = !hasAffect(k);
			affects.set(k,t);
			if( isNew )
				onAffectStart(k);
		}
	}

	public function mulAffectS(k:Affect, f:Float) {
		if( hasAffect(k) )
			setAffectS(k, getAffectDurationS(k)*f, true);
	}

	public function clearAffect(k:Affect) {
		if( hasAffect(k) ) {
			affects.remove(k);
			onAffectEnd(k);
		}
	}

	function updateAffects() {
		for(k in affects.keys()) {
			var t = affects.get(k);
			t-=1/Const.FPS * tmod;
			if( t<=0 )
				clearAffect(k);
			else
				affects.set(k,t);
		}
	}

	function onAffectStart(k:Affect) {}
	function onAffectEnd(k:Affect) {}

	public function isConscious() {
		return !hasAffect(Stun) && isAlive();
	}

	public function blink(c:UInt) {
		blinkColor.setColor(c);
		cd.setS("keepBlink",0.06);
	}


	public function setSquashX(v:Float) {
		sprSquashX = v;
		sprSquashY = 2-v;
	}
	public function setSquashY(v:Float) {
		sprSquashX = 2-v;
		sprSquashY = v;
	}

    public function preUpdate() {
		ucd.update(utmod);
		cd.update(tmod);
		updateAffects();
		updateActions();
	}

	public function onDark() {
		switch darkMode {
			case Stay:
			case Destroy, DestroyAndHide:
				destroy();
				return;

			case GoOutOfGame:
		}

		cd.setS("colorDarken",1);
	}

	public function onLight() {
		colorMatrix.identity();
		spr.filter = null;
	}

    public function postUpdate() {
        spr.x = (cx+xr)*Const.GRID;
        spr.y = (cy+yr)*Const.GRID;
        spr.scaleX = dir*sprScaleX * sprSquashX;
        spr.scaleY = sprScaleY * sprSquashY;
		spr.visible = entityVisible;
		spr.alpha = level.fakeLight;

		sprSquashX += (1-sprSquashX) * 0.2;
		sprSquashY += (1-sprSquashY) * 0.2;

		if( game.dark && darkMode!=Stay && darkMode!=DestroyAndHide && spr.filter==null )
			spr.filter = new dn.heaps.filter.PixelOutline(Const.DARK_LIGHT_COLOR, true);

		if( game.dark && darkMode==DestroyAndHide )
			spr.visible = false;

		if( game.dark && darkMode==Stay )
			colorMatrix.load( C.getColorizeMatrixH2d(Const.DARK_COLOR, 0.5*(1-cd.getRatio("colorDarken"))) );

		// Blink
		if( !cd.has("keepBlink") ) {
			blinkColor.r*=Math.pow(0.60, tmod);
			blinkColor.g*=Math.pow(0.55, tmod);
			blinkColor.b*=Math.pow(0.50, tmod);
		}

		// Color adds
		spr.colorAdd.load(baseColor);
		spr.colorAdd.r += blinkColor.r;
		spr.colorAdd.g += blinkColor.g;
		spr.colorAdd.b += blinkColor.b;

		// Debug label
		if( debugLabel!=null ) {
			debugLabel.x = Std.int(footX - debugLabel.textWidth*0.5);
			debugLabel.y = Std.int(footY+1);
		}

		// Debug bounds
		if( debugBounds!=null ) {
			if( invalidateDebugBounds ) {
				invalidateDebugBounds = false;
				renderBounds();
			}
			debugBounds.x = footX;
			debugBounds.y = footY;
		}
	}

	public function finalUpdate() {
		prevFrameFootX = footX;
		prevFrameFootY = footY;
	}

	public inline function lockControlS(t:Float) {
		if( !destroyed )
			cd.setS("ctrlLocked",t);
	}

	public inline function controlsLocked() {
		return destroyed || cd.has("ctrlLocked");
	}

	public function startClimbing() {
		climbing = true;
		bdx*=0.2;
		bdy*=0.2;
		dx*=0.3;
		dy*=0.3;
	}

	public function stopClimbing() {
		climbing = false;
	}


	public inline function isGrabbingAnything() {
		return isAlive() && grabbedItem!=null && grabbedItem.isAlive();
	}

	public inline function isGrabbingType(k:Enum_ItemType) {
		return isGrabbingAnything() && grabbedItem.type==k;
	}

	public inline function isGrabbing(e:en.Item) {
		return isAlive() && grabbedItem==e;
	}

	public function grabItem(i:en.Item) {
		dropItem();

		if( i!=null && i.isAlive() ) {
			i.inVault = false;
			grabbedItem = i;
		}
	}

	public function dropItem() : Null<en.Item> {
		if( grabbedItem==null || !grabbedItem.isAlive() ) {
			grabbedItem = null;
			return null;
		}

		var old = grabbedItem;
		grabbedItem.cd.setS("pickLock",0.5);
		grabbedItem = null;
		return old;
	}


	function onLand(fallCHei:Float) {
		bdy = 0;
	}

	public function fixedUpdate() {} // runs at a "guaranteed" 30 fps

	function hasCircularCollisions() {
		return isAlive() && circularCollisions && !isOutOfTheGame();
	}

	function hasCircularCollisionsWith(e:Entity) {
		return e!=this && hasCircularCollisions() && e.hasCircularCollisions();
	}

	public function update() { // runs at an unknown fps
		// Circular collisions
		if( hasCircularCollisions() ) {
			var d = 0.;
			var a = 0.;
			for(e in ALL)
				if( hasCircularCollisionsWith(e) ) {
					d = M.dist(centerX,centerY, e.centerX,e.centerY);
					if( d<=radius+e.radius ) {
						a = Math.atan2(e.centerY-centerY, e.centerX-centerX);
						var repel = ( 1 - d / (radius+e.radius) ) * 0.02 * tmod;
						e.dx += Math.cos(a)*repel;
						// if( !e.onGround )
							// e.dy += Math.sin(a)*repel;

						dx -= Math.cos(a)*repel;
						// if( !onGround )
							// dy -= Math.sin(a)*repel;
					}
				}
		}

		// X
		var steps = M.ceil( M.fabs(dxTotal*tmod) );
		var step = dxTotal*tmod / steps;
		while( steps>0 ) {
			xr+=step;

			if( level.hasCollision(cx+1,cy) && xr>=0.7 ) {
				xr = 0.7;
				dx *= Math.pow(0.5,tmod);
			}

			if( level.hasCollision(cx-1,cy) && xr<=0.3 ) {
				xr = 0.3;
				dx *= Math.pow(0.5,tmod);
			}

			while( xr>1 ) { xr--; cx++; }
			while( xr<0 ) { xr++; cx--; }
			steps--;
		}
		dx*=Math.pow(frictX,tmod);
		bdx*=Math.pow(bumpFrict,tmod);
		if( M.fabs(dx)<=0.0005*tmod ) dx = 0;
		if( M.fabs(bdx)<=0.0005*tmod ) bdx = 0;

		// Y
		if( !onGround && !climbing )
			dy += gravityMul*Const.GRAVITY * tmod;
		var steps = M.ceil( M.fabs(dyTotal*tmod) );
		var step = dyTotal*tmod / steps;
		while( steps>0 ) {
			yr+=step;

			if( onGround || dy<=0 )
				fallHighestCy = cy+yr;

			if( !climbing && level.hasCollision(cx,cy-1) && yr<0.5 ) {
				yr = 0.5;
				dy *= Math.pow(0.5,tmod);
			}

			if( level.hasCollision(cx,cy+1) && yr>=1 ) {
				dy = 0;
				yr = 1;
				onLand(cy+yr-fallHighestCy);
			}

			while( yr>1 ) { yr--; cy++; }
			while( yr<0 ) { yr++; cy--; }
			steps--;
		}
		dy*=Math.pow(frictY,tmod);
		bdy*=Math.pow(bumpFrict,tmod);
		if( M.fabs(dy)<=0.0005*tmod ) dy = 0;
		if( M.fabs(bdy)<=0.0005*tmod ) bdy = 0;


		// Lost item
		if( grabbedItem!=null && !grabbedItem.isAlive() )
			dropItem();

		// Move grabbed item
		if( grabbedItem!=null ) {
			grabbedItem.setPosCase(cx,cy);
			grabbedItem.xr = xr;
			grabbedItem.yr = yr;
			grabbedItem.cancelVelocities();
		}


		#if debug
		if( ui.Console.ME.hasFlag("affect") ) {
			var all = [];
			for(k in affects.keys())
				all.push( k+"=>"+M.pretty( getAffectDurationS(k) , 1) );
			debug(all);
		}

		if( ui.Console.ME.hasFlag("bounds") && debugBounds==null )
			enableBounds();

		if( !ui.Console.ME.hasFlag("bounds") && debugBounds!=null )
			disableBounds();
		#end
    }
}