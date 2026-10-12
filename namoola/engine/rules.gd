## Game rules from docs/RULES.md, one static function per tick stage.
class_name Rules
extends RefCounted


## Moves the top box of a column into the leftmost free slot. Returns false (and emits
## tap_rejected) if the game is over, the column is empty, or every slot is full.
static func apply_tap(s: GameState, col: int) -> bool:
	if s.phase != GameState.Phase.RUNNING:
		s.emit("tap_rejected", {"col": col, "reason": "not_running"})
		return false
	if col < 0 or col >= s.tray.size() or s.tray[col].is_empty():
		s.emit("tap_rejected", {"col": col, "reason": "empty_column"})
		return false
	var slot := s.free_slot()
	if slot < 0:
		s.emit("tap_rejected", {"col": col, "reason": "slots_full"})
		return false
	var box: Box = s.tray[col].pop_front()
	box.state = Box.State.IN_SLOT
	box.slot = slot
	box.hidden = false
	s.slots[slot] = box
	s.emit("box_to_slot", {"box": box.id, "col": col, "slot": slot})
	if not s.tray[col].is_empty() and s.tray[col][0].hidden:
		s.tray[col][0].hidden = false
		s.emit("box_revealed", {"box": s.tray[col][0].id, "col": col})
	return true


## Advances every ant one tick; ants that arrive eat their pixel.
static func resolve_arrivals(s: GameState) -> void:
	var still: Array = []
	for t in s.tasks:
		if t.level_rev != s.level_rev:
			continue  # stale ant from an earlier attempt
		t.ticks_left -= 1
		if t.ticks_left > 0:
			still.append(t)
			continue
		var box: Box = s.boxes[t.box_id]
		var c := s.board.remove_pixel(t.cell)
		assert(c == box.color)
		Exposure.on_removed(s.board, t.cell)
		box.count -= 1
		box.inflight -= 1
		s.emit("pixel_eaten", {"ant": t.id, "box": box.id, "cell": t.cell, "color": c,
			"count": box.count})
	s.tasks = still


## Boxes that reached zero leave their slot.
static func free_done_boxes(s: GameState) -> void:
	for i in s.slots.size():
		var box = s.slots[i]
		if box != null and box.count == 0 and box.inflight == 0:
			box.state = Box.State.DONE
			box.slot = -1
			s.slots[i] = null
			s.emit("box_done", {"box": box.id, "slot": i})


static func is_won(s: GameState) -> bool:
	return s.board.remaining_total == 0


## The only way to lose: every slot full, no ant in flight, and no slotted box has an
## exposed pixel of its color. No timers.
static func is_lost(s: GameState) -> bool:
	if s.slots.has(null):
		return false
	for box in s.slots:
		if s.board.has_exposed(box.color):
			return false
	return true


static func evaluate(s: GameState) -> void:
	if is_won(s):
		s.phase = GameState.Phase.WON
		s.emit("won")
	elif is_lost(s):
		s.phase = GameState.Phase.LOST
		s.emit("lost")


## Per color: remaining pixels == sum of counts of boxes not yet done.
static func balance_ok(s: GameState) -> bool:
	var by_color := {}
	for box in s.boxes:
		if box.state != Box.State.DONE:
			by_color[box.color] = int(by_color.get(box.color, 0)) + box.count
	for c in s.board.remaining_by_color:
		if int(s.board.remaining_by_color[c]) != int(by_color.get(c, 0)):
			return false
		by_color.erase(c)
	for c in by_color:
		if by_color[c] != 0:
			return false
	return true
