package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;

	public function new(e:Entity_Hero) {
		super(e.cx, e.cy);

		ca = Main.ME.controller.createAccess("hero");
		ca.setLeftDeadZone(0.2);

		var g = new h2d.Graphics(spr);
		g.beginFill(e.color);
		g.drawRect(-8, -16, 16,16);
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	override function onLand(fallCHei:Float) {
		super.onLand(fallCHei);
		var impact = M.fmin(1, fallCHei/6);
		dx *= (1-impact)*0.5;
		game.camera.bump(0, 2*impact);
		setSquashY(1-impact*0.7);

		if( fallCHei>=3 )
			lockControlS(0.03*impact);
	}

	override function update() {
		super.update();

		if( onGround )
			cd.setS("airControl",0.7);

		// Walk
		if( !controlsLocked() && ca.leftDist() > 0 ) {
			dx += Math.cos( ca.leftAngle() ) * ca.leftDist() * 0.04 * ( 0.2+0.8*cd.getRatio("airControl") ) * tmod;
		}

		// Jump
		if( !controlsLocked() && ca.aPressed() && onGround ) {
			setSquashX(0.7);
			dy = -0.22;
			cd.setS("jumpForce",0.1);
			cd.setS("jumpExtra",0.1);
		}
		else if( cd.has("jumpExtra") && ca.aDown() )
			dy-=0.04*tmod;

		if( cd.has("jumpForce") && ca.aDown() )
			dy -= 0.15 * cd.getRatio("jumpForce") * tmod;
	}
}