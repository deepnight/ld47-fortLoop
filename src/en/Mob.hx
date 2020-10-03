package en;

class Mob extends Entity {
	public static var ALL : Array<Mob> = [];
	var data : Entity_Mob;

	var origin : CPoint;
	var patrolTarget : Null<CPoint>;

	public function new(e:Entity_Mob) {
		super(e.cx, e.cy);
		ALL.push(this);
		data = e;

		dir = data.f_initialDir;
		lockControlS(1);

		origin = makePoint();
		patrolTarget = data.f_patrol==null ? null : new CPoint(data.f_patrol.cx, data.f_patrol.cy);

		var g = new h2d.Graphics(spr);
		g.beginFill(0xff0000);
		g.drawRect(-8, -16, 16,16);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function update() {
		super.update();

		if( !controlsLocked() ) {
			// AI
			var spd = 0.01;
			if( data.f_patrol==null ) {
				// Auto patrol
				dx += spd * dir * tmod;
				if( level.hasMark(PlatformEndLeft,cx,cy) && dir==-1 && xr<0.5
					|| level.hasMark(PlatformEndRight,cx,cy) && dir==1 && xr>0.5 ) {
					lockControlS(0.5);
					setSquashX(0.85);
					dir*=-1;
				}
			}
			else {
				// Fixed patrol
				dir = patrolTarget.centerX>centerX ? 1 : -1;
				dx += spd * dir * tmod;
				if( cx==patrolTarget.cx && cy==patrolTarget.cy && onGround && M.fabs(xr-0.5)<=0.3 ) {
					patrolTarget.cx = patrolTarget.cx==origin.cx ? data.f_patrol.cx : origin.cx;
					patrolTarget.cy = patrolTarget.cy==origin.cy ? data.f_patrol.cy : origin.cy;
					setSquashX(0.85);
					lockControlS(0.5);
				}
			}
		}

		if( distCase(hero)<=0.7 && !cd.hasSetS("heroHitLock",0.3) ) {
			hero.cancelVelocities();
			hero.bump(dirTo(hero)*0.2, -0.2);
			hero.setSquashX(0.5);
			hero.lockControlS(0.3);
			camera.shakeS(0.5,0.5);
			lockControlS(0.5);
			setSquashX(0.5);
			if( !level.hasMark(PlatformEnd,cx,cy) ) {
				bump(-dirTo(hero)*0.05, -0.1);
			}
		}
	}
}