## Generates campaign levels into res://levels/NNN.json.
## Usage: godot --headless -s tools/build_levels.gd -- --from=1 --to=100
##        --variants=N tries N art variants per level (default 8)
##        --stride=4 builds every 4th level from --from (to run 4 processes in parallel);
##        add --before to only measure the old style (round robin, numbers 10-40, no tarps
##        or tow truck) and write reports/before_<from>_<to>.csv without saving levels.
extends SceneTree

var variants := 8


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var from := int(args.get("from", "1"))
	var to := int(args.get("to", "100"))
	var stride := int(args.get("stride", "1"))
	variants = int(args.get("variants", "8"))
	if args.has("before"):
		_before(from, to, stride)
	else:
		_build(from, to, stride)
	quit()


func _build(from: int, to: int, stride: int) -> void:
	for id in range(from, to + 1, stride):
		var cfg := Campaign.config(id)
		var t0 := Time.get_ticks_msec()
		var lv := LevelGenerator.generate(cfg, 40, 200, variants, func(m): print(m))
		if lv.is_empty():
			push_error("L%d: generation failed" % id)
			continue
		var errs := LevelValidator.check(lv)
		var f := FileAccess.open(LevelLoader.path_for(id), FileAccess.WRITE)
		f.store_string(JSON.stringify(lv, "  ", false))
		f.close()
		print("L%03d %s %s random_loss=%.1f%% smart_win=%.1f%% band=%s in_target=%s errs=%s (%ds)" % [
			id, cfg["garage_key"], cfg["item"], lv["stats"]["random_loss"], lv["stats"]["smart_win"],
			cfg["band"], lv["in_target"], errs, (Time.get_ticks_msec() - t0) / 1000])


func _before(from: int, to: int, stride: int) -> void:
	var f := FileAccess.open("res://reports/before_%03d_%03d.csv" % [from, to], FileAccess.WRITE)
	for id in range(from, to + 1, stride):
		var cfg := Campaign.config(id)
		cfg["numbers"] = [10, 40]
		cfg["tarps"] = false
		cfg["tow"] = false
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("level-%d" % id)
		var art := LevelGenerator.make_art(cfg, rng)
		var tr := LevelGenerator.trace(cfg, art["cells"], rng)
		var lv := LevelGenerator.build_level(cfg, art, tr, 0.0, rng)
		var m := Simulator.measure(lv, 200, 200)
		f.store_line("%d,%s,%s,%.1f,%.1f" % [id, cfg["garage_key"], cfg["item"], m["random_loss"], m["smart_win"]])
		print("before L%03d random_loss=%.1f smart_win=%.1f" % [id, m["random_loss"], m["smart_win"]])
	f.close()
