package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];
	var data : Entity_Item;

	public function new(e:Entity_Item) {
		super(e.cx, e.cy);
		ALL.push(this);
		data = e;

		spr.set(switch data.f_type {
			case Ammo: "itemAmmo";
			case Diamond: "itemDiamond";
		});

		switch data.f_type {
			case Ammo:
			case Diamond: darkMode = Hide;
		}
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function update() {
		super.update();

		if( distCase(hero)<=0.9 && !hasAffect(Hidden) ) {
			switch data.f_type {
			case Ammo: hero.addAmmo(6); fx.flashBangS(0xffcc00,0.1);
			case Diamond: fx.flashBangS(0x04b6ff, 0.3, 1);
			}
			destroy();
		}

		if( data.f_type==Diamond && !hasAffect(Hidden) && !cd.hasSetS("jump",1) && onGround )
			dy = -0.2;
	}
}