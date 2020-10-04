package en;

class Trigger extends Entity {
	public static var ALL : Array<Trigger> = [];
	var data : Entity_Trigger;
	var triggered = false;

	public function new(e:Entity_Trigger) {
		super(e.cx, e.cy);
		gravityMul = 0;
		ALL.push(this);
		data = e;
		darkMode = GoOutOfGame;
		game.scroller.add(spr, Const.DP_BG);

		spr.set("triggerOff");
	}

	public function trigger() {
		if( triggered )
			return false;

		triggered = true;
		spr.set("triggerOn");
		var d = getTargetDoor();
		if( d!=null )
			d.setClosed(false);
		return true;
	}

	function getTargetDoor() : en.Door {
		if( data.f_target==null ) {
			var dh = new dn.DecisionHelper(en.Door.ALL);
			dh.keepOnly( (e)->e.needKey );
			dh.score( (e)->-distCase(e) );
			return dh.getBest();
		}
		else {
			var dh = new dn.DecisionHelper(en.Door.ALL);
			dh.score( (e)->-e.distCaseFree(data.f_target.cx, data.f_target.cy) );
			return dh.getBest();
		}
	}

	public function untrigger() {
		triggered = false;
		spr.set("triggerOff");
	}

	override function postUpdate() {
		super.postUpdate();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function update() {
		super.update();

		var e = getTargetDoor();
		if( e!=null ) {
			if( !triggered && !e.isClosed )
				trigger();

			if( triggered && e.isClosed )
				untrigger();
		}

		if( !isOutOfTheGame() && hero.onGround && hero.distCaseX(this)<=1 && hero.cy==cy )
			trigger();
	}
}