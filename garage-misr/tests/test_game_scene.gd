extends GutTest

const GAME := preload("res://scenes/game.tscn")


func _play_with_hints(game: Node, max_frames := 6000) -> void:
	var frames := 0
	while not game.engine.is_finished() and frames < max_frames:
		var q := Bots.choose_smart(game.engine.state)
		if q >= 0:
			game.tap_queue(q)
		game._process(GameEngine.TICK_SEC)
		frames += 1


func test_level_1_plays_to_a_win_through_the_ui():
	var game = GAME.instantiate()
	add_child_autofree(game)
	game.load_level(1)
	assert_eq(game.level_id, 1)
	assert_gt(game._queues.size(), 0, "queue buttons built")
	_play_with_hints(game)
	assert_eq(game.engine.state.phase, GameState.Phase.WON)
	assert_true(game._overlay.visible, "win overlay shown")
	assert_eq(game._overlay_label.text, Strings.t("win"))


func test_rejected_tap_shows_the_attendant_message():
	var game = GAME.instantiate()
	add_child_autofree(game)
	game.load_level(1)
	for i in 12:
		for q in game.engine.state.queues.size():
			game.tap_queue(q)
		game._process(GameEngine.TICK_SEC)
		if game._toast.visible:
			break
	assert_true(game._toast.visible)
	assert_string_contains(game._toast.text, Strings.t("bays_full"))


func test_restart_button_resets_the_level():
	var game = GAME.instantiate()
	add_child_autofree(game)
	game.load_level(1)
	var fresh: Dictionary = game.engine.snapshot()
	game.tap_queue(0)
	for i in 10:
		game._process(GameEngine.TICK_SEC)
	game.restart()
	game._process(GameEngine.TICK_SEC)
	assert_eq(game.engine.snapshot(), fresh)
