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

	/** LEd world data **/
	public var world : World;

	public var hero: en.Hero;

	public var dark(default,null) : Bool;
	var darkMask : h2d.Bitmap;
	public var autoSwitchS(default,null) : Float = Const.LIGHT_DURATION;
	var darkHalo : HSprite;

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
		level = new Level(world.all_levels.Combat);
		level.attachMainEntities();
		camera.trackTarget(hero, true);

		darkMask = new h2d.Bitmap( h2d.Tile.fromColor(Const.DARK_COLOR) );
		root.add(darkMask, Const.DP_TOP);

		darkHalo = Assets.tiles.h_get("darkHalo");
		root.add(darkHalo,Const.DP_TOP);
		darkHalo.alpha = 0.;

		Process.resizeAll();
		setDarkness(false,true);
		level.attachLightEntities();
	}

	/**
		Called when the CastleDB changes on the disk, if hot-reloading is enabled in Boot.hx
	**/
	public function onCdbReload() {
	}

	/**
		Called when LEd world changes on the disk, if hot-reloading is enabled in Boot.hx
	**/
	public function onLedReload() {
		Main.ME.startGame();
	}

	override function onResize() {
		super.onResize();
		scroller.setScale(Const.SCALE);
		darkHalo.scaleX = w()/darkHalo.tile.width;
		darkHalo.scaleY = h()/darkHalo.tile.height;
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
				tw.terminateWithoutCallbacks(darkMask.alpha);
				darkMask.visible = false;
				level.burn.visible = true;
				tw.createMs(level.burn.alpha, 0.5>0, 1000, TEaseIn);
				fx.flashBangS(0xffcc00, 0.3, 2);
				camera.shakeS(2, 0.3);
				tw.createMs(camera.zoom, 1, 700, TElasticEnd);
			}
		}

		// Doors
		if( !dark )
			delayer.addS("doors", ()->{
				for(e in en.Door.ALL)
					if( !e.destroyed && !e.needKey )
						e.setClosed(false);
			}, init ? 0 : 0.2);

		// Timer
		autoSwitchS = dark ? Const.DARKNESS_DURATION : Const.LIGHT_DURATION;

		// Entities callback
		for(e in Entity.ALL)
			if( !e.destroyed )
				if( dark )
					e.onDark();
				else
					e.onLight();

		// Init entities
		if( dark )
			level.attachLightEntities();

		return dark;
	}

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
	public inline function stopFrame() {
		ucd.setS("stopFrame", 0.2);
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
			if( ca.isKeyboardPressed(K.K) )
				for(e in en.Mob.ALL)
					e.destroy();
			#end

			// Restart
			if( ca.selectPressed() )
				Main.ME.startGame();
		}

		// Auto light/dark switch
		autoSwitchS -= tmod/Const.FPS;
		if( !dark && autoSwitchS<=0.5 && !cd.hasSetS("autoDarkBefore",2) ) {
			for(e in en.Door.ALL)
				e.setClosed(true);
		}
		if( autoSwitchS<=0 )
			setDarkness(!dark);
	}
}


