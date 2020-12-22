import Data;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;
	public var controller : dn.heaps.Controller;
	public var ca : dn.heaps.Controller.ControllerAccess;

	public function new(s:h2d.Scene) {
		super();
		ME = this;

        createRoot(s);

		// Engine settings
		hxd.Timer.wantedFPS = Const.FPS;
		engine.backgroundColor = 0xff<<24|Const.DARK_COLOR;
        #if( hl && !debug )
        engine.fullScreen = true;
        #end

		// Resources
		#if(hl && debug)
		hxd.Res.initLocal();
        #else
        hxd.Res.initEmbed();
        #end

        // Hot reloading (CastleDB)
		#if debug
        hxd.res.Resource.LIVE_UPDATE = true;
        hxd.Res.data.watch(function() {
            delayer.cancelById("cdb");

            delayer.addS("cdb", function() {
            	Data.load( hxd.Res.data.entry.getBytes().toString() );
            	if( Game.ME!=null )
                    Game.ME.onCdbReload();
            }, 0.2);
        });

        // Hot reloading (LDtk)
        hxd.Res.world.world.watch(function() {
            delayer.cancelById("ldtk");

            delayer.addS("ldtk", function() {
            	if( Game.ME!=null )
                    Game.ME.onLedReload();
            }, 0.2);
        });
		#end

		// Assets & data init
		hxd.snd.Manager.get();
		Assets.init();
		new ui.Console(Assets.fontTiny, s);
		Lang.init("en");
		Data.load( hxd.Res.data.entry.getText() );

		// Game controller
		controller = new dn.heaps.Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(AXIS_LEFT_Y_NEG, Key.UP, Key.Z, Key.W);
		controller.bind(AXIS_LEFT_Y_POS, Key.DOWN, Key.S);
		controller.bind(X, Key.SPACE, Key.F, Key.E); // throw item
		controller.bind(A, Key.UP, Key.Z, Key.W); // jump
		controller.bind(Y, Key.X, Key.TAB, Key.ENTER); // darkness
		controller.bind(SELECT, Key.R); // Restart
		controller.bind(START, Key.N);

		var f = new dn.heaps.filter.OverlayTexture(Deep);
		f.alpha = 0.3;
		f.autoUpdateSize = ()->return Const.SCALE;
		Boot.ME.s2d.filter = f;

		// Start
		#if js
			new dn.heaps.GameFocusHelper(Boot.ME.s2d, Assets.fontMedium);
			delayer.addF( startGame, 1 );
		#else
			startGame();
		#end
	}

	public function startIntro() {
		new Intro(false);
	}

	public function startGame() {
		if( Game.ME!=null ) {
			Game.ME.destroy();
			delayer.addF(function() {
				new Game();
			}, 5);
		}
		else
			new Game();
	}

	override public function onResize() {
		super.onResize();

		// Auto scaling
		Const.SCALE = dn.heaps.Scaler.bestFit_i(350,200);
		Const.UI_SCALE = Const.SCALE;
	}

    override function update() {
		Assets.tiles.tmod = tmod;
        super.update();
    }
}