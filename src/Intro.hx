class Intro extends dn.Process {
	var f : h2d.Flow;
	var lines = 0;
	var cm = new dn.Cinematic(Const.FPS);
	var texts : h2d.Flow;

	public function new(isEnding:Bool) {
		super(Main.ME);
		createRoot(Main.ME.root);

		f = new h2d.Flow(root);
		f.layout = Vertical;
		f.verticalSpacing = 16;
		f.horizontalAlign = Middle;

		var logo = Assets.tiles.h_get("logo",f);

		texts = new h2d.Flow(f);
		texts.paddingLeft = 5;
		texts.layout = Vertical;
		texts.verticalSpacing = 2;
		texts.horizontalAlign = Middle;


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
		f.setScale(Const.SCALE);
		f.x = M.ceil( w()*0.5 - f.outerWidth*0.5*f.scaleX ) ;
		f.y = M.ceil( h()*0.5 - f.outerHeight*0.5*f.scaleY ) ;
	}

	override function preUpdate() {
		super.preUpdate();
		cm.update(tmod);
	}
}