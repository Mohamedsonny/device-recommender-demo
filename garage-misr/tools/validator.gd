## Checks a level file: everything LevelData.validate checks, plus palette, garage size and
## colors, tow numbers, and that the stored solution replays to a WIN on the real engine.
class_name LevelValidator
extends RefCounted


static func check(level: Dictionary) -> PackedStringArray:
	var errs := LevelData.validate(level)
	if not errs.is_empty():
		return errs
	for hex in level.get("palette", []):
		if not Color.html_is_valid(hex):
			errs.append("bad palette color %s" % hex)
	if level.has("garage"):
		var g: Dictionary = Campaign.GARAGES[int(level["garage"]) - 1]
		if int(level["w"]) != g["w"] or int(level["h"]) != g["h"]:
			errs.append("size %dx%d != garage %dx%d" % [level["w"], level["h"], g["w"], g["h"]])
		var n: int = level["palette"].size()
		if n < 3 or n > g["colors"][1]:
			errs.append("%d colors outside 3-%d" % [n, g["colors"][1]])
	for q in level["queues"]:
		for t in q:
			if t.get("tow", false) and (int(t["n"]) < 5 or int(t["n"]) > 8):
				errs.append("tow truck number %d outside 5-8" % int(t["n"]))
	if not level.has("solution"):
		errs.append("no solution")
	elif not replay_wins(level):
		errs.append("solution does not replay to a win")
	return errs


static func replay_wins(level: Dictionary) -> bool:
	var e := GameEngine.new()
	if not e.load_level(level).is_empty():
		return false
	var last := 0
	for s in level["solution"]:
		e.push_command_at(int(s[0]), {"type": "tap", "queue": int(s[1])})
		last = maxi(last, int(s[0]))
	while not e.is_finished() and e.state.tick < last + LevelGenerator.MAX_TICKS:
		e.step()
	return e.state.phase == GameState.Phase.WON
