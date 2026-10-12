## Level dictionary (parsed JSON) -> validated GameState. See docs/LEVEL_FORMAT.md.
class_name LevelData
extends RefCounted

const GATES := ["bottom", "top", "left", "right"]
const DEFAULTS := {"bays": 5, "gate": "bottom", "cars_per_tick": 3,
	"travel_base_ticks": 4, "travel_cells_per_tick": 2}
const ROW_CHARS := "0123456789abcdefghijklmnopqrstuvwxyz"


static func get_opt(level: Dictionary, key: String):
	return level.get(key, DEFAULTS[key])


static func gates(level: Dictionary) -> Array:
	var g = get_opt(level, "gate")
	if g is String:
		return GATES.duplicate() if g == "all" else [g]
	return Array(g)


## Decodes "cells" (base64 bytes) or "rows" (one char per cell: 0-9a-z car color,
## "." = asphalt).
static func cells(level: Dictionary) -> PackedByteArray:
	if level.has("cells"):
		return Marshalls.base64_to_raw(level["cells"])
	var out := PackedByteArray()
	for row in level.get("rows", []):
		for ch in row:
			out.append(GarageGrid.ASPHALT if ch == "." else ROW_CHARS.find(ch.to_lower()))
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
		errs.append("cell count %d != w*h %d" % [px.size(), w * h])
		return errs
	var ncolors := 256
	if level.has("palette"):
		ncolors = level["palette"].size()
		if ncolors < 1 or ncolors > 9:
			errs.append("palette must have 1-9 colors, has %d" % ncolors)
	var cars_by_color := {}
	for c in px:
		if c == GarageGrid.ASPHALT:
			continue
		if c >= ncolors:
			errs.append("car color %d outside palette" % c)
			return errs
		cars_by_color[c] = int(cars_by_color.get(c, 0)) + 1
	for g in gates(level):
		if not g in GATES:
			errs.append("unknown gate '%s'" % g)
	if int(get_opt(level, "bays")) < 1:
		errs.append("bays must be >= 1")
	if int(get_opt(level, "cars_per_tick")) < 1:
		errs.append("cars_per_tick must be >= 1")
	var trailers_by_color := {}
	var queues = level.get("queues", [])
	if not queues is Array or queues.is_empty():
		errs.append("queues must be a non-empty array")
		return errs
	for qi in queues.size():
		for ti in queues[qi].size():
			var t: Dictionary = queues[qi][ti]
			var n := int(t.get("n", 0))
			if n <= 0:
				errs.append("queues[%d][%d]: number must be positive" % [qi, ti])
			if t.get("tow", false):
				continue
			var c := int(t.get("c", -1))
			if c < 0 or c >= ncolors:
				errs.append("queues[%d][%d]: bad color %d" % [qi, ti, c])
			trailers_by_color[c] = int(trailers_by_color.get(c, 0)) + n
	# Balance invariant: per color, sum of trailer numbers == cars of that color.
	var seen := {}
	for c in cars_by_color.keys() + trailers_by_color.keys():
		if seen.has(c):
			continue
		seen[c] = true
		var cars := int(cars_by_color.get(c, 0))
		var nums := int(trailers_by_color.get(c, 0))
		if cars != nums:
			errs.append("balance: color %d has %d cars but trailers sum to %d" % [c, cars, nums])
	return errs


## Builds a fresh attempt. Assumes validate(level) returned no errors.
static func build_state(level: Dictionary, rev: int) -> GameState:
	var s := GameState.new()
	s.level_rev = rev
	s.cars_per_tick = int(get_opt(level, "cars_per_tick"))
	s.travel_base_ticks = int(get_opt(level, "travel_base_ticks"))
	s.travel_cells_per_tick = int(get_opt(level, "travel_cells_per_tick"))
	s.grid = GarageGrid.new()
	s.grid.setup(int(level["w"]), int(level["h"]), cells(level), gates(level))
	Freedom.build(s.grid)
	for q_data in level["queues"]:
		var q := []
		for d in q_data:
			var id := s.trailers.size()
			var hidden := bool(d.get("hidden", false))
			var t := Trailer.make_tow(id, int(d["n"]), hidden) if d.get("tow", false) \
				else Trailer.make(id, int(d["c"]), int(d["n"]), hidden)
			s.trailers.append(t)
			q.append(t)
		if not q.is_empty():
			q[0].hidden = false
		s.queues.append(q)
	s.bays.resize(int(get_opt(level, "bays")))
	s.bays.fill(null)
	s.phase = GameState.Phase.RUNNING
	return s
