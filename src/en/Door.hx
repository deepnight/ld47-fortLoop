package en;

class Door extends Entity {
	public static var ALL : Array<Door> = [];
	var data : Entity_Door;
	var cHei = 2;
	var isClosed : Bool;

	public function new(e:Entity_Door) {
		super(e.cx, e.cy);
		ALL.push(this);
		data = e;
		darkMode = Hide;
		setClosed(true);
		Game.ME.scroller.add(spr, Const.DP_BG);
	}

	function setClosed(closed:Bool) {
		if( level==null || level.destroyed )
			return;

		isClosed = closed;

		if( spr!=null && !spr.destroyed )
			spr.set(closed ? "doorClosed" : "doorOpen");

		for(i in 0...cHei)
			level.setExtraCollision(cx,cy-i, closed);
	}

	override function postUpdate() {
		super.postUpdate();
		if( !isClosed && hasAffect(Hidden) )
			spr.visible = false;
	}

	override function dispose() {
		super.dispose();

		if( isClosed )
			setClosed(false);

		ALL.remove(this);
	}

	override function update() {
		super.update();

		// if( distCase(hero)<=1 && isClosed )
		// 	setClosed(false);
	}
}