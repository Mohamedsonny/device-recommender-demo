## Level dictionary (parsed JSON) -> validated GameState. See docs/LEVEL_FORMAT.md.
class_name LevelData
extends RefCounted

const ENTRIES := ["bottom", "top", "left", "right"]
const DEFAULTS := {"slots": 5, "entry": "bottom", "ants_per_tick": 3,
	"travel_base_ticks": 4, "travel_rows_per_tick": 2}
const ROW_CHARS := "0123456789abcdefghijklmnopqrstuvwxyz"


static func get_opt(level: Dictionary, key: String):
	return level.get(key, DEFAULTS[key])


static func entries(level: Dictionary) -> Array:
	var e = get_opt(level, "entry")
	if e is String:
		return ENTRIES.duplicate() if e == "all" else [e]
	return Array(e)


## Decodes "pixels" (base64 bytes) or "rows" (one char per cell: 0-9a-z, "." = empty).
static func cells(level: Dictionary) -> PackedByteArray:
	if level.has("pixels"):
		return Marshalls.base64_to_raw(level["pixels"])
	var out := PackedByteArray()
	for row in level.get("rows", []):
		for ch in row:
			out.append(BoardState.EMPTY if ch == "." else ROW_CHARS.find(ch.to_lower()))
	return out


## Returns every problem found; an empty array means the level is loadable.
static func validate(level: Dictionary) -> PackedStringArray:
	var errs := PackedStringArray()
	var w := int(level.get("w", 0))
	var h := int(level.get("h", 0))
	if w <= 0 or h <= 0:
		errs.append("w and h must be positive")
		return errs
	var px := cells(level)
	if px.size() != w * h:
		errs.append("pixel count %d != w*h %d" % [px.size(), w * h])
		return errs
	var ncolors := 256
	if level.has("palette"):
		ncolors = level["palette"].size()
		if ncolors < 1 or ncolors > 9:
			errs.append("palette must have 1-9 colors, has %d" % ncolors)
	var pixels_by_color := {}
	for c in px:
		if c == BoardState.EMPTY:
			continue
		if c >= ncolors:
			errs.append("pixel color %d outside palette" % c)
			return errs
		pixels_by_color[c] = int(pixels_by_color.get(c, 0)) + 1
	for e in entries(level):
		if not e in ENTRIES:
			errs.append("unknown entry '%s'" % e)
	if int(get_opt(level, "slots")) < 1:
		errs.append("slots must be >= 1")
	if int(get_opt(level, "ants_per_tick")) < 1:
		errs.append("ants_per_tick must be >= 1")
	var boxes_by_color := {}
	var tray = level.get("tray", [])
	if not tray is Array or tray.is_empty():
		errs.append("tray must be a non-empty array of columns")
		return errs
	for ci in tray.size():
		for bi in tray[ci].size():
			var b: Dictionary = tray[ci][bi]
			var c := int(b.get("c", -1))
			var n := int(b.get("n", 0))
			if c < 0 or c >= ncolors:
				errs.append("tray[%d][%d]: bad color %d" % [ci, bi, c])
			if n <= 0:
				errs.append("tray[%d][%d]: count must be positive" % [ci, bi])
			boxes_by_color[c] = int(boxes_by_color.get(c, 0)) + n
	# Balance invariant: per color, sum of box counts == pixels of that color.
	var all_colors := pixels_by_color.keys() + boxes_by_color.keys()
	for c in all_colors:
		var p := int(pixels_by_color.get(c, 0))
		var b := int(boxes_by_color.get(c, 0))
		if p != b:
			var msg := "balance: color %d has %d pixels but boxes sum to %d" % [c, p, b]
			if not msg in errs:
				errs.append(msg)
	return errs


## Builds a fresh attempt. Assumes validate(level) returned no errors.
static func build_state(level: Dictionary, rev: int) -> GameState:
	var s := GameState.new()
	s.level_rev = rev
	s.ants_per_tick = int(get_opt(level, "ants_per_tick"))
	s.travel_base_ticks = int(get_opt(level, "travel_base_ticks"))
	s.travel_rows_per_tick = int(get_opt(level, "travel_rows_per_tick"))
	s.board = BoardState.new()
	s.board.setup(int(level["w"]), int(level["h"]), cells(level), entries(level))
	Exposure.build(s.board)
	for col_data in level["tray"]:
		var col := []
		for b in col_data:
			var box := Box.make(s.boxes.size(), int(b["c"]), int(b["n"]), bool(b.get("hidden", false)))
			s.boxes.append(box)
			col.append(box)
		if not col.is_empty():
			col[0].hidden = false
		s.tray.append(col)
	s.slots.resize(int(get_opt(level, "slots")))
	s.slots.fill(null)
	s.phase = GameState.Phase.RUNNING
	return s
