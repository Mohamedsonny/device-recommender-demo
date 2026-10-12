## Which pixels ants can reach. One BFS at load, then a small flood per removed pixel,
## so the cost of an update is proportional to the area that changed.
class_name Exposure
extends RefCounted


## A pixel is exposed if it lies on an entry edge, or is a 4-neighbour of an empty
## cell connected to the entry.
static func build(b: BoardState) -> void:
	var frontier: Array[int] = []
	for i in b.w * b.h:
		if b.on_entry[i] == 0:
			continue
		if b.color[i] == BoardState.EMPTY:
			b.connected[i] = 1
			frontier.append(i)
		else:
			b.expose(i)
	_flood(b, frontier)


## Called after b.remove_pixel(cell). The cell was exposed, so it is now connected
## empty space; flood into any cavity it opens and expose the pixels around it.
static func on_removed(b: BoardState, cell: int) -> void:
	b.connected[cell] = 1
	var frontier: Array[int] = [cell]
	_flood(b, frontier)


static func _flood(b: BoardState, frontier: Array[int]) -> void:
	var head := 0
	while head < frontier.size():
		var i := frontier[head]
		head += 1
		var x := i % b.w
		@warning_ignore("integer_division")
		var y := i / b.w
		# Fixed neighbour order (up, down, left, right) keeps exposure order deterministic.
		if y > 0: _visit(b, i - b.w, frontier)
		if y < b.h - 1: _visit(b, i + b.w, frontier)
		if x > 0: _visit(b, i - 1, frontier)
		if x < b.w - 1: _visit(b, i + 1, frontier)


static func _visit(b: BoardState, n: int, frontier: Array[int]) -> void:
	if b.color[n] == BoardState.EMPTY:
		if b.connected[n] == 0:
			b.connected[n] = 1
			frontier.append(n)
	elif b.exposed[n] == 0:
		b.expose(n)
