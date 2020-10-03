class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var cWid(get,never) : Int; inline function get_cWid() return level.l_Collisions.cWid;
	public var cHei(get,never) : Int; inline function get_cHei() return level.l_Collisions.cHei;

	public var level : World.World_Level;
	var tilesetSource : h2d.Tile;

	var marks : Map< LevelMark, Map<Int,Bool> > = new Map();
	var invalidated = true;

	var walls : h2d.TileGroup;
	var bg : h2d.TileGroup;
	var dark : h2d.TileGroup;
	public var burn : h2d.TileGroup;

	public function new(l:World.World_Level) {
		super(Game.ME);
		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		level = l;

		tilesetSource = hxd.Res.world.tileset.toTile();
		bg = new h2d.TileGroup(tilesetSource, root);
		walls = new h2d.TileGroup(tilesetSource, root);
		dark = new h2d.TileGroup(tilesetSource, root);
		burn = new h2d.TileGroup(tilesetSource, root);
		burn.blendMode = Add;
		burn.filter = new h2d.filter.Group([
			new h2d.filter.Bloom(4, 1, 8),
			new h2d.filter.Blur(8),
		]);


		// Entities
		var e = level.l_Entities.all_Hero[0];
		game.hero = new en.Hero(e);

		for(cy in 0...cHei)
		for(cx in 0...cWid) {
			if( !hasCollision(cx,cy) && !hasCollision(cx,cy-1) ) {
				if( hasCollision(cx+1,cy) && !hasCollision(cx+1,cy-1) )
					setMark(cx,cy, GrabRight);

				if( hasCollision(cx-1,cy) && !hasCollision(cx-1,cy-1) )
					setMark(cx,cy, GrabLeft);
			}

			if( !hasCollision(cx,cy) && hasCollision(cx,cy+1) ) {
				if( hasCollision(cx+1,cy) || !hasCollision(cx+1,cy+1) )
					setMark(cx,cy, PlatformEnd);
				if( hasCollision(cx-1,cy) || !hasCollision(cx-1,cy+1) )
					setMark(cx,cy, PlatformEnd);
			}
		}
	}

	override function onDispose() {
		super.onDispose();
		level = null;
		marks = null;
		tilesetSource.dispose();
		tilesetSource = null;
	}

	/**
		Mark the level for re-render at the end of current frame (before display)
	**/
	public inline function invalidate() {
		invalidated = true;
	}

	/**
		Return TRUE if given coordinates are in level bounds
	**/
	public inline function isValid(cx,cy) return cx>=0 && cx<cWid && cy>=0 && cy<cHei;

	/**
		Transform coordinates into a coordId
	**/
	public inline function coordId(cx,cy) return cx + cy*cWid;


	/** Return TRUE if mark is present at coordinates **/
	public inline function hasMark(mark:LevelMark, cx:Int, cy:Int) {
		return !isValid(cx,cy) || !marks.exists(mark) ? false : marks.get(mark).exists( coordId(cx,cy) );
	}

	/** Enable mark at coordinates **/
	public function setMark(cx:Int, cy:Int, mark:LevelMark) {
		if( isValid(cx,cy) && !hasMark(mark,cx,cy) ) {
			if( !marks.exists(mark) )
				marks.set(mark, new Map());
			marks.get(mark).set( coordId(cx,cy), true );
		}
	}

	/** Remove mark at coordinates **/
	public function removeMark(mark:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && hasMark(mark,cx,cy) )
			marks.get(mark).remove( coordId(cx,cy) );
	}

	/** Return TRUE if "Collisions" layer contains a collision value **/
	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy) ? true : level.l_Collisions.getInt(cx,cy)==0;
	}

	public function setDark(v:Bool) {
		dark.visible = v;
		walls.visible = !v;
		bg.visible = !v;
		burn.visible = !v;
	}

	/** Render current level**/
	function render() {
		bg.clear();
		walls.clear();
		dark.clear();

		// Bg
		for( autoTile in level.l_Bg.autoTiles ) {
			var tile = level.l_Bg.tileset.getAutoLayerHeapsTile(tilesetSource, autoTile);
			bg.add(autoTile.renderX, autoTile.renderY, tile);
			// burn.add(autoTile.renderX, autoTile.renderY, tile);
		}

		// Walls
		for( autoTile in level.l_Collisions.autoTiles ) {
			var tile = level.l_Collisions.tileset.getAutoLayerHeapsTile(tilesetSource, autoTile);
			walls.add(autoTile.renderX, autoTile.renderY, tile);
			burn.add(autoTile.renderX, autoTile.renderY, tile);
		}

		// Dark
		for( autoTile in level.l_DarkRender.autoTiles ) {
			var tile = level.l_DarkRender.tileset.getAutoLayerHeapsTile(tilesetSource, autoTile);
			dark.add(autoTile.renderX, autoTile.renderY, tile);
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}