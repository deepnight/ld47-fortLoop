class Intro extends dn.Process {
	var logo : HSprite;
	var lines = 0;
	var cm = new dn.Cinematic(Const.FPS);
	var texts : h2d.Flow;

	public function new(isEnding:Bool) {
		super(Main.ME);
		createRoot(Main.ME.root);

		logo = Assets.tiles.h_get("logo",root);
		logo.setCenterRatio(0,0.5);

		texts = new h2d.Flow(logo);
		texts.layout = Vertical;


		if( !isEnding ) {
			cm.create({
				tw.createMs(root.alpha, 0>1, 500);
				1000;
				tw.createMs(root.alpha, 0, 1000);
				1000;
				destroy();
				Main.ME.startGame();
			});
			text("A 48h game by Sebastien Benard");
		}
		else {
			tw.createMs(root.alpha, 0>1, 500);
			text("Thank you for playing :)", 0xffcc00);
			text("A 48h game by Sebastien Benard");
			text("for Ludum Dare 47");
			text("www.deepnight.net", 0xffffff);
		}

		dn.Process.resizeAll();
	}

	function text(str:String, c=0x6b648d) {
		var tf = new h2d.Text(Assets.fontPixel, texts);
		tf.text = str;
		tf.textColor = c;
		lines++;
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.SCALE);
		logo.y = M.ceil( h()*0.5/Const.SCALE ) ;
		texts.x = 180;
		texts.y = Std.int( -texts.outerHeight*0.5 );
	}

	override function preUpdate() {
		super.preUpdate();
		cm.update(tmod);
	}
}