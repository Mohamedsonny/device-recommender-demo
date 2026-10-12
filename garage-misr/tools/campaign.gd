## The launch campaign: garages, the art each level forms, difficulty bands and which
## mechanics are on. Pure data + lookups; the generator reads it.
class_name Campaign
extends RefCounted

const LEVELS_PER_GARAGE := 20

# Number ranges grow with the grid: a 28x36 garage holds ~1000 cars, which 6-25 trailers
# cannot cover in 3-5 trailers per color. See docs/LEVEL_GENERATION.md.
const GARAGES := [
	{"name": "جراج الحارة", "key": "hara", "w": 16, "h": 20, "colors": [3, 4], "queues": [3, 3],
		"numbers": [8, 25], "items": ["ful", "taameya", "eish", "shay", "beid"]},
	{"name": "جراج وسط البلد", "key": "wust_el_balad", "w": 20, "h": 26, "colors": [4, 5],
		"queues": [4, 4], "numbers": [10, 30],
		"items": ["koshari", "hawawshi", "dora", "arabeyet_ful", "kebda"]},
	{"name": "جراج المول", "key": "mall", "w": 24, "h": 30, "colors": [5, 6], "queues": [4, 5],
		"numbers": [12, 35], "items": ["konafa", "basbousa", "qatayef", "om_ali", "ice_cream"]},
	{"name": "جراج ليالي رمضان", "key": "ramadan", "w": 26, "h": 32, "colors": [6, 7],
		"queues": [5, 5], "numbers": [14, 40], "items": ["fanous", "kahk", "yamish", "helal", "madfaa"]},
	{"name": "جراج الساحل", "key": "sahel", "w": 28, "h": 36, "colors": [6, 8], "queues": [5, 5],
		"numbers": [15, 45], "items": ["batikh", "manga", "shamsiya", "asab", "samaka"]},
	{"name": "جراج الجيزة", "key": "giza", "w": 32, "h": 40, "colors": [7, 9], "queues": [5, 6],
		"numbers": [16, 50], "items": []},
]

const BANDS := [  # [first level, last level, min RandomBot loss %, max]
	[1, 5, 0.0, 0.0], [6, 20, 5.0, 15.0], [21, 40, 20.0, 35.0], [41, 60, 30.0, 45.0],
	[61, 80, 40.0, 55.0], [81, 100, 50.0, 65.0], [101, 120, 55.0, 70.0],
]
const EXTREME_BAND := [75.0, 85.0]
const SMART_MIN_WIN := 90.0


static func garage_of(level: int) -> Dictionary:
	@warning_ignore("integer_division")
	return GARAGES[(level - 1) / LEVELS_PER_GARAGE]


static func is_extreme(level: int) -> bool:
	return level % 10 == 0


## Full RandomBot loss band [min, max] for a level.
static func band(level: int) -> Array:
	if is_extreme(level):
		return EXTREME_BAND.duplicate()
	for b in BANDS:
		if level >= b[0] and level <= b[1]:
			return [b[2], b[3]]
	return [0.0, 100.0]


## Sawtooth target inside the band: easy, easy, harder (by position among non-Extreme levels).
static func target(level: int) -> Array:
	var b := band(level)
	if is_extreme(level) or b[0] == b[1]:
		return b
	var mid: float = (b[0] + b[1]) / 2.0
	return [mid, b[1]] if level % 3 == 0 else [b[0], mid]


## Everything the generator needs for one level.
static func config(level: int) -> Dictionary:
	var g := garage_of(level)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("garage-misr-%d" % level)
	var items: Array = g["items"]
	@warning_ignore("integer_division")
	var gi := (level - 1) / LEVELS_PER_GARAGE
	var tutorial := level <= 5
	var queues := rng.randi_range(g["queues"][0], g["queues"][1])
	var gate: Variant = "bottom"
	if g["key"] == "sahel" and level % 4 == 3 and not is_extreme(level):
		gate = ["bottom", "top"]
	return {
		"id": level, "garage": gi + 1, "garage_name": g["name"], "garage_key": g["key"],
		"item": items[(level - 1) % items.size()],
		"w": g["w"], "h": g["h"],
		"colors": 3 if tutorial else rng.randi_range(g["colors"][0], g["colors"][1]),
		"queues": queues, "bays": 5, "gate": gate,
		# Extreme: smaller trailers, so more of them crowd the bays.
		"numbers": [int(g["numbers"][0] * 0.6), int(g["numbers"][1] * 0.6)] if is_extreme(level)
			else g["numbers"],
		"extreme": is_extreme(level), "band": band(level), "target": target(level),
		"tarps": level >= 41, "tow": level >= 41, "tutorial": tutorial,
	}
