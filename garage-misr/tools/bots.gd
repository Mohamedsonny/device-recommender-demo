## Automatic players used by the simulator, the generator and the hint button.
## Each choose_* returns the queue index to tap this tick, or -1 to wait.
class_name Bots
extends RefCounted


## RandomBot: whenever a bay is free, taps any non-empty queue at random.
static func choose_random(s: GameState, rng: RandomNumberGenerator) -> int:
	if s.free_bay() < 0:
		return -1
	var qs := _tappable(s)
	return -1 if qs.is_empty() else qs[rng.randi_range(0, qs.size() - 1)]


## SmartBot: taps a front trailer whose color has free cars nobody in a bay is already
## waiting for (picking at random among the near-best, like a person would). Never fills the
## last free bay with a color that has no free cars unless nothing else can make progress.
## With 3+ free bays and no good choice it pre-places the locked color closest to the gate.
## It hesitates on HESITATE of ticks, so runs differ from seed to seed.
const HESITATE := 0.3


static func choose_smart(s: GameState, rng: RandomNumberGenerator = null) -> int:
	var free_bays := s.bays.count(null)
	if free_bays == 0:
		return -1
	if rng != null and rng.randf() < HESITATE:
		return -1
	var qs := _tappable(s)
	if qs.is_empty():
		return -1
	var good := []
	var best_supply := 0
	var tow := -1
	for q in qs:
		var t: Trailer = s.queues[q][0]
		if t.is_tow:
			tow = q
			continue
		var supply := net_supply(s, t.color)
		if supply > 0:
			good.append([q, supply])
			best_supply = maxi(best_supply, supply)
	if not good.is_empty():
		var near := good.filter(func(g): return g[1] * 10 >= best_supply * 6)
		return near[0][0] if rng == null else near[rng.randi_range(0, near.size() - 1)][0]
	var progressing := not s.tasks.is_empty()
	if not progressing:
		for t in s.bays:
			if t != null and (s.any_free_car() if t.is_tow else s.grid.has_free(t.color)):
				progressing = true
				break
	if tow >= 0 and (not progressing or free_bays > 1) and s.any_free_car():
		return tow
	if not progressing or free_bays > 2:
		return _closest_locked(s, qs)
	return -1


## Free, unreserved cars of color c minus what bay trailers of that color still need.
static func net_supply(s: GameState, c: int) -> int:
	var n := s.grid.free_count(c)
	for t in s.bays:
		if t != null and not t.is_tow and t.color == c:
			n -= t.available()
	return n


static func _closest_locked(s: GameState, qs: Array) -> int:
	var g := s.grid
	var depth := {}
	for i in g.color.size():
		var c := g.color[i]
		if c != GarageGrid.ASPHALT and g.gate_dist[i] < int(depth.get(c, 1 << 30)):
			depth[c] = g.gate_dist[i]
	var best := -1
	var best_d := 1 << 30
	for q in qs:
		var t: Trailer = s.queues[q][0]
		if t.is_tow:
			continue
		var d := int(depth.get(t.color, 1 << 30))
		if d < best_d:
			best = q
			best_d = d
	return best


static func _tappable(s: GameState) -> Array:
	var out := []
	for q in s.queues.size():
		if not s.queues[q].is_empty():
			out.append(q)
	return out
