package en;

class Text extends Entity {
	public static var ALL : Array<Text> = [];

	var data : Entity_Text;
	var wrapper : h2d.Object;
	var bg : h2d.ScaleGrid;
	var tf : h2d.Text;
	var darkCount = 0;
	public var textVisible = true;

	public function new(e:World.Entity_Text) {
		super(e.cx, e.cy);
		data = e;
		ALL.push(this);
		gravityMul = 0;
		darkMode = Stay;
		textVisible = !data.f_startHidden;

		wrapper = new h2d.Object();
		game.scroller.add(wrapper, Const.DP_BG);

		var px = 8;
		var py = 6;
		bg = new h2d.ScaleGrid(Assets.tiles.getTile("uiBox"), 5, 5, wrapper);
		tf = new h2d.Text(Assets.fontPixel, wrapper);
		tf.setPosition(px,py);
		tf.text = e.f_text;
		tf.textColor = e.f_color_int;
		tf.maxWidth = 160;

		bg.width = px*2 + tf.textWidth;
		bg.height = py*2 + tf.textHeight;
		bg.color.setColor( C.addAlphaF( C.interpolateInt(e.f_color_int, 0x322445, 0.8) ) );
		bg.colorAdd = new h3d.Vector();
	}

	override function onDark() {
		super.onDark();
		if( cd.has("playerWasAround") )
			darkCount++;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		wrapper.remove();
	}

	public function reveal() {
		textVisible = true;
		blink(0xffcc00);
		cd.setS("revealAnim",0.5);
	}

	override function postUpdate() {
		super.postUpdate();
		spr.visible = false;
		wrapper.visible = textVisible && (data.f_showAfterDark<=0 || darkCount>=data.f_showAfterDark );
		bg.colorAdd.load( blinkColor );

		wrapper.x = Std.int( data.pixelX - bg.width*0.5 );
		wrapper.y = Std.int( data.pixelY - bg.height*0.5 ) + Std.int(8*cd.getRatio("revealAnim"));
	}

	override function update() {
		super.update();
		if( distCase(hero)<=12 )
			cd.setS("playerWasAround",Const.INFINITE);
	}
}