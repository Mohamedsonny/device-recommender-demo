## Game rules from docs/RULES.md, one static function per tick stage.
class_name Rules
extends RefCounted


## Moves the front trailer of a queue into the leftmost free bay. Returns false (and emits
## tap_rejected) if the game is over, the queue is empty, or every bay is full.
static func apply_tap(s: GameState, q: int) -> bool:
	if s.phase != GameState.Phase.RUNNING:
		s.emit("tap_rejected", {"queue": q, "reason": "not_running"})
		return false
	if q < 0 or q >= s.queues.size() or s.queues[q].is_empty():
		s.emit("tap_rejected", {"queue": q, "reason": "empty_queue"})
		return false
	var bay := s.free_bay()
	if bay < 0:
		s.emit("tap_rejected", {"queue": q, "reason": "bays_full"})
		return false
	var t: Trailer = s.queues[q].pop_front()
	t.state = Trailer.State.IN_BAY
	t.bay = bay
	t.hidden = false
	s.bays[bay] = t
	s.emit("trailer_to_bay", {"trailer": t.id, "queue": q, "bay": bay})
	_reveal_front(s, q)
	return true


## Advances every driving car one tick; cars that reach the gate load onto their trailer.
static func resolve_arrivals(s: GameState) -> void:
	var still: Array = []
	for task in s.tasks:
		if task.level_rev != s.level_rev:
			continue  # stale car from an earlier attempt
		task.ticks_left -= 1
		if task.ticks_left > 0:
			still.append(task)
			continue
		var c := s.grid.remove_car(task.cell)
		assert(c == task.color)
		Freedom.on_car_left(s.grid, task.cell)
		var charge: Trailer = s.trailers[task.charge_id]
		charge.count -= 1
		charge.inflight -= 1
		if task.trailer_id != task.charge_id:
			var tow: Trailer = s.trailers[task.trailer_id]
			tow.count -= 1
			tow.inflight -= 1
		s.emit("car_loaded", {"car": task.id, "trailer": task.trailer_id,
			"charge": task.charge_id, "cell": task.cell, "color": c,
			"count": s.trailers[task.trailer_id].count})
	s.tasks = still


## Trailers that reached zero leave: from a bay (honk, bay frees) or, if the tow truck
## used up a queued trailer's whole number, straight out of its queue.
static func remove_finished(s: GameState) -> void:
	for i in s.bays.size():
		var t = s.bays[i]
		if t != null and t.count == 0 and t.inflight == 0:
			t.state = Trailer.State.DONE
			t.bay = -1
			s.bays[i] = null
			s.emit("trailer_left", {"trailer": t.id, "bay": i})
	for q in s.queues.size():
		var queue: Array = s.queues[q]
		var i := 0
		while i < queue.size():
			var t: Trailer = queue[i]
			if t.count == 0 and t.inflight == 0:
				t.state = Trailer.State.DONE
				queue.remove_at(i)
				s.emit("trailer_emptied", {"trailer": t.id, "queue": q})
				if i == 0:
					_reveal_front(s, q)
			else:
				i += 1


static func is_won(s: GameState) -> bool:
	return s.grid.remaining_total == 0


## The only way to lose: every bay full, no car driving, and no bay trailer has a free car
## of its color (the tow truck takes any color). No timers.
static func is_lost(s: GameState) -> bool:
	if s.bays.has(null):
		return false
	if not s.tasks.is_empty():
		return false
	for t in s.bays:
		if t.is_tow:
			if s.any_free_car():
				return false
		elif s.grid.has_free(t.color):
			return false
	return true


static func evaluate(s: GameState) -> void:
	if is_won(s):
		s.phase = GameState.Phase.WON
		s.emit("won")
	elif is_lost(s):
		s.phase = GameState.Phase.LOST
		s.emit("lost")


## Per color: remaining cars == sum of numbers of colored trailers not yet done.
static func balance_ok(s: GameState) -> bool:
	var by_color := {}
	for t in s.trailers:
		if not t.is_tow and t.state != Trailer.State.DONE:
			by_color[t.color] = int(by_color.get(t.color, 0)) + t.count
	for c in s.grid.remaining_by_color:
		if int(s.grid.remaining_by_color[c]) != int(by_color.get(c, 0)):
			return false
		by_color.erase(c)
	for c in by_color:
		if by_color[c] != 0:
			return false
	return true


static func _reveal_front(s: GameState, q: int) -> void:
	if not s.queues[q].is_empty() and s.queues[q][0].hidden:
		s.queues[q][0].hidden = false
		s.emit("trailer_revealed", {"trailer": s.queues[q][0].id, "queue": q})
