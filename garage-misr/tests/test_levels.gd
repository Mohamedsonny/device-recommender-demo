extends GutTest
## Every shipped level must pass the validator, including replaying its stored solution.


func _level_files() -> Array:
	var out := []
	var dir := DirAccess.open("res://levels")
	for f in dir.get_files():
		if f.ends_with(".json"):
			out.append("res://levels/" + f)
	out.sort()
	return out


func test_levels_exist():
	assert_gt(_level_files().size(), 0)


func test_every_level_passes_the_validator():
	var bad := []
	for path in _level_files():
		var errs := LevelValidator.check(LevelLoader.load_file(path))
		if not errs.is_empty():
			bad.append("%s: %s" % [path, errs])
	assert_eq(bad, [], "all levels valid and solvable")


func test_levels_follow_the_campaign():
	for path in _level_files():
		var lv := LevelLoader.load_file(path)
		var id := int(lv["id"])
		assert_eq(path, LevelLoader.path_for(id))
		var cfg := Campaign.config(id)
		assert_eq(int(lv["garage"]), cfg["garage"], "L%d garage" % id)
		assert_eq(lv["extreme"], Campaign.is_extreme(id), "L%d extreme" % id)
		var has_tow := false
		var has_tarp := false
		for q in lv["queues"]:
			for t in q:
				has_tow = has_tow or t.get("tow", false)
				has_tarp = has_tarp or t.get("hidden", false)
		assert_eq(has_tow, id >= 41, "L%d tow truck only from 41" % id)
		if id < 41:
			assert_false(has_tarp, "L%d no tarps before 41" % id)


func test_generator_is_reproducible():
	var cfg := Campaign.config(7)
	var a := RandomNumberGenerator.new()
	a.seed = 5
	var b := RandomNumberGenerator.new()
	b.seed = 5
	var art_a := LevelGenerator.make_art(cfg, a, 0.3)
	var art_b := LevelGenerator.make_art(cfg, b, 0.3)
	assert_eq(art_a["cells"], art_b["cells"])
	var la := LevelGenerator.build_level(cfg, art_a, LevelGenerator.trace(cfg, art_a["cells"], a), 0.5, a)
	var lb := LevelGenerator.build_level(cfg, art_b, LevelGenerator.trace(cfg, art_b["cells"], b), 0.5, b)
	assert_eq(JSON.stringify(la), JSON.stringify(lb))
	assert_eq(LevelValidator.check(la), PackedStringArray())


func test_bots_keep_the_balance():
	var lv := LevelLoader.load_file(_level_files()[0])
	for bot in ["random", "smart"]:
		var e := GameEngine.new()
		e.load_level(lv)
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		while not e.is_finished() and e.state.tick < 5000:
			var q := Bots.choose_random(e.state, rng) if bot == "random" else Bots.choose_smart(e.state, rng)
			if q >= 0:
				e.push_command({"type": "tap", "queue": q})
			e.step()
			assert_true(Rules.balance_ok(e.state))
		assert_true(e.is_finished(), bot + " finished")
