## Guaranteed-solvable level generator. It plays the garage on the real engine while it
## invents trailers, so every level ships with the tap sequence that clears it. Difficulty
## comes from how those trailers are laid out in the queues (see docs/LEVEL_GENERATION.md).
class_name LevelGenerator
extends RefCounted

const MAX_TICKS := 20000


## Plays the art and returns the solution trace: [{"c", "n", "tick"}] in the order the
## trailers entered bays, or [] if this run dead-locked (caller retries with another seed).
static func trace(cfg: Dictionary, cells: PackedByteArray, rng: RandomNumberGenerator) -> Array:
	var e := GameEngine.new()
	e.load_unchecked({"w": cfg["w"], "h": cfg["h"], "cells": Marshalls.raw_to_base64(cells),
		"queues": [[]], "bays": cfg["bays"], "gate": cfg["gate"]})
	var s := e.state
	var uncommitted := s.grid.remaining_by_color.duplicate()
	var lo: int = cfg["numbers"][0]
	var hi: int = cfg["numbers"][1]
	var out := []
	while not e.is_finished() and s.tick < MAX_TICKS:
		while s.free_bay() >= 0:
			var c := _pick_color(s, uncommitted, rng)
			if c < 0:
				break
			var n := mini(rng.randi_range(lo, hi), uncommitted[c])
			if uncommitted[c] - n < lo:
				n = uncommitted[c]  # last trailer of the color takes the exact remainder
			uncommitted[c] -= n
			var t := Trailer.make(s.trailers.size(), c, n)
			s.trailers.append(t)
			s.queues[0].append(t)
			Rules.apply_tap(s, 0)
			out.append({"c": c, "n": n, "tick": s.tick})
		e.step()
	return out if s.phase == GameState.Phase.WON else []


## A color with cars left to assign and free cars nobody in a bay is waiting for,
## weighted by that spare supply.
static func _pick_color(s: GameState, uncommitted: Dictionary, rng: RandomNumberGenerator) -> int:
	var total := 0
	var options := []
	for c in s.grid.colors():
		if uncommitted.get(c, 0) <= 0:
			continue
		var supply := Bots.net_supply(s, c)
		if supply > 0:
			options.append([c, supply])
			total += supply
	if options.is_empty():
		return -1
	var r := rng.randi_range(1, total)
	for o in options:
		r -= o[1]
		if r <= 0:
			return o[0]
	return options[-1][0]


## Lays the trace out in queues. trap 0 = round robin: every queue front is a trailer needed
## soon. trap 1 = the solution is cut into one chunk per queue, so all but one queue start
## with trailers for colors still locked deep in the garage. In between, each trailer is
## placed by the chunk rule with probability trap. Order inside each queue always follows
## the solution, so the stored tap sequence stays valid.
static func build_level(cfg: Dictionary, art: Dictionary, tr: Array, trap: float,
		rng: RandomNumberGenerator) -> Dictionary:
	var k: int = cfg["queues"]
	var queues := []
	for i in k:
		queues.append([])
	var order := range(k)  # which queue gets which chunk (seeded shuffle, reproducible)
	for i in range(k - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	var solution := []
	var n := tr.size()
	for i in n:
		@warning_ignore("integer_division")
		var q: int = order[mini(k - 1, i * k / n)] if rng.randf() < trap else (i + order[0]) % k
		var d := {"c": tr[i]["c"], "n": tr[i]["n"]}
		if cfg["tarps"] and not queues[q].is_empty() and rng.randf() < 0.25:
			d["hidden"] = true
		queues[q].append(d)
		solution.append([tr[i]["tick"], q])
	if cfg["tow"]:
		# At the back of a queue: it never blocks a solution trailer.
		queues[rng.randi_range(0, k - 1)].append({"tow": true, "n": rng.randi_range(5, 8)})
	return {
		"id": cfg["id"], "garage": cfg["garage"], "garage_name": cfg["garage_name"],
		"item": cfg["item"], "item_name": PlaceholderArt.ITEMS[cfg["item"]]["name"],
		"extreme": cfg["extreme"], "band": cfg["band"],
		"w": cfg["w"], "h": cfg["h"], "palette": art["palette"],
		"cells": Marshalls.raw_to_base64(art["cells"]),
		"queues": queues, "bays": cfg["bays"], "gate": cfg["gate"], "cars_per_tick": 3,
		"solution": solution, "trap": snappedf(trap, 0.001), "schema": 1,
	}


## Draws art whose color count is inside the garage range.
static func make_art(cfg: Dictionary, rng: RandomNumberGenerator, floor := 0.0) -> Dictionary:
	var art := {}
	for attempt in 20:
		art = PlaceholderArt.draw(cfg["item"], cfg["w"], cfg["h"], cfg["colors"], rng, floor)
		if art["colors"] >= mini(cfg["colors"], 3) and art["colors"] <= cfg["colors"]:
			return art
	return art


const FLOORS := [0.0, 0.3, 0.45, 0.2, 0.35, 0.5, 0.25, 0.4]
const TRAPS := [0.0, 0.25, 0.5, 0.75, 1.0, 0.125, 0.375, 0.625, 0.875]


## Rejection sampling over art variants (jitter + floor height) and trap values. A candidate
## is screened with `quick` RandomBot games, then measured with `final` games per bot. It is
## accepted when RandomBot loss is inside the level's sawtooth target, SmartBot wins >= 90%
## and the validator passes; a level inside the band but not the target is kept as a
## fallback. Returns the level dict with "stats" and "in_target", or {} if nothing worked.
static func generate(cfg: Dictionary, quick := 40, final := 200, max_variants := 8,
		log := Callable()) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("level-%d" % cfg["id"])
	var tgt: Array = cfg["target"]
	var band: Array = cfg["band"]
	var tutorial: bool = band[1] <= 0.0
	var fallback := {}
	var fallback_err := INF
	if cfg["extreme"]:
		max_variants *= 2
	for v in max_variants:
		var floor: float = 0.0 if tutorial else FLOORS[v % FLOORS.size()]
		var art := make_art(cfg, rng, floor)
		var tr := trace(cfg, art["cells"], rng)
		if tr.is_empty():
			continue
		var traps: Array = [0.0] if tutorial else TRAPS
		for trap in traps:
			var lv := build_level(cfg, art, tr, trap, rng)
			var loss := 100.0 * (1.0 - Simulator.win_rate(lv, "random", quick))
			var err := _miss({"random_loss": loss}, tgt)
			if log.is_valid():
				log.call("  L%d v%d floor %.2f trap %.3f -> quick random loss %.1f%%" % [
					cfg["id"], v, floor, trap, loss])
			if err > 0.0 and _miss({"random_loss": loss}, band) > 0.0:
				continue
			var fm := Simulator.measure(lv, final, final)
			lv["stats"] = fm
			lv["floor"] = floor
			if log.is_valid():
				log.call("  L%d final: random loss %.1f%% smart %.1f%%" % [cfg["id"],
					fm["random_loss"], fm["smart_win"]])
			if fm["smart_win"] < Campaign.SMART_MIN_WIN or not LevelValidator.check(lv).is_empty():
				continue
			var ferr := _miss(fm, tgt)
			if ferr == 0.0:
				lv["in_target"] = true
				return lv
			if _miss(fm, band) == 0.0 and (fallback.is_empty() or ferr < fallback_err):
				lv["in_target"] = false
				fallback = lv
				fallback_err = ferr
	return fallback


static func _miss(m: Dictionary, band: Array) -> float:
	var x: float = m["random_loss"]
	return maxf(0.0, band[0] - x) + maxf(0.0, x - band[1])
