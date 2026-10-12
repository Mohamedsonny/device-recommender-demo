## Shared test helpers (not a test script: no test_ prefix).
extends RefCounted

const FIXTURE := "res://tests/fixtures/garage_6x6.json"


static func fixture() -> Dictionary:
	return LevelLoader.load_file(FIXTURE)


## The fixture with a tow truck (number 6) appended to the back of queue 2.
static func fixture_with_tow() -> Dictionary:
	var lv := fixture()
	lv["queues"][2].append({"tow": true, "n": 6})
	return lv


static func engine_for(level: Dictionary) -> GameEngine:
	var e := GameEngine.new()
	var errs := e.load_level(level)
	assert(errs.is_empty(), str(errs))
	return e


## Random player: each tick, with probability p, taps a random non-empty queue.
## Returns every tap pushed as {"tick", "queue"} so it can be replayed. on_step(engine, events)
## is called after each step.
static func play_random(e: GameEngine, rng_seed: int, max_ticks: int, p := 0.3,
		on_step := Callable()) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var taps := []
	while e.state.tick < max_ticks and not e.is_finished():
		if rng.randf() < p:
			var qs := []
			for i in e.state.queues.size():
				if not e.state.queues[i].is_empty():
					qs.append(i)
			if not qs.is_empty():
				var q: int = qs[rng.randi_range(0, qs.size() - 1)]
				taps.append({"tick": e.state.tick, "queue": q})
				e.push_command({"type": "tap", "queue": q})
		var events := e.step()
		if on_step.is_valid():
			on_step.call(e, events)
	return taps


## Independent re-statement of the loss rule, read straight from the grid arrays.
static func loss_rule_holds(s: GameState) -> bool:
	if s.bays.has(null) or not s.tasks.is_empty():
		return false
	for t in s.bays:
		for i in s.grid.color.size():
			var c := s.grid.color[i]
			if c != GarageGrid.ASPHALT and (t.is_tow or c == t.color) \
					and s.grid.free[i] == 1 and s.grid.reserved[i] == 0:
				return false
	return true
