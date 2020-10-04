package en;

class Torch extends Entity {
	public static var ALL : Array<Torch> = [];

	public function new(e:World_Entity) {
		super(e.cx, e.cy);
		ALL.push(this);
		gravityMul = 0;
		// darkMode = DestroyAndHide;
		game.scroller.add(spr, Const.DP_BG);

		spr.set("torchOff");
	}

	public static function any() {
		for(e in ALL)
			if( e.isAlive() )
				return true;
		return false;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();

		spr.filter = null;
		spr.alpha = 0.3;

		if( !isOutOfTheGame() && !cd.hasSetS("fx",0.1) )
			fx.torchFlame(footX, footY-10, game.getAutoSwitchRatio());

		if( isOutOfTheGame() && !cd.hasSetS("fx",0.1) )
			fx.torchFlame(footX, footY-10, 0);
	}

	override function update() {
		super.update();
	}
}