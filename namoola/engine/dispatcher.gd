## Sends ants from slotted boxes to exposed pixels of their color.
class_name Dispatcher
extends RefCounted


## Slots are served left to right. A box never has more than count - inflight ants out,
## and each pixel is reserved when its ant is dispatched, so no pixel is eaten twice.
static func dispatch(s: GameState) -> void:
	for box in s.slots:
		if box == null:
			continue
		var budget := mini(s.ants_per_tick, box.count - box.inflight)
		while budget > 0:
			var cell := s.board.take_exposed(box.color)
			if cell < 0:
				break
			var t := AntTask.make(s.next_task_id, box.id, cell, s.level_rev, s.travel_ticks(cell))
			s.next_task_id += 1
			s.tasks.append(t)
			box.inflight += 1
			s.emit("ant_dispatched", {"ant": t.id, "box": box.id, "slot": box.slot,
				"cell": cell, "ticks": t.ticks_left})
			budget -= 1
