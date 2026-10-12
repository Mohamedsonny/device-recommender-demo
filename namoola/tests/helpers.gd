## Shared test helpers (not a test script: no test_ prefix).
extends RefCounted

const FIXTURE := "res://tests/fixtures/level_6x6.json"


static func fixture() -> Dictionary:
	return LevelLoader.load_file(FIXTURE)


static func engine_for(level: Dictionary) -> GameEngine:
	var e := GameEngine.new()
	var errs := e.load_level(level)
	assert(errs.is_empty(), str(errs))
	return e


## Random player: each tick, with probability p, taps a random non-empty column.
## Returns every tap pushed as {"tick", "col"} so it can be replayed. on_step(engine, events)
## is called after each step.
static func play_random(e: GameEngine, rng_seed: int, max_ticks: int, p := 0.3,
		on_step := Callable()) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var taps := []
	while e.state.tick < max_ticks and not e.is_finished():
		if rng.randf() < p:
			var cols := []
			for i in e.state.tray.size():
				if not e.state.tray[i].is_empty():
					cols.append(i)
			if not cols.is_empty():
				var col: int = cols[rng.randi_range(0, cols.size() - 1)]
				taps.append({"tick": e.state.tick, "col": col})
				e.push_command({"type": "tap", "col": col})
		var events := e.step()
		if on_step.is_valid():
			on_step.call(e, events)
	return taps


## Independent re-statement of the loss rule, read straight from the board arrays.
static func loss_rule_holds(s: GameState) -> bool:
	if s.slots.has(null) or not s.tasks.is_empty():
		return false
	for box in s.slots:
		for i in s.board.color.size():
			if s.board.color[i] == box.color and s.board.exposed[i] == 1 \
					and s.board.reserved[i] == 0:
				return false
	return true
