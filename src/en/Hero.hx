package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;
	// var darkMask : h2d.Graphics;
	// var darkHalo : h2d.Graphics;

	public function new(e:Entity_Hero) {
		super(e.cx, e.cy);

		ca = Main.ME.controller.createAccess("hero");
		ca.setLeftDeadZone(0.2);
		stayInDark = true;


		// darkMask = new h2d.Graphics();
		// darkMask.filter = new h2d.filter.ColorMatrix();
		// game.root.add(darkMask, Const.DP_FX_FRONT);

		// darkHalo = new h2d.Graphics(darkMask);
		// darkHalo.blendMode = Erase;
		// darkHalo.beginFill(0xffffff, 1);
		// darkHalo.drawCircle(0,0,Const.GRID*4);
		// darkHalo.endFill();
		// darkHalo.filter = new h2d.filter.Blur(32);

		spr.anim.registerStateAnim("heroIdle",0);
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
		// darkHalo.remove();
		// darkHalo = null;
	}

	override function onDark() {
		super.onDark();
	}

	override function onLight() {
		super.onLight();
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

	override function postUpdate() {
		super.postUpdate();

		// darkMask.visible = game.dark;
		// if( game.dark ) {
		// 	darkMask.clear();
		// 	darkMask.beginFill(Const.DARK_COLOR);
		// 	darkMask.drawRect(0,0,game.w(), game.h());

		// 	darkHalo.setScale( Const.SCALE * camera.zoom );
		// 	darkHalo.x = centerX*Const.SCALE*camera.zoom + game.scroller.x;
		// 	darkHalo.y = centerY*Const.SCALE*camera.zoom + game.scroller.y;
		// }
	}

	override function update() {
		super.update();

		if( onGround ) {
			cd.setS("onGroundRecently",0.1);
			cd.setS("airControl",0.7);
		}

		// Walk
		if( !controlsLocked() && ca.leftDist() > 0 ) {
			var spd = 0.015;
			dx += Math.cos( ca.leftAngle() ) * ca.leftDist() * spd * ( 0.2+0.8*cd.getRatio("airControl") ) * tmod;
			dir = dx>0 ? 1 : -1;
		}

		// Jump
		if( !controlsLocked() && ca.aPressed() && cd.has("onGroundRecently") ) {
			setSquashX(0.7);
			dy = -0.12;
			cd.setS("jumpForce",0.1);
			cd.setS("jumpExtra",0.1);
		}
		else if( cd.has("jumpExtra") && ca.aDown() )
			dy-=0.04*tmod;

		if( cd.has("jumpForce") && ca.aDown() )
			dy -= 0.1 * cd.getRatio("jumpForce") * tmod;

		// HACK
		if( !controlsLocked() && ca.xPressed() ) {
			game.dark = !game.dark;
		}

		// Hop
		if( !controlsLocked() && yr<0.5 && dy>0 && ca.leftDist()>0 ) {
			if( xr>=0.5 && level.hasMark(GrabRight,cx,cy) && M.radDistance(ca.leftAngle(),0)<=M.PIHALF*0.7 ) {
				yr = M.fmin(0.3,yr);
				dy = -0.3;
				dx+=0.2;
			}
			if( xr<=0.5 && level.hasMark(GrabLeft,cx,cy) && M.radDistance(ca.leftAngle(),M.PI)<=M.PIHALF*0.7 ) {
				yr = M.fmin(0.3,yr);
				dy = -0.3;
				dx-=0.2;
			}
		}
	}
}