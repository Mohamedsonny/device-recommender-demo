## Opens the game on a level, plays a few seconds with hints and saves a screenshot.
## Needs a display (e.g. xvfb-run): godot --rendering-driver opengl3 -s tools/screenshot.gd -- --level=12 --ticks=60
extends SceneTree


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_run(int(args.get("level", "1")), int(args.get("ticks", "40")), args.get("out", "res://reports/screenshot.png"))


func _run(level: int, ticks: int, out: String) -> void:
	await process_frame
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.load_level(level)
	game.set_process(false)
	for i in ticks:
		var q := Bots.choose_smart(game.engine.state)
		if q >= 0 and i % 6 == 0:
			game.tap_queue(q)
		game._process(GameEngine.TICK_SEC)
	game.show_hint()
	game._process(0.001)
	for i in 4:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
