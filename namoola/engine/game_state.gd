## Full state of one attempt at a level. Pure data plus small queries.
class_name GameState
extends RefCounted

enum Phase { READY, RUNNING, WON, LOST }

var board: BoardState
var boxes: Array = []   # Box, indexed by id
var tray: Array = []    # columns; each an Array of Box with index 0 = top (the tappable one)
var slots: Array = []   # Box or null
var tasks: Array = []   # AntTask in dispatch order
var level_rev := 0
var phase := Phase.READY
var tick := 0           # ticks completed in this attempt
var ants_per_tick := 3
var travel_base_ticks := 4
var travel_rows_per_tick := 2
var next_task_id := 0
var events: Array = []  # filled during a step, read by the view


func free_slot() -> int:
	return slots.find(null)


func tray_empty() -> bool:
	for col in tray:
		if not col.is_empty():
			return false
	return true


func travel_ticks(cell: int) -> int:
	@warning_ignore("integer_division")
	return travel_base_ticks + board.entry_dist[cell] / maxi(1, travel_rows_per_tick)


func emit(type: String, data := {}) -> void:
	var e := data.duplicate()
	e["type"] = type
	e["rev"] = level_rev
	e["tick"] = tick
	events.append(e)
