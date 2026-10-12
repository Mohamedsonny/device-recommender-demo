## Which cars can drive out. One BFS from the gate at load, then a small flood per car
## that leaves, so an update costs only the area that changed.
class_name Freedom
extends RefCounted


## A car is free if it is on a gate edge, or 4-neighbour to asphalt connected to the gate.
static func build(g: GarageGrid) -> void:
	var frontier: Array[int] = []
	for i in g.w * g.h:
		if g.on_gate[i] == 0:
			continue
		if g.color[i] == GarageGrid.ASPHALT:
			g.connected[i] = 1
			frontier.append(i)
		else:
			g.set_free(i)
	_flood(g, frontier)


## Called after g.remove_car(cell). The car was free, so its cell is now connected
## asphalt; flood into any enclosed lot it opens and free the cars around it.
static func on_car_left(g: GarageGrid, cell: int) -> void:
	g.connected[cell] = 1
	var frontier: Array[int] = [cell]
	_flood(g, frontier)


static func _flood(g: GarageGrid, frontier: Array[int]) -> void:
	var head := 0
	while head < frontier.size():
		var i := frontier[head]
		head += 1
		var x := i % g.w
		@warning_ignore("integer_division")
		var y := i / g.w
		# Fixed neighbour order (up, down, left, right) keeps freedom order deterministic.
		if y > 0: _visit(g, i - g.w, frontier)
		if y < g.h - 1: _visit(g, i + g.w, frontier)
		if x > 0: _visit(g, i - 1, frontier)
		if x < g.w - 1: _visit(g, i + 1, frontier)


static func _visit(g: GarageGrid, n: int, frontier: Array[int]) -> void:
	if g.color[n] == GarageGrid.ASPHALT:
		if g.connected[n] == 0:
			g.connected[n] = 1
			frontier.append(n)
	elif g.free[n] == 0:
		g.set_free(n)
