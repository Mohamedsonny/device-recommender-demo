## Garage seen from above: flat byte arrays, never one Node per car.
## Freedom bookkeeping lives in Freedom; this class only stores and mutates cells.
class_name GarageGrid
extends RefCounted

const ASPHALT := 255

var w: int
var h: int
var color: PackedByteArray       # car color per cell, or ASPHALT
var reserved: PackedByteArray    # 1 = this car has been called and is about to drive
var free: PackedByteArray        # 1 = this car has a clear path to the gate
var connected: PackedByteArray   # 1 = asphalt reachable from the gate
var on_gate: PackedByteArray     # 1 = cell lies on a gate row/column
var gate_dist: PackedInt32Array  # cells to the nearest gate edge
var remaining_by_color: Dictionary = {}  # color -> int
var remaining_total := 0

# Free, unreserved cars per color, in the order they became free.
# A car only leaves this list by being reserved, so a queue with a head index is enough.
var _queue: Dictionary = {}  # color -> Array[int]
var _head: Dictionary = {}   # color -> int


func setup(width: int, height: int, cells: PackedByteArray, gates: Array) -> void:
	w = width
	h = height
	var n := w * h
	color = cells.duplicate()
	reserved = _zeros(n)
	free = _zeros(n)
	connected = _zeros(n)
	on_gate = _zeros(n)
	gate_dist = PackedInt32Array()
	gate_dist.resize(n)
	remaining_by_color = {}
	remaining_total = 0
	_queue = {}
	_head = {}
	for i in n:
		var x := i % w
		@warning_ignore("integer_division")
		var y := i / w
		var d := 1 << 30
		for g in gates:
			match g:
				"bottom": d = mini(d, h - 1 - y)
				"top": d = mini(d, y)
				"left": d = mini(d, x)
				"right": d = mini(d, w - 1 - x)
		gate_dist[i] = d
		on_gate[i] = 1 if d == 0 else 0
		var c := color[i]
		if c != ASPHALT:
			remaining_by_color[c] = int(remaining_by_color.get(c, 0)) + 1
			remaining_total += 1
			if not _queue.has(c):
				_queue[c] = []
				_head[c] = 0


func idx(x: int, y: int) -> int:
	return y * w + x


func set_free(cell: int) -> void:
	free[cell] = 1
	_queue[color[cell]].append(cell)


func has_free(c: int) -> bool:
	return _queue.has(c) and _head[c] < _queue[c].size()


func free_count(c: int) -> int:
	return _queue[c].size() - _head[c] if _queue.has(c) else 0


## Reserves and returns the car of color c that has been free the longest, or -1.
func call_car(c: int) -> int:
	if not has_free(c):
		return -1
	var cell: int = _queue[c][_head[c]]
	_head[c] += 1
	assert(color[cell] == c and reserved[cell] == 0 and free[cell] == 1)
	reserved[cell] = 1
	return cell


## Clears the cell of a car that has driven out. The caller must update freedom afterwards.
func remove_car(cell: int) -> int:
	var c := color[cell]
	assert(c != ASPHALT and reserved[cell] == 1)
	color[cell] = ASPHALT
	reserved[cell] = 0
	free[cell] = 0
	remaining_by_color[c] -= 1
	remaining_total -= 1
	return c


func colors() -> Array:
	var out := remaining_by_color.keys()
	out.sort()
	return out


static func _zeros(n: int) -> PackedByteArray:
	var a := PackedByteArray()
	a.resize(n)
	a.fill(0)
	return a
