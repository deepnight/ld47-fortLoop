import dn.heaps.slib.*;

class Assets {
	public static var SLIB = dn.heaps.assets.SfxDirectory.load("sfx", true);

	public static var fontPixel : h2d.Font;
	public static var fontTiny : h2d.Font;
	public static var fontSmall : h2d.Font;
	public static var fontMedium : h2d.Font;
	public static var fontLarge : h2d.Font;
	public static var tiles : SpriteLib;

	static var initDone = false;
	public static function init() {
		if( initDone )
			return;
		initDone = true;

		fontPixel = hxd.Res.fonts.minecraftiaOutline.toFont();
		fontTiny = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont();
		fontSmall = hxd.Res.fonts.barlow_condensed_medium_regular_11.toFont();
		fontMedium = hxd.Res.fonts.barlow_condensed_medium_regular_17.toFont();
		fontLarge = hxd.Res.fonts.barlow_condensed_medium_regular_32.toFont();

		tiles = dn.heaps.assets.Atlas.load("atlas/tiles.atlas");
		tiles.defineAnim("heroIdle", "0(10), 1(15)");
		tiles.defineAnim("heroRun", "0(5), 1(3), 2(5), 3(3)");
		tiles.defineAnim("heroCrouchRun", "0(5), 1(3), 2(5), 1(3)");
		tiles.defineAnim("heroClimb", "1(5), 0(3), 2(5), 0(3)");
		tiles.defineAnim("heroThrow", "0(2), 1(3)");

		tiles.defineAnim("knightWalk", "0(5), 1(3), 2(5), 1(3)");
	}
}