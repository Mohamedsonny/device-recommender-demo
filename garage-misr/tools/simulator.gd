## Plays levels headless on the real engine with the bots and measures outcomes.
class_name Simulator
extends RefCounted

const MAX_TICKS := 20000


## Plays one game. bot is "random" or "smart". Returns {"won": bool, "ticks": int}.
static func play(level: Dictionary, bot: String, rng_seed: int) -> Dictionary:
	var e := GameEngine.new()
	var errs := e.load_level(level)
	assert(errs.is_empty(), str(errs))
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	while not e.is_finished() and e.state.tick < MAX_TICKS:
		var q := Bots.choose_random(e.state, rng) if bot == "random" \
			else Bots.choose_smart(e.state, rng)
		if q >= 0:
			e.push_command({"type": "tap", "queue": q})
		e.step()
	return {"won": e.state.phase == GameState.Phase.WON, "ticks": e.state.tick}


## Fraction of games won by the bot over n seeds (seed offset keeps runs reproducible).
static func win_rate(level: Dictionary, bot: String, n: int, seed_offset := 0) -> float:
	var wins := 0
	for i in n:
		if play(level, bot, seed_offset + i)["won"]:
			wins += 1
	return float(wins) / n


## Random loss % and smart win % (0-100), the two numbers every report uses.
static func measure(level: Dictionary, n_random := 200, n_smart := 200) -> Dictionary:
	return {
		"random_loss": 100.0 * (1.0 - win_rate(level, "random", n_random)),
		"smart_win": 100.0 * win_rate(level, "smart", n_smart, 100000),
	}
