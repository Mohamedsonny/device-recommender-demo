## Board model: flat byte arrays, never one Node per pixel.
## Exposure bookkeeping lives in Exposure; this class only stores and mutates cells.
class_name BoardState
extends RefCounted

const EMPTY := 255

var w: int
var h: int
var color: PackedByteArray       # palette index per cell, or EMPTY
var reserved: PackedByteArray    # 1 = an ant is already heading to this pixel
var exposed: PackedByteArray     # 1 = ants can reach this pixel now
var connected: PackedByteArray   # 1 = empty cell reachable from the entry
var on_entry: PackedByteArray    # 1 = cell lies on an entry edge
var entry_dist: PackedInt32Array # rows/cols to the nearest entry edge
var remaining_by_color: Dictionary = {}  # color -> int
var remaining_total := 0

# Exposed, unreserved pixels per color, in the order they became exposed.
# A pixel only leaves this list by being reserved, so a queue with a head index is enough.
var _queue: Dictionary = {}  # color -> Array[int]
var _head: Dictionary = {}   # color -> int


func setup(width: int, height: int, cells: PackedByteArray, entries: Array) -> void:
	w = width
	h = height
	var n := w * h
	color = cells.duplicate()
	reserved = _zeros(n)
	exposed = _zeros(n)
	connected = _zeros(n)
	on_entry = _zeros(n)
	entry_dist = PackedInt32Array()
	entry_dist.resize(n)
	remaining_by_color = {}
	remaining_total = 0
	_queue = {}
	_head = {}
	for i in n:
		var x := i % w
		@warning_ignore("integer_division")
		var y := i / w
		var d := 1 << 30
		for e in entries:
			match e:
				"bottom": d = mini(d, h - 1 - y)
				"top": d = mini(d, y)
				"left": d = mini(d, x)
				"right": d = mini(d, w - 1 - x)
		entry_dist[i] = d
		on_entry[i] = 1 if d == 0 else 0
		var c := color[i]
		if c != EMPTY:
			remaining_by_color[c] = int(remaining_by_color.get(c, 0)) + 1
			remaining_total += 1
			if not _queue.has(c):
				_queue[c] = []
				_head[c] = 0


func idx(x: int, y: int) -> int:
	return y * w + x


func expose(cell: int) -> void:
	exposed[cell] = 1
	_queue[color[cell]].append(cell)


func has_exposed(c: int) -> bool:
	return _queue.has(c) and _head[c] < _queue[c].size()


## Reserves and returns the oldest exposed unreserved pixel of color c, or -1.
func take_exposed(c: int) -> int:
	if not has_exposed(c):
		return -1
	var cell: int = _queue[c][_head[c]]
	_head[c] += 1
	assert(color[cell] == c and reserved[cell] == 0 and exposed[cell] == 1)
	reserved[cell] = 1
	return cell


## Clears a pixel an ant has reached. The caller must update exposure afterwards.
func remove_pixel(cell: int) -> int:
	var c := color[cell]
	assert(c != EMPTY and reserved[cell] == 1)
	color[cell] = EMPTY
	reserved[cell] = 0
	exposed[cell] = 0
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
