## A tray box: a color and the number of pixels its ants will eat.
class_name Box
extends RefCounted

enum State { IN_TRAY, IN_SLOT, DONE }

var id: int
var color: int
var count: int       # pixels still to be eaten (decremented when an ant arrives)
var hidden: bool     # "?" box; revealed when it reaches the top of its column
var state := State.IN_TRAY
var inflight := 0    # ants dispatched and not yet arrived
var slot := -1


static func make(box_id: int, box_color: int, box_count: int, is_hidden := false) -> Box:
	var b := Box.new()
	b.id = box_id
	b.color = box_color
	b.count = box_count
	b.hidden = is_hidden
	return b
