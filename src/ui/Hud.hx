package ui;

class Hud extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;

	var flow : h2d.Flow;
	// var ammo : h2d.Flow;
	// var life : h2d.Flow;
	var invalidated = true;

	public function new() {
		super(Game.ME);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.ColorMatrix(); // force pixel perfect rendering

		flow = new h2d.Flow(root);
		flow.horizontalSpacing = 16;
		// life = new h2d.Flow(flow);
		// ammo = new h2d.Flow(flow);
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.UI_SCALE);
		flow.x = w()*0.5/root.scaleX - flow.outerWidth*0.5;
		flow.y = h()/root.scaleY - flow.outerHeight-8;
	}

	public inline function invalidate() invalidated = true;

	function render() {
		var hero = game.hero;

		// life.removeChildren();
		// for(i in 0...hero.maxLife)
		// 	Assets.tiles.h_get(i+1<=hero.life ? "iconLifeOn" : "iconLifeOff", life);

		// ammo.removeChildren();
		// for(i in 0...hero.maxAmmo)
		// 	Assets.tiles.h_get(i+1<=hero.ammo ? "iconAmmoOn" : "iconAmmoOff", ammo);

		onResize();
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
