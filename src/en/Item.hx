package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];
	var data : Entity_Item;

	public function new(e:Entity_Item) {
		super(e.cx, e.cy);
		ALL.push(this);
		data = e;

		var g = new h2d.Graphics(spr);
		g.beginFill(0xffcc00);
		g.drawRect(-8, -16, 16,16);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function update() {
		super.update();

		if( distCase(hero)<=0.9 ) {
			switch data.f_type {
			case Ammo: hero.addAmmo(6);
			}
			destroy();
		}
	}
}