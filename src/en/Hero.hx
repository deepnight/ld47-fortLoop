package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;
	public var ammo : Int;
	public var maxAmmo : Int;

	public function new(e:Entity_Hero) {
		super(e.cx, e.cy);

		ammo = maxAmmo = 15;
		ca = Main.ME.controller.createAccess("hero");
		ca.setLeftDeadZone(0.2);
		darkMode = Stay;
		circularCollisions = true;
		initLife(3);


		spr.filter = new dn.heaps.filter.PixelOutline();
		spr.anim.setGlobalSpeed(0.2);
		spr.anim.registerStateAnim("heroRun",1, 2, ()->M.fabs(dx)>=0.05 );
		spr.anim.registerStateAnim("heroIdle",0);
		spr.anim.registerTransition("heroIdle","heroRun","heroIdleRun",0.4);
	}

	override function onDamage(dmg:Int, from:Entity) {
		super.onDamage(dmg, from);
		cancelVelocities();
		if( from!=null )
			bump(from.dirTo(this)*0.2, -0.2);
		setSquashX(0.5);
		lockControlS(0.3);
		fx.flashBangS(0xff0000,0.2, 1);
		camera.shakeS(0.5,0.5);
		hud.invalidate();
	}

	public function refillAmmo() {
		ammo = maxAmmo;
		hud.invalidate();
	}

	public function addAmmo(n:Int) {
		ammo = M.imin(maxAmmo, ammo+n);
		hud.invalidate();
	}

	public function useAmmo() {
		if( ammo<=0 )
			return false;

		ammo--;
		hud.invalidate();
		return true;
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	override function onDark() {
		super.onDark();
		lockControlS(0.25);
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

	public inline function isCrouching() {
		return isAlive() && onGround && level.hasCollision(cx,cy-1);
	}

	override function update() {
		super.update();
		var spd = 0.015 * (game.dark?2:1);

		if( onGround ) {
			cd.setS("onGroundRecently",0.1);
			cd.setS("airControl",0.7);
		}

		// Walk
		if( !controlsLocked() && ca.leftDist() > 0 ) {
			if( !climbing )
				dx += Math.cos( ca.leftAngle() ) * ca.leftDist() * spd * ( 0.2+0.8*cd.getRatio("airControl") ) * tmod;
			var old = dir;
			dir = M.sign( Math.cos(ca.leftAngle()) );
			if( old!=dir )
				spr.anim.playOverlap("heroTurn", 0.66);
		}

		// Jump
		if( !controlsLocked() && ca.aPressed() && ( cd.has("onGroundRecently") || climbing ) && !isCrouching() ) {
			if( climbing ) {
				stopClimbing();
				cd.setS("climbLock",0.2);
				dx = dir*0.1;
				dy = 0;
			}
			else {
				setSquashX(0.7);
				dy = -0.07;
			}
			cd.setS("jumpForce",0.1);
			cd.setS("jumpExtra",0.1);
		}
		else if( cd.has("jumpExtra") && ca.aDown() )
			dy-=0.04*tmod;

		if( cd.has("jumpForce") && ca.aDown() )
			dy -= 0.05 * cd.getRatio("jumpForce") * tmod;

		// Throw item
		if( ca.xPressed() ) {
			var e = dropItem();
			if( e!=null ) {
				e.cd.setS("pickLock",0.1);
				e.dx = dir*0.45;
				e.dy = -0.15;
			}
			// else {
			// 	for(e in en.Vault.ALL)
			// 		if( e.isGrabbingAnything() && distCase(e)<=1.5 ) {
			// 			grabItem( e.dropItem() );
			// 			break;
			// 		}
			// }
			// if( !useAmmo() )
			// 	fx.flashBangS(0x9182d3, 0.1, 0.1);
			// else {
			// 	var dh = new dn.DecisionHelper(en.Mob.ALL);
			// 	dh.keepOnly( (e)->e.isAlive() && M.fabs(cx-e.cx)<=10 && !e.isOutOfTheGame() );
			// 	dh.keepOnly( (e)->M.fabs(e.centerY-centerY)<=Const.GRID && dirTo(e)==dir && sightCheck(e) );
			// 	dh.score( (e)->-M.fabs(centerX-e.centerX) );
			// 	dh.useBest( (e)->{
			// 		e.hit(1, this);
			// 	});
			// }
		}

		// HACK
		#if debug
		if( !controlsLocked() && ca.rbPressed() ) {
			game.setDarkness(!game.dark);
		}
		#end

		if( !climbing && !cd.has("climbLock") && !controlsLocked() && ca.leftDist()>0 ) {
			// Grab ladder up
			if( M.radDistance(ca.leftAngle(),-M.PIHALF)<=M.PIHALF*0.5 && level.hasLadder(cx,cy) ) {
				startClimbing();
				setSquashX(0.6);
				dy-=0.2;
			}
			// Grab ladder down
			if( M.radDistance(ca.leftAngle(),M.PIHALF)<=M.PIHALF*0.5 && level.hasLadder(cx,cy+1) ) {
				startClimbing();
				cy++;
				yr = 0.1;
				setSquashY(0.6);
				dy=0.2;
			}
		}

		// Lost ladder
		if( climbing && !level.hasLadder(cx,cy) )
			stopClimbing();

		// Reach ladder top
		if( climbing && dy<0 && !level.hasLadder(cx,cy-1) && yr<=0.7 ) {
			stopClimbing();
			dy = -0.2;
			yr = 0.2;
			cd.setS("climbLock",0.2);
		}

		if( climbing )
			xr += (0.5-xr)*0.1;

		// Reach ladder bottom
		if( climbing && dy>0 && !level.hasLadder(cx,cy+1) ) {
			stopClimbing();
			dy = 0.1;
			cd.setS("climbLock",0.2);
		}

		// Climb ladder
		if( climbing && ca.leftDist()>0 ) {
			dy+=Math.sin(ca.leftAngle()) * spd * 0.75 * tmod;
		}

		// Hop
		if( !controlsLocked() && yr<0.5 && dy>0 && ca.leftDist()>0 ) {
			if( xr>=0.5 && level.hasMark(GrabRight,cx,cy) && M.radDistance(ca.leftAngle(),0)<=M.PIHALF*0.7 && !level.hasCollision(cx+1,cy-1) ) {
				yr = M.fmin(0.4,yr);
				dy = -0.2;
				dx+=0.2;
			}
			if( xr<=0.5 && level.hasMark(GrabLeft,cx,cy) && M.radDistance(ca.leftAngle(),M.PI)<=M.PIHALF*0.7 && !level.hasCollision(cx-1,cy-1) ) {
				yr = M.fmin(0.4,yr);
				dy = -0.2;
				dx-=0.2;
			}
		}

		// Auto attack
		for(e in en.Mob.ALL) {
			if( e.isAlive() && !e.isOutOfTheGame() && distCaseX(e)<=1 && footY>=e.footY-Const.GRID*1 && footY<=e.footY+Const.GRID*0.5 && !cd.hasSetS("autoAtk",0.1) ) {
				e.hit(1,hero);
				bump(-dirTo(e)*rnd(0.03,0.06), 0);
				e.bump(dirTo(e)*rnd(0.06,0.12), -rnd(0.04,0.08));
				// var i = dropItem();
				// if( i!=null )
				// 	i.bump(-dirTo(e)*rnd(0.1,0.2), -0.3);
			}
		}

		// Drop item while crouching
		if( isGrabbingAnything() && isCrouching() ) {
			var e = dropItem();
			var dh = new dn.DecisionHelper( dn.Bresenham.getDisc(cx,cy, 3) );
			dh.keepOnly( (pt)->!level.hasCollision(pt.x,pt.y) && !level.hasCollision(pt.x,pt.y-1) );
			dh.score( (pt)->-e.distCaseFree(pt.x,pt.y) );
			dh.useBest( (pt)->e.setPosCase(pt.x, pt.y) );
			e.dy = -0.2;
			e.dx = dirTo(e)*0.1;
			e.xr = dirTo(e)==1 ? 0.1 : 0.9;
		}

		// #if debug
		debug( M.pretty(hxd.Timer.fps(),1) );
		// #end
	}
}