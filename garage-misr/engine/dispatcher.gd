## Trailers in bays call free cars of their color; the tow truck calls any free car.
class_name Dispatcher
extends RefCounted


## Bays are served left to right. A trailer never has more than number - inflight cars on
## the way, and each car is reserved when called, so no car loads onto two trailers.
static func dispatch(s: GameState) -> void:
	for t in s.bays:
		if t == null:
			continue
		var budget := mini(s.cars_per_tick, t.count - t.inflight)
		while budget > 0:
			if not (_call_tow(s, t) if t.is_tow else _call(s, t, t, t.color)):
				break
			budget -= 1


static func _call(s: GameState, trailer: Trailer, charge: Trailer, c: int) -> bool:
	var cell := s.grid.call_car(c)
	if cell < 0:
		return false
	var task := CarTask.make(s.next_task_id, trailer.id, charge.id, cell, c, s.level_rev,
		s.travel_ticks(cell))
	s.next_task_id += 1
	s.tasks.append(task)
	trailer.inflight += 1
	if charge != trailer:
		charge.inflight += 1
	s.emit("car_called", {"car": task.id, "trailer": trailer.id, "charge": charge.id,
		"bay": trailer.bay, "cell": cell, "color": c, "ticks": task.ticks_left,
		"towed": trailer.is_tow})
	return true


## The tow truck takes one free car. Each towed car is charged to the colored trailer with
## the most cars still to call (count - inflight) of that color, so the balance invariant
## holds. Such a trailer always exists while an unreserved car of that color remains.
static func _call_tow(s: GameState, tow: Trailer) -> bool:
	var c := pick_tow_color(s)
	if c < 0:
		return false
	var charge := largest_trailer(s, c)
	assert(charge != null)
	return _call(s, tow, charge, c)


## Prefers colors no bay trailer is calling right now (the ones that are stuck), then the
## color with the most free cars, then the lowest color index.
static func pick_tow_color(s: GameState) -> int:
	var wanted := {}
	for t in s.bays:
		if t != null and not t.is_tow and t.available() > 0:
			wanted[t.color] = true
	var best := -1
	var best_score := -1
	for c in s.grid.colors():
		var n := s.grid.free_count(c)
		if n == 0:
			continue
		var score := n + (0 if wanted.has(c) else 1 << 20)
		if score > best_score:
			best = c
			best_score = score
	return best


static func largest_trailer(s: GameState, c: int) -> Trailer:
	var best: Trailer = null
	for t in s.trailers:
		if t.is_tow or t.color != c or t.state == Trailer.State.DONE or t.available() <= 0:
			continue
		if best == null or t.available() > best.available():
			best = t
	return best
