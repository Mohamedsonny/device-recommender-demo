extends GutTest

const H := preload("res://tests/helpers.gd")
const SEEDS := [1, 2, 3, 7, 42, 99, 1234, 2026]


func _tap(e: GameEngine, col: int) -> void:
	e.push_command({"type": "tap", "col": col})


func _run_to_end(e: GameEngine, max_ticks := 5000) -> void:
	while not e.is_finished() and e.state.tick < max_ticks:
		e.step()


func _replay(level: Dictionary, taps: Array) -> GameEngine:
	var e := H.engine_for(level)
	for t in taps:
		e.push_command_at(t["tick"], {"type": "tap", "col": t["col"]})
	return e


# --- determinism ---------------------------------------------------------------

func test_determinism_same_taps_same_final_state():
	for s in SEEDS:
		var a := H.engine_for(H.fixture())
		var taps := H.play_random(a, s, 5000)
		assert_true(a.is_finished(), "seed %d finished" % s)
		var b := _replay(H.fixture(), taps)
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

func test_no_pixel_eaten_twice_in_1000_random_ticks():
	for s in SEEDS:
		var e := H.engine_for(H.fixture())
		var eaten := {}
		var dupes := [0]
		H.play_random(e, s, 1000, 0.3, func(_e, events):
			for ev in events:
				if ev["type"] == "pixel_eaten":
					if eaten.has(ev["cell"]):
						dupes[0] += 1
					eaten[ev["cell"]] = true)
		assert_eq(dupes[0], 0, "seed %d: no double eat" % s)
		assert_eq(eaten.size() + e.state.board.remaining_total, 36, "seed %d: eaten + left = all" % s)
		if e.state.phase == GameState.Phase.WON:
			assert_eq(eaten.size(), 36)


func test_counts_never_negative_and_balance_holds_every_tick():
	for s in SEEDS:
		var e := H.engine_for(H.fixture())
		var bad := [0, 0, 0]
		assert_true(Rules.balance_ok(e.state))
		H.play_random(e, s, 5000, 0.3, func(eng, _events):
			for b in eng.state.boxes:
				if b.count < 0 or b.inflight < 0:
					bad[0] += 1
				if b.inflight > b.count:
					bad[1] += 1
			if not Rules.balance_ok(eng.state):
				bad[2] += 1)
		assert_eq(bad, [0, 0, 0], "seed %d: [negative, overdispatch, imbalance] ticks" % s)


func test_win_only_when_board_empty():
	var wins := 0
	for s in SEEDS:
		var e := H.engine_for(H.fixture())
		H.play_random(e, s, 5000)
		if e.state.phase == GameState.Phase.WON:
			wins += 1
			for c in e.state.board.color:
				assert_eq(c, BoardState.EMPTY)
			for b in e.state.boxes:
				assert_eq(b.state, Box.State.DONE)
	assert_gt(wins, 0, "at least one random game won")


func test_loss_only_by_the_rule():
	for slots in [5, 2]:
		_check_loss_rule(slots)


func _check_loss_rule(slots: int) -> void:
	var lv := H.fixture()
	lv["slots"] = slots
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
	assert_eq(mismatches[0], 0, "%d slots: LOST exactly when the rule holds" % slots)
	gut.p("random losses on fixture with %d slots: %d / 200" % [slots, losses])
	if slots == 2:
		assert_gt(losses, 0, "the 2-slot variant must exercise real losses")


# --- taps and slots ------------------------------------------------------------

func test_double_tap_in_one_tick_never_double_books_a_slot():
	var e := H.engine_for(H.fixture())
	for i in 10:
		_tap(e, 0)
	var events := e.step()
	var placed := events.filter(func(ev): return ev["type"] == "box_to_slot")
	assert_eq(placed.size(), 3, "column 0 has 3 boxes")
	assert_eq(e.state.slots.map(func(b): return -1 if b == null else b.id), [0, 1, 2, -1, -1])
	for i in 10:
		_tap(e, 1)
		_tap(e, 2)
	events = e.step()
	placed = events.filter(func(ev): return ev["type"] == "box_to_slot")
	var rejected := events.filter(func(ev): return ev["type"] == "tap_rejected")
	assert_eq(placed.size(), 2, "only 2 free slots left")
	assert_eq(rejected.size(), 18)
	var ids := e.state.slots.map(func(b): return b.id)
	ids.sort()
	assert_eq(ids, [0, 1, 2, 3, 5], "five distinct boxes")


func test_tap_rejected_when_slots_full():
	var lv := H.fixture()
	lv["slots"] = 1
	var e := H.engine_for(lv)
	_tap(e, 0)
	_tap(e, 2)
	var events := e.step()
	var rejected := events.filter(func(ev): return ev["type"] == "tap_rejected")
	assert_eq(rejected.size(), 1)
	assert_eq(rejected[0]["reason"], "slots_full")
	assert_eq(e.state.tray[2].size(), 1, "rejected box stays in tray")


func test_hidden_box_revealed_at_top():
	var e := H.engine_for(H.fixture())
	var hidden: Box = e.state.tray[1][1]
	assert_true(hidden.hidden)
	_tap(e, 1)
	var events := e.step()
	assert_false(hidden.hidden)
	assert_eq(events.filter(func(ev): return ev["type"] == "box_revealed").size(), 1)


func test_box_never_dispatches_more_than_its_count():
	var lv := {"w": 4, "h": 1, "rows": ["0000"], "slots": 2, "ants_per_tick": 3,
		"tray": [[{"c": 0, "n": 1}, {"c": 0, "n": 3}]]}
	var e := H.engine_for(lv)
	_tap(e, 0)
	var events := e.step()
	assert_eq(events.filter(func(ev): return ev["type"] == "ant_dispatched").size(), 1)
	assert_eq(e.state.board.reserved.count(1), 1)


# --- restart -------------------------------------------------------------------

func test_restart_mid_eating_resets_everything():
	var e := H.engine_for(H.fixture())
	var fresh := H.engine_for(H.fixture()).snapshot()
	_tap(e, 0)
	_tap(e, 1)
	var eaten := 0
	for i in 8:
		eaten += e.step().filter(func(ev): return ev["type"] == "pixel_eaten").size()
	assert_gt(eaten, 0, "some pixels eaten")
	assert_false(e.state.tasks.is_empty(), "ants still in flight")
	var old_rev := e.state.level_rev
	e.push_command({"type": "restart"})
	_tap(e, 2)  # queued behind the restart: belongs to the old attempt, dropped
	var events := e.step()
	assert_eq(e.state.level_rev, old_rev + 1)
	assert_eq(events.back()["type"], "restarted")
	assert_eq(e.snapshot(), fresh, "state equals a fresh load")
	assert_true(e.command_log.is_empty())
	# Nothing from the old attempt leaks into the new one.
	for i in 50:
		for ev in e.step():
			assert_eq(ev["rev"], old_rev + 1)
	assert_eq(e.state.board.remaining_total, 36)


func test_stale_ant_tasks_are_ignored():
	var e := H.engine_for(H.fixture())
	_tap(e, 0)
	e.step()
	assert_false(e.state.tasks.is_empty())
	var before := e.state.board.remaining_total
	for t in e.state.tasks:
		t.level_rev -= 1  # pretend they belong to an older attempt
		t.ticks_left = 1
	e.step()
	assert_eq(e.state.board.remaining_total, before, "stale arrivals ate nothing")


# --- loss rule, hand-built -------------------------------------------------------

func _tower() -> Dictionary:
	# 1 column: color 2 on top, color 0 at the bottom (the entry). One slot.
	return {"w": 1, "h": 2, "rows": ["2", "0"], "slots": 1,
		"tray": [[{"c": 0, "n": 1}], [{"c": 2, "n": 1}]]}


func test_loss_when_slot_holds_a_buried_color():
	var e := H.engine_for(_tower())
	_tap(e, 1)
	var events := e.step()
	assert_eq(e.state.phase, GameState.Phase.LOST)
	assert_eq(events.back()["type"], "lost")


func test_full_slots_with_ants_in_flight_is_not_a_loss():
	var e := H.engine_for(_tower())
	_tap(e, 0)
	e.step()
	assert_eq(e.state.free_slot(), -1, "slot full")
	assert_false(e.state.tasks.is_empty(), "ant on its way")
	assert_eq(e.state.phase, GameState.Phase.RUNNING)
	while e.state.slots[0] != null:
		e.step()
		assert_eq(e.state.phase, GameState.Phase.RUNNING)
	_tap(e, 1)
	_run_to_end(e)
	assert_eq(e.state.phase, GameState.Phase.WON)


func test_waiting_box_with_free_slot_is_not_a_loss():
	var lv := _tower()
	lv["slots"] = 2
	var e := H.engine_for(lv)
	_tap(e, 1)
	for i in 20:
		e.step()
	assert_eq(e.state.phase, GameState.Phase.RUNNING, "color 2 waits, a slot is still free")
	_tap(e, 0)
	_run_to_end(e)
	assert_eq(e.state.phase, GameState.Phase.WON)


func test_taps_after_game_over_are_rejected():
	var e := H.engine_for(_tower())
	_tap(e, 1)
	e.step()
	_tap(e, 0)
	var events := e.step()
	assert_eq(events[0]["reason"], "not_running")


# --- level validation ---------------------------------------------------------------

func test_fixture_is_valid():
	assert_eq(LevelData.validate(H.fixture()), PackedStringArray())


func test_unbalanced_level_is_rejected():
	var lv := H.fixture()
	lv["tray"][2][0]["n"] = 4
	var e := GameEngine.new()
	var errs := e.load_level(lv)
	assert_eq(errs.size(), 1)
	assert_string_contains(errs[0], "balance: color 1")


func test_bad_levels_are_rejected():
	var lv := H.fixture()
	lv["tray"][0][0]["n"] = 0
	assert_gt(LevelData.validate(lv).size(), 0, "zero count")
	lv = H.fixture()
	lv["rows"][0] = "0011"
	assert_gt(LevelData.validate(lv).size(), 0, "wrong dimensions")
	lv = H.fixture()
	lv["rows"][0] = "001130"
	assert_gt(LevelData.validate(lv).size(), 0, "color outside palette")


func test_base64_pixels_match_rows():
	var lv := H.fixture()
	var raw := LevelData.cells(lv)
	lv.erase("rows")
	lv["pixels"] = Marshalls.raw_to_base64(raw)
	var a := H.engine_for(H.fixture())
	var b := H.engine_for(lv)
	assert_eq(b.snapshot(), a.snapshot())
