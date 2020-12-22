import dn.Process;
import hxd.Key;

class Game extends Process {
	public static var ME : Game;

	/** Game controller (pad or keyboard) **/
	public var ca : dn.heaps.Controller.ControllerAccess;

	/** Particles **/
	public var fx : Fx;

	/** Basic viewport control **/
	public var camera : Camera;

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller : h2d.Layers;

	/** Level data **/
	public var level : Level;

	/** UI **/
	public var hud : ui.Hud;

	/** Slow mo internal values**/
	var curGameSpeed = 1.0;
	var slowMos : Map<String, { id:String, t:Float, f:Float }> = new Map();

	/** LDtk world data **/
	public var world : World;

	public var hero: en.Hero;

	public var dark(default,null) : Bool;
	var darkMask : h2d.Bitmap;
	var darkHalo : HSprite;
	var fadeMask : h2d.Bitmap;

	public var curLevelIdx = 0;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);

		scroller = new h2d.Layers();
		root.add(scroller, Const.DP_BG);
		scroller.filter = new h2d.filter.ColorMatrix(); // force rendering for pixel perfect

		world = new World( hxd.Res.world.world.entry.getText() );
		camera = new Camera();
		fx = new Fx();
		hud = new ui.Hud();

		darkMask = new h2d.Bitmap( h2d.Tile.fromColor(Const.DARK_COLOR) );
		root.add(darkMask, Const.DP_TOP);

		fadeMask = new h2d.Bitmap( h2d.Tile.fromColor(Const.DARK_COLOR) );
		root.add(fadeMask, Const.DP_TOP);

		darkHalo = Assets.tiles.h_get("darkHalo");
		root.add(darkHalo,Const.DP_TOP);
		darkHalo.alpha = 0.;

		#if debug
		startLevel(3);
		#else
		startLevel(0);
		#end
	}


	function fadeIn() {
		tw.terminateWithoutCallbacks(fadeMask.alpha);
		fadeMask.visible = true;
		tw.createMs( fadeMask.alpha, 1>0, 800, TEaseIn ).end( ()->fadeMask.visible = false );
	}

	function fadeOut() {
		tw.terminateWithoutCallbacks(fadeMask.alpha);
		fadeMask.visible = true;
		tw.createMs( fadeMask.alpha, 0>1, 2000, TEaseIn );
	}

	public function nextLevel() {
		startLevel(curLevelIdx+1);
	}

	public function notify(str:String, col=0x889fcd) {
		var f = new h2d.Flow();
		root.add(f, Const.DP_UI);
		var tf = new h2d.Text(Assets.fontPixel, f);
		tf.scale(Const.SCALE*2);
		tf.text = str;
		tf.textColor = col;
		f.x = Std.int( w()*0.5 - f.outerWidth*0.5 );
		f.y = Std.int( h()*0.4 - f.outerHeight*0.5 );

		tw.createMs(tf.alpha, 0>1, 400);
		tw.createMs(tf.x, w()*0.5 > 0, TEaseOut, 200).end( ()->{
			tw.createMs(tf.x, 1000 | -w()*0.5, TEaseIn, 200).end( ()->{
				f.remove();
			});
		});
	}

	function startLevel(idx=-1, ?data:World_Level) {
		curLevelIdx = idx;
		cd.unset("levelComplete");
		fadeIn();

		// Cleanup
		if( level!=null )
			level.destroy();
		for(e in Entity.ALL)
			e.destroy();
		fx.clear();
		gc();
		tw.terminateWithoutCallbacks(camera.zoom);
		camera.zoom = 1;

		// End game
		if( data==null && idx>=world.levels.length ) {
			destroy();
			new Intro(true);
			return;
		}

		// Init
		level = new Level( data!=null ? data : world.levels[curLevelIdx] );
		level.attachMainEntities();
		setDarkness(false,true);

		camera.trackTarget(hero, true);
		Process.resizeAll();
	}

	/**
		Called when the CastleDB changes on the disk, if hot-reloading is enabled in Boot.hx
	**/
	public function onCdbReload() {
	}

	/**
		Called when LDtk world changes on the disk, if hot-reloading is enabled in Boot.hx
	**/
	public function onLedReload() {
		world.parseJson( hxd.Res.world.world.entry.getText() );
		startLevel(curLevelIdx);
	}

	override function onResize() {
		super.onResize();
		scroller.setScale(Const.SCALE);

		darkHalo.scaleX = w()/darkHalo.tile.width;
		darkHalo.scaleY = h()/darkHalo.tile.height;

		fadeMask.scaleX = w()/fadeMask.tile.width;
		fadeMask.scaleY = h()/fadeMask.tile.height;
	}


	public function setDarkness(v:Bool, init=false) {
		dark = v;
		level.setDark( dark );
		camera.targetTrackOffY = Const.GRID  * (dark ? -1 : -2);

		// Visual effect
		if( init )
			level.burn.visible = false;
		else {
			if( dark ) {
				notify("Looped back in time...");
				camera.shakeS(2, 0.5);
				// Black effect
				// darkMask.visible = true;
				// darkMask.scaleX = w();
				// darkMask.scaleY = h();
				// tw.createMs(darkMask.alpha, 0.7>0, 2000, TEaseInt);
				tw.createMs(camera.zoom, 1>1.2, 1500, TEase);
			}
			else {
				// Super bright effect
				notify("Go!");
				tw.terminateWithoutCallbacks(darkMask.alpha);
				darkMask.visible = false;
				level.burn.visible = true;
				tw.createMs(level.burn.alpha, 0.5>0, 1000, TEaseIn);
				fx.flashBangS(0xffcc00, 0.3, 2);
				camera.shakeS(2, 0.3);
				tw.createMs(camera.zoom, 1, 700, TElasticEnd);
			}
		}

		if( dark )
			Assets.SLIB.dark0(0.5);
		else if( !init )
			Assets.SLIB.light0(0.5);

		// Doors
		if( dark ) {
			Assets.SLIB.door0(1);
			for(e in en.Door.ALL)
				e.setClosed(true);
		}
		else
			delayer.addS("doors", ()->{
				for(e in en.Door.ALL)
					if( !e.destroyed && !e.needKey )
						e.setClosed(false);
			}, init ? 0 : 0.2);

		// Entities callback
		for(e in Entity.ALL)
			if( !e.destroyed )
				if( dark )
					e.onDark();
				else
					e.onLight();

		// Init entities
		if( init || dark )
			level.attachLightEntities();

		// Timer
		cd.unset("autoSwitch"); // BUG cd ratio false
		if( en.Torch.any() )
			cd.setS("autoSwitch", dark ? Const.DARKNESS_DURATION : Const.LIGHT_DURATION);
		else
			cd.setS("autoSwitch", Const.INFINITE);

		return dark;
	}

	public function getAutoSwitchS() return cd.getS("autoSwitch");
	public function getAutoSwitchRatio() return M.fclamp( cd.getRatio("autoSwitch"), 0, 1 );

	function gc() {
		if( Entity.GC==null || Entity.GC.length==0 )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		gc();
	}


	/**
		Start a cumulative slow-motion effect that will affect `tmod` value in this Process
		and its children.

		@param sec Realtime second duration of this slowmo
		@param speedFactor Cumulative multiplier to the Process `tmod`
	**/
	public function addSlowMo(id:String, sec:Float, speedFactor=0.3) {
		if( slowMos.exists(id) ) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		}
		else
			slowMos.set(id, { id:id, t:sec, f:speedFactor });
	}


	function updateSlowMos() {
		// Timeout active slow-mos
		for(s in slowMos) {
			s.t -= utmod * 1/Const.FPS;
			if( s.t<=0 )
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for(s in slowMos)
			targetGameSpeed*=s.f;
		curGameSpeed += (targetGameSpeed-curGameSpeed) * (targetGameSpeed>curGameSpeed ? 0.2 : 0.6);

		if( M.fabs(curGameSpeed-targetGameSpeed)<=0.001 )
			curGameSpeed = targetGameSpeed;
	}


	/**
		Pause briefly the game for 1 frame: very useful for impactful moments,
		like when hitting an opponent in Street Fighter ;)
	**/
	public inline function stopFrame(t=0.2) {
		ucd.setS("stopFrame", t);
	}

	override function preUpdate() {
		super.preUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
	}

	override function postUpdate() {
		super.postUpdate();


		for(e in Entity.ALL) if( !e.destroyed ) e.postUpdate();
		for(e in Entity.ALL) if( !e.destroyed ) e.finalUpdate();
		gc();

		// Update slow-motions
		updateSlowMos();
		baseTimeMul = ( 0.2 + 0.8*curGameSpeed ) * ( ucd.has("stopFrame") ? 0.3 : 1 );
		Assets.tiles.tmod = tmod;

		darkHalo.alpha += ( (dark ? 0.4 : 0.) - darkHalo.alpha ) * 0.03;
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.fixedUpdate();
	}

	override function update() {
		super.update();

		for(e in Entity.ALL) if( !e.destroyed ) e.update();

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			#if hl
			// Exit
			if( ca.isKeyboardPressed(Key.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press ESCAPE again to exit."));
				else
					hxd.System.exit();
			#end

			#if debug
			if( ca.isKeyboardPressed(K.N) )
				nextLevel();

			if( ca.isKeyboardPressed(K.K) )
				for(e in en.Mob.ALL)
					e.destroy();
			#end

			// Restart
			if( ca.selectPressed() ) {
				#if debug
				if( ca.isKeyboardDown(K.SHIFT) || ca.isKeyboardDown(K.CTRL) )
					startLevel(0);
				else
				#end
				startLevel(curLevelIdx);
			}
		}

		// Auto light/dark switch
		if( en.Torch.any() && !cd.has("autoSwitch") )
			setDarkness(!dark);

		// Level complete
		if( hero.isAlive() && !cd.has("levelComplete") ) {
			var win = true;
			for(e in en.Vault.ALL)
				if( !e.isGrabbingAnything() ) {
					win = false;
					break;
				}

			if( win ) {
				if( dark )
					setDarkness(false);

				Assets.SLIB.complete(1);

				// for(e in en.Mob.ALL)
				// 	if( e.isAlive() )
				// 		e.kill(null);

				for(e in en.Item.ALL)
					if( e.isAlive() && !e.inVault )
						e.destroy();

				cd.setS("autoSwitch", Const.INFINITE);
				fx.flashBangS(0xffcc00, 0.4, 1);
				cd.setS("levelComplete", Const.INFINITE);
				cd.setS("autoNext",2);
				tw.createMs(camera.zoom, 1.3, 2000);
				fadeOut();
			}
		}

		if( cd.has("levelComplete") && !cd.has("autoNext") )
			startLevel(curLevelIdx+1);
	}
}


