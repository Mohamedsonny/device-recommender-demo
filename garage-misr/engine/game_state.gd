## Full state of one attempt at a level. Pure data plus small queries.
class_name GameState
extends RefCounted

enum Phase { READY, RUNNING, WON, LOST }

var grid: GarageGrid
var trailers: Array = []  # Trailer, indexed by id
var queues: Array = []    # each an Array of Trailer, index 0 = front (the tappable one)
var bays: Array = []      # Trailer or null
var tasks: Array = []     # CarTask in call order
var level_rev := 0
var phase := Phase.READY
var tick := 0             # ticks completed in this attempt
var cars_per_tick := 3
var travel_base_ticks := 4
var travel_cells_per_tick := 2
var next_task_id := 0
var events: Array = []    # filled during a step, read by the view


func free_bay() -> int:
	return bays.find(null)


func queues_empty() -> bool:
	for q in queues:
		if not q.is_empty():
			return false
	return true


func travel_ticks(cell: int) -> int:
	@warning_ignore("integer_division")
	return travel_base_ticks + grid.gate_dist[cell] / maxi(1, travel_cells_per_tick)


## True if some free, unreserved car exists of any color.
func any_free_car() -> bool:
	for c in grid.remaining_by_color:
		if grid.has_free(c):
			return true
	return false


func emit(type: String, data := {}) -> void:
	var e := data.duplicate()
	e["type"] = type
	e["rev"] = level_rev
	e["tick"] = tick
	events.append(e)
