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

		if( data.f_exitLevel ) {
			game.nextLevel();
			return true;
		}

		var d = getTargetDoor();
		if( d!=null )
			d.setClosed(false);

		if( data.f_target!=null ) {
			for(e in en.Text.ALL)
				if( !e.textVisible && e.distCaseFree(data.f_target.cx, data.f_target.cy)<=2 )
					e.reveal();
		}

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
			dh.keepOnly( (e)->e.distCaseFree(data.f_target.cx, data.f_target.cy)<=2 );
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
		if( data.f_hidden )
			spr.visible = false;
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

		if( !isOutOfTheGame() ) {
			if( data.f_radius==0 && hero.onGround && hero.distCaseX(this)<=1 && hero.cy==cy )
				trigger();
			else if( data.f_radius>0 && hero.distCase(this)<=data.f_radius+0.5 )
				trigger();
		}
	}
}