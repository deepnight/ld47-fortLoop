package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];
	public var type : Enum_ItemType;
	public var origin : CPoint;
	public var inVault = false;

	public function new(x,y, t:Enum_ItemType) {
		super(x, y);
		ALL.push(this);
		gravityMul*=0.5;
		frictX = frictY = 0.96;

		type = t;
		origin = makePoint();
		cd.setS("pickLock",0.25);

		game.scroller.add(spr, Const.DP_BG);
		spr.set(switch type {
			case Ammo: "itemAmmo";
			case DoorKey: "itemKey";
			case Diamond: "itemDiamond";
		});

		switch type {
			case Diamond: darkMode = GoOutOfGame;
			case _:
		}
	}

	override function onDark() {
		super.onDark();

		if( isGrabbedByHero() )
			hero.dropItem();

		if( darkMode==GoOutOfGame )
			setPosCase(origin.cx, origin.cy);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onLand(fallCHei:Float) {
		super.onLand(fallCHei);

		if( fallCHei>=0.5 ) {
			dx*=0.5;
			dy = -0.1;
		}
	}

	public inline function isGrabbedByHero() return hero!=null && hero.isGrabbing(this);

	override function update() {
		super.update();

		if( distCase(hero)<=0.9 && !isOutOfTheGame() && !hero.isGrabbingAnything() && !cd.has("pickLock") ) {
			switch type {
			case Ammo:
				hero.addAmmo(6);
				fx.flashBangS(0xffcc00,0.1);
				destroy();

			case Diamond:
				fx.flashBangS(0x04b6ff, 0.3, 1);
				hero.grabItem(this);

			case DoorKey:
				fx.flashBangS(0xffcc00, 0.3, 0.2);
				hero.grabItem(this);
			}
		}
	}
}