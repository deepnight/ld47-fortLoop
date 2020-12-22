class Const {
	public static var FPS = 60;
	public static var FIXED_FPS = 30;
	public static var SCALE = 1; // ignored if auto-scaling
	public static var UI_SCALE = 1;
	public static var GRID = 16;
	public static var GRAVITY = 0.028;

	public static var DARK_COLOR = 0x1b131b;
	public static var DARK_LIGHT_COLOR = 0x493346;

	public static var DARKNESS_DURATION = 2.5;
	public static var LIGHT_DURATION = 12;

	static var _uniq = 0;
	public static var NEXT_UNIQ(get,never) : Int; static inline function get_NEXT_UNIQ() return _uniq++;
	public static var INFINITE = 999999;

	static var _inc = 0;
	public static var DP_BG = _inc++;
	public static var DP_VAULT_LOCK = _inc++;
	public static var DP_FX_BG = _inc++;
	public static var DP_MAIN = _inc++;
	public static var DP_FRONT = _inc++;
	public static var DP_FX_FRONT = _inc++;
	public static var DP_TOP = _inc++;
	public static var DP_UI = _inc++;
}
