package en;

class Text extends Entity {
	public static var ALL : Array<Text> = [];

	var wrapper : h2d.Object;

	public function new(e:World.Entity_Text) {
		super(e.cx, e.cy);
		ALL.push(this);
		gravityMul = 0;
		darkMode = Stay;

		wrapper = new h2d.Object();
		game.scroller.add(wrapper, Const.DP_BG);

		var px = 8;
		var py = 6;
		var bg = new h2d.ScaleGrid(Assets.tiles.getTile("uiBox"), 5, 5, wrapper);
		var tf = new h2d.Text(Assets.fontPixel, wrapper);
		tf.setPosition(px,py);
		tf.text = e.f_text;
		tf.textColor = e.f_color_int;
		tf.maxWidth = 160;

		bg.width = px*2 + tf.textWidth;
		bg.height = py*2 + tf.textHeight;
		bg.color.setColor( C.addAlphaF( C.interpolateInt(e.f_color_int, 0x322445, 0.8) ) );

		wrapper.x = Std.int( e.pixelX - bg.width*0.5 );
		wrapper.y = Std.int( e.pixelY - bg.height*0.5 );
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		wrapper.remove();
	}

	override function postUpdate() {
		super.postUpdate();
		spr.visible = false;
	}

	override function update() {
		super.update();
	}
}