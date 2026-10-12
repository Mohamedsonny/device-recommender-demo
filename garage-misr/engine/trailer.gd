## A car-carrier trailer (تريلا): a color and the number of cars it will carry.
## A tow truck (ونش) is a trailer with is_tow = true and color = TOW_COLOR.
class_name Trailer
extends RefCounted

enum State { IN_QUEUE, IN_BAY, DONE }

const TOW_COLOR := -1

var id: int
var color: int
var count: int       # cars still to load (drops by 1 when a car arrives)
var hidden: bool     # tarp "?" trailer; revealed when it reaches the front of its queue
var is_tow := false
var state := State.IN_QUEUE
var inflight := 0    # cars called for (or, for a colored trailer, charged by the tow truck)
var bay := -1


func available() -> int:
	return count - inflight


static func make(trailer_id: int, trailer_color: int, number: int, is_hidden := false) -> Trailer:
	var t := Trailer.new()
	t.id = trailer_id
	t.color = trailer_color
	t.count = number
	t.hidden = is_hidden
	return t


static func make_tow(trailer_id: int, number: int, is_hidden := false) -> Trailer:
	var t := make(trailer_id, TOW_COLOR, number, is_hidden)
	t.is_tow = true
	return t
