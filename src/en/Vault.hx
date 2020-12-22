package en;

class Vault extends Entity {
	public static var ALL : Array<Vault> = [];
	var data : Entity_Vault;
	var lock : HSprite;

	public function new(e:Entity_Vault) {
		super(e.cx, e.cy);
		gravityMul = 0;
		ALL.push(this);
		data = e;
		game.scroller.add(spr, Const.DP_BG);

		spr.set("vault");
		spr.setCenterRatio(0.5,0.5);

		lock = Assets.tiles.h_get("vaultLock",0, 0.5,0.5);
		game.scroller.add(lock, Const.DP_VAULT_LOCK);
	}

	override function postUpdate() {
		super.postUpdate();
		spr.alpha = isOutOfTheGame() ? 0.2 : 1;
		lock.setPosition(spr.x, spr.y);
		lock.visible = !game.dark && isGrabbingAnything();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		lock.remove();
	}

	override function update() {
		super.update();

		if( !isGrabbingAnything() ) {
			for(e in en.Item.ALL) {
				if( !e.isAlive() || e.type!=Diamond && e.type!=DiamondDup )
					continue;

				if( !e.isGrabbedByHero() && distCase(e)<=1.3 || e.isGrabbedByHero() && distCase(e)<=1.3 ) {
					if( e.isGrabbedByHero() )
						hero.dropItem();
					grabItem(e);
					e.cd.setS("pickLock",0.6);
					e.inVault = true;
					fx.vaultIn(centerX, centerY+5, 0x2ae9ff);
					Assets.SLIB.vault0(1);
					break;
				}
			}
		}

		darkMode = isGrabbingAnything() ? Stay : GoOutOfGame;

		if( isGrabbingAnything() )
			grabbedItem.setPosPixel(footX-1, footY+6);
	}
}