package en;

class Vortex extends Entity {
	public static var ALL : Array<Vortex> = [];
	var data : Entity_Vortex;
	var content : Null<Enum_ItemType>;

	public function new(e:Entity_Vortex) {
		super(e.cx, e.cy);
		gravityMul = 0;
		ALL.push(this);
		darkMode = Stay;
		data = e;
		game.scroller.add(spr, Const.DP_BG);
	}

	override function postUpdate() {
		super.postUpdate();
		if( !cd.hasSetS("fx",0.06) )
			fx.vortex(footX, footY, content==null ? 12 : 5, content==null ? 0x00ff00 : 0x8b95cf);
		spr.visible = false;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onLight() {
		super.onLight();

		if( content!=null ) {
			var e = new en.Item(cx,cy, content);
			e.dx = rnd(0.01,0.02,true);
			e.dy = -0.1;
			e.cd.setS("vortexLock",Const.INFINITE);
			content = null;
		}
	}

	override function update() {
		super.update();

		if( content==null )
			for(e in en.Item.ALL)
				if( e.isAlive() && distCase(e)<=2 && !e.cd.has("vortexLock") && !e.isGrabbedByHero() ) {
					content = e.type;
					e.destroy();
				}
	}
}