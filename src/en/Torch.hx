package en;

class Torch extends Entity {
	public static var ALL : Array<Torch> = [];

	var fake = false;
	public function new(e:World.Entity_Torch) {
		super(e.cx, e.cy);
		fake = e.f_fake;
		ALL.push(this);
		gravityMul = 0;
		// darkMode = DestroyAndHide;
		game.scroller.add(spr, Const.DP_BG);

		spr.set("torchOff");
	}

	public static function any() {
		for(e in ALL)
			if( e.isAlive() && !e.fake )
				return true;
		return false;
	}

	override function onLight() {
		super.onLight();
		fx.torchLightOn(footX, footY-10);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();

		spr.filter = null;
		spr.alpha = 0.3;

		if( !cd.hasSetS("fx",0.06) ) {
			if( !isOutOfTheGame() )
				fx.torchFlame(footX, footY-10, game.getAutoSwitchRatio());

			if( isOutOfTheGame() )
				fx.torchFlame(footX, footY-10, 0);
		}
		if( isOutOfTheGame() && game.getAutoSwitchS()<=1 && !cd.hasSetS("fxIgnite",0.03) )
			fx.torchIgnition(uid, footX, footY-10, 1 - game.getAutoSwitchS()/1 );
	}

	override function update() {
		super.update();
	}
}