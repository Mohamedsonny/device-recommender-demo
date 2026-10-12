extends GutTest

const H := preload("res://tests/helpers.gd")
const SEEDS := [1, 2, 3, 7, 42, 99, 1234, 2026]
const CARS := 36


func _tap(e: GameEngine, q: int) -> void:
	e.push_command({"type": "tap", "queue": q})


func _run_to_end(e: GameEngine, max_ticks := 5000) -> void:
	while not e.is_finished() and e.state.tick < max_ticks:
		e.step()


## Steps until the bay empties; bounded so a broken engine fails the test instead of hanging.
func _step_until_bay_free(e: GameEngine, bay := 0, max_ticks := 200) -> Array:
	var events := []
	var n := 0
	while e.state.bays[bay] != null and n < max_ticks:
		assert_eq(e.state.phase, GameState.Phase.RUNNING)
		events.append_array(e.step())
		n += 1
	assert_lt(n, max_ticks, "bay %d freed" % bay)
	return events


func _replay(level: Dictionary, taps: Array) -> GameEngine:
	var e := H.engine_for(level)
	for t in taps:
		e.push_command_at(t["tick"], {"type": "tap", "queue": t["queue"]})
	return e


func _of(events: Array, type: String) -> Array:
	return events.filter(func(ev): return ev["type"] == type)


# --- determinism ---------------------------------------------------------------

func test_determinism_same_taps_same_final_state():
	for lv in [H.fixture(), H.fixture_with_tow()]:
		for s in SEEDS:
			var a := H.engine_for(lv)
			var taps := H.play_random(a, s, 5000)
			assert_true(a.is_finished(), "seed %d finished" % s)
			var b := _replay(lv, taps)
			_run_to_end(b)
			assert_eq(b.snapshot(), a.snapshot(), "seed %d replay matches" % s)
			assert_eq(b.state_hash(), a.state_hash())


func test_1x_and_2x_reach_identical_state():
	for s in SEEDS:
		var ref := H.engine_for(H.fixture())
		var taps := H.play_random(ref, s, 5000)
		for speed in [1.0, 2.0]:
			var e := _replay(H.fixture(), taps)
			var frames := 0
			while not e.is_finished() and frames < 100000:
				e.advance(1.0 / 60.0, speed)
				frames += 1
			assert_eq(e.snapshot(), ref.snapshot(), "seed %d at %sx" % [s, speed])


func test_2x_runs_twice_as_many_ticks_per_second():
	var a := H.engine_for(H.fixture())
	var b := H.engine_for(H.fixture())
	for i in 60:
		a.advance(1.0 / 60.0, 1.0)
		b.advance(1.0 / 60.0, 2.0)
	assert_almost_eq(a.state.tick, 20, 1)
	assert_almost_eq(b.state.tick, 40, 1)


# --- safety invariants over random play ----------------------------------------

func test_no_car_loaded_twice_in_1000_random_ticks():
	for lv in [H.fixture(), H.fixture_with_tow()]:
		for s in SEEDS:
			var e := H.engine_for(lv)
			var loaded := {}
			var dupes := [0]
			H.play_random(e, s, 1000, 0.3, func(_e, events):
				for ev in events:
					if ev["type"] == "car_loaded":
						if loaded.has(ev["cell"]):
							dupes[0] += 1
						loaded[ev["cell"]] = true)
			assert_eq(dupes[0], 0, "seed %d: no car loaded twice" % s)
			assert_eq(loaded.size() + e.state.grid.remaining_total, CARS,
				"seed %d: loaded + parked = all" % s)


func test_numbers_never_negative_and_balance_holds_every_tick():
	for lv in [H.fixture(), H.fixture_with_tow()]:
		for s in SEEDS:
			var e := H.engine_for(lv)
			var bad := [0, 0, 0]
			assert_true(Rules.balance_ok(e.state))
			H.play_random(e, s, 5000, 0.3, func(eng, _events):
				for t in eng.state.trailers:
					if t.count < 0 or t.inflight < 0:
						bad[0] += 1
					if t.inflight > t.count:
						bad[1] += 1
				if not Rules.balance_ok(eng.state):
					bad[2] += 1)
			assert_eq(bad, [0, 0, 0], "seed %d: [negative, overcall, imbalance] ticks" % s)


func test_win_only_when_garage_empty():
	var wins := 0
	for s in SEEDS:
		var e := H.engine_for(H.fixture())
		H.play_random(e, s, 5000)
		if e.state.phase == GameState.Phase.WON:
			wins += 1
			for c in e.state.grid.color:
				assert_eq(c, GarageGrid.ASPHALT)
			for t in e.state.trailers:
				assert_eq(t.state, Trailer.State.DONE)
	assert_gt(wins, 0, "at least one random game won")


func test_loss_only_by_the_rule():
	for bays in [5, 2]:
		for lv in [H.fixture(), H.fixture_with_tow()]:
			lv["bays"] = bays
			var losses := 0
			var mismatches := [0]
			for s in range(200):
				var e := H.engine_for(lv)
				H.play_random(e, s, 5000, 0.6, func(eng, _events):
					var lost: bool = eng.state.phase == GameState.Phase.LOST
					if lost != H.loss_rule_holds(eng.state):
						mismatches[0] += 1)
				if e.state.phase == GameState.Phase.LOST:
					losses += 1
			assert_eq(mismatches[0], 0, "%d bays: LOST exactly when the rule holds" % bays)
			gut.p("random losses, %d bays, tow=%s: %d / 200" % [bays,
				lv["queues"][2].size() > 1, losses])
			if bays == 2:
				assert_gt(losses, 0, "the 2-bay variant must exercise real losses")


# --- taps and bays ---------------------------------------------------------------

func test_double_tap_in_one_tick_never_double_books_a_bay():
	var e := H.engine_for(H.fixture())
	for i in 10:
		_tap(e, 0)
	var events := e.step()
	assert_eq(_of(events, "trailer_to_bay").size(), 3, "queue 0 has 3 trailers")
	assert_eq(e.state.bays.map(func(t): return -1 if t == null else t.id), [0, 1, 2, -1, -1])
	for i in 10:
		_tap(e, 1)
		_tap(e, 2)
	events = e.step()
	assert_eq(_of(events, "trailer_to_bay").size(), 2, "only 2 free bays left")
	assert_eq(_of(events, "tap_rejected").size(), 18)
	var ids := e.state.bays.map(func(t): return t.id)
	ids.sort()
	assert_eq(ids, [0, 1, 2, 3, 5], "five distinct trailers")


func test_tap_rejected_when_bays_full():
	var lv := H.fixture()
	lv["bays"] = 1
	var e := H.engine_for(lv)
	_tap(e, 0)
	_tap(e, 2)
	var rejected := _of(e.step(), "tap_rejected")
	assert_eq(rejected.size(), 1)
	assert_eq(rejected[0]["reason"], "bays_full")
	assert_eq(e.state.queues[2].size(), 1, "rejected trailer stays in its queue")


func test_tarp_trailer_revealed_at_front():
	var e := H.engine_for(H.fixture())
	var covered: Trailer = e.state.queues[1][1]
	assert_true(covered.hidden)
	_tap(e, 1)
	var events := e.step()
	assert_false(covered.hidden)
	assert_eq(_of(events, "trailer_revealed").size(), 1)


func test_trailer_never_calls_more_than_its_number():
	var lv := {"w": 4, "h": 1, "rows": ["0000"], "bays": 2, "cars_per_tick": 3,
		"queues": [[{"c": 0, "n": 1}, {"c": 0, "n": 3}]]}
	var e := H.engine_for(lv)
	_tap(e, 0)
	assert_eq(_of(e.step(), "car_called").size(), 1)
	assert_eq(e.state.grid.reserved.count(1), 1)


func test_waiting_trailer_does_not_block_others():
	# Color 2 is buried behind color 0; its trailer waits while color 0 keeps loading.
	var e := H.engine_for(_tower(2))
	_tap(e, 1)
	_tap(e, 0)
	_run_to_end(e)
	assert_eq(e.state.phase, GameState.Phase.WON)


# --- restart -------------------------------------------------------------------

func test_restart_mid_loading_resets_everything():
	var e := H.engine_for(H.fixture())
	var fresh := H.engine_for(H.fixture()).snapshot()
	_tap(e, 0)
	_tap(e, 1)
	var loaded := 0
	for i in 8:
		loaded += _of(e.step(), "car_loaded").size()
	assert_gt(loaded, 0, "some cars loaded")
	assert_false(e.state.tasks.is_empty(), "cars still driving")
	var old_rev := e.state.level_rev
	e.push_command({"type": "restart"})
	_tap(e, 2)  # queued behind the restart: belongs to the old attempt, dropped
	var events := e.step()
	assert_eq(e.state.level_rev, old_rev + 1)
	assert_eq(events.back()["type"], "restarted")
	assert_eq(e.snapshot(), fresh, "state equals a fresh load")
	assert_true(e.command_log.is_empty())
	for i in 50:
		for ev in e.step():
			assert_eq(ev["rev"], old_rev + 1)
	assert_eq(e.state.grid.remaining_total, CARS)


func test_stale_car_tasks_are_ignored():
	var e := H.engine_for(H.fixture())
	_tap(e, 0)
	e.step()
	assert_false(e.state.tasks.is_empty())
	var before := e.state.grid.remaining_total
	for t in e.state.tasks:
		t.level_rev -= 1  # pretend they belong to an older attempt
		t.ticks_left = 1
	e.step()
	assert_eq(e.state.grid.remaining_total, before, "stale arrivals loaded nothing")


# --- loss rule, hand-built -------------------------------------------------------

## One column: a color-2 car parked behind a color-0 car at the gate.
func _tower(bays := 1) -> Dictionary:
	return {"w": 1, "h": 2, "rows": ["2", "0"], "bays": bays,
		"queues": [[{"c": 0, "n": 1}], [{"c": 2, "n": 1}]]}


func test_loss_when_bay_holds_a_locked_color():
	var e := H.engine_for(_tower())
	_tap(e, 1)
	var events := e.step()
	assert_eq(e.state.phase, GameState.Phase.LOST)
	assert_eq(events.back()["type"], "lost")


func test_full_bays_with_cars_driving_is_not_a_loss():
	var e := H.engine_for(_tower())
	_tap(e, 0)
	e.step()
	assert_eq(e.state.free_bay(), -1, "bay full")
	assert_false(e.state.tasks.is_empty(), "car on its way")
	_step_until_bay_free(e)
	_tap(e, 1)
	_run_to_end(e)
	assert_eq(e.state.phase, GameState.Phase.WON)


func test_waiting_trailer_with_free_bay_is_not_a_loss():
	var e := H.engine_for(_tower(2))
	_tap(e, 1)
	for i in 20:
		e.step()
	assert_eq(e.state.phase, GameState.Phase.RUNNING, "color 2 waits, a bay is still free")


func test_taps_after_game_over_are_rejected():
	var e := H.engine_for(_tower())
	_tap(e, 1)
	e.step()
	_tap(e, 0)
	assert_eq(e.step()[0]["reason"], "not_running")


# --- tow truck ---------------------------------------------------------------------

func test_tow_truck_takes_a_free_car_of_another_color():
	var lv := _tower()
	lv["queues"].append([{"tow": true, "n": 1}])
	var e := H.engine_for(lv)
	_tap(e, 2)
	var called := _of(e.step(), "car_called")
	assert_eq(called.size(), 1)
	assert_eq(called[0]["color"], 0)
	assert_true(called[0]["towed"])
	assert_eq(called[0]["charge"], 0, "charged to the color-0 trailer")
	var events := _step_until_bay_free(e)
	assert_eq(_of(events, "trailer_emptied").size(), 1, "color-0 trailer used up in its queue")
	assert_true(e.state.queues[0].is_empty())
	assert_true(Rules.balance_ok(e.state))
	_tap(e, 1)
	_run_to_end(e)
	assert_eq(e.state.phase, GameState.Phase.WON)


func test_tow_truck_charges_the_largest_remaining_trailer():
	var lv := {"w": 6, "h": 1, "rows": ["000000"], "bays": 2,
		"queues": [[{"tow": true, "n": 2}], [{"c": 0, "n": 2}, {"c": 0, "n": 4}]]}
	var e := H.engine_for(lv)
	_tap(e, 0)
	var called := _of(e.step(), "car_called")
	assert_eq(called.size(), 2)
	# both charges go to whichever trailer has more left to call at that moment: 4 -> 3, then 3 vs 2
	assert_eq(called.map(func(c): return c["charge"]), [2, 2])
	_run_to_end(e, 40)
	assert_eq(e.state.trailers[2].count, 2)
	assert_true(Rules.balance_ok(e.state))


func test_tow_truck_prefers_colors_no_bay_is_calling():
	var lv := {"w": 2, "h": 1, "rows": ["01"], "bays": 2, "cars_per_tick": 1,
		"queues": [[{"c": 0, "n": 1}], [{"tow": true, "n": 1}], [{"c": 1, "n": 1}]]}
	var e := H.engine_for(lv)
	_tap(e, 1)
	_tap(e, 0)
	var called := _of(e.step(), "car_called")
	assert_eq(called.map(func(c): return [c["trailer"], c["color"]]), [[1, 1], [0, 0]])


func test_tow_truck_in_bay_prevents_loss_while_any_car_is_free():
	var lv := _tower()
	lv["bays"] = 2
	lv["queues"].append([{"tow": true, "n": 1}])
	var e := H.engine_for(lv)
	_tap(e, 1)  # color 2, locked
	_tap(e, 2)  # tow truck: takes the color-0 car and frees the color-2 car
	_run_to_end(e)
	assert_eq(e.state.phase, GameState.Phase.WON)


# --- level validation ---------------------------------------------------------------

func test_fixture_is_valid():
	assert_eq(LevelData.validate(H.fixture()), PackedStringArray())
	assert_eq(LevelData.validate(H.fixture_with_tow()), PackedStringArray())


func test_unbalanced_level_is_rejected():
	var lv := H.fixture()
	lv["queues"][2][0]["n"] = 4
	var errs := GameEngine.new().load_level(lv)
	assert_eq(errs.size(), 1)
	assert_string_contains(errs[0], "balance: color 1")


func test_bad_levels_are_rejected():
	var lv := H.fixture()
	lv["queues"][0][0]["n"] = 0
	assert_gt(LevelData.validate(lv).size(), 0, "zero number")
	lv = H.fixture()
	lv["rows"][0] = "0011"
	assert_gt(LevelData.validate(lv).size(), 0, "wrong size")
	lv = H.fixture()
	lv["rows"][0] = "001130"
	assert_gt(LevelData.validate(lv).size(), 0, "color outside palette")
	lv = H.fixture()
	lv["gate"] = "roof"
	assert_gt(LevelData.validate(lv).size(), 0, "unknown gate")


func test_base64_cells_match_rows():
	var lv := H.fixture()
	var raw := LevelData.cells(lv)
	lv.erase("rows")
	lv["cells"] = Marshalls.raw_to_base64(raw)
	assert_eq(H.engine_for(lv).snapshot(), H.engine_for(H.fixture()).snapshot())
