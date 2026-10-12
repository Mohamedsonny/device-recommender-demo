## Draws the garage from engine events. One MultiMesh holds every parking cell and a second
## one the driving cars (capped at MAX_DRIVING), so there is never a Node per car.
class_name GarageView
extends Node2D

const CELL := 24.0
const CAR_SIZE := Vector2(20.0, 20.0)
const MAX_DRIVING := 150
const ASPHALT := Color("#3b3d40")

var engine: GameEngine
var palette: Array[Color] = []

var _cells: MultiMeshInstance2D
var _driving: MultiMeshInstance2D
# Cell colors mirrored on the CPU: the source for the MultiMesh, readable by tests (headless
# Godot has no renderer to read MultiMesh data back from).
var _colors := PackedColorArray()
var _cars: Dictionary = {}  # car task id -> {"from", "to", "start", "ticks", "color"}


func setup(e: GameEngine, colors: Array) -> void:
	engine = e
	palette.clear()
	for c in colors:
		palette.append(Color(c))
	if _cells == null:
		_cells = _make_layer(Vector2(CELL, CELL) * 0.96)
		_driving = _make_layer(CAR_SIZE)
	rebuild()


func rebuild() -> void:
	var g := engine.state.grid
	var mm := _cells.multimesh
	mm.instance_count = g.w * g.h
	_colors.resize(g.w * g.h)
	for i in g.w * g.h:
		mm.set_instance_transform_2d(i, Transform2D(0.0, _cell_pos(i)))
		_paint(i)
	_cars.clear()
	_driving.multimesh.instance_count = MAX_DRIVING
	_driving.multimesh.visible_instance_count = 0


## Apply what one or more engine steps produced. Call with the result of step()/advance().
func apply_events(events: Array) -> void:
	for ev in events:
		if ev["rev"] != engine.state.level_rev:
			continue
		match ev["type"]:
			"car_called":
				_paint_color(ev["cell"], ASPHALT)
				_cars[ev["car"]] = {"from": _cell_pos(ev["cell"]), "to": _gate_pos(ev["cell"]),
					"start": ev["tick"], "ticks": float(ev["ticks"]), "color": _color(ev["color"])}
			"car_loaded":
				_cars.erase(ev["car"])
			"restarted":
				rebuild()
	_draw_driving(0.0)


func _process(_delta: float) -> void:
	_draw_driving(engine.tick_alpha() if engine != null else 0.0)


func cell_color(i: int) -> Color:
	return _colors[i]


func driving_visible() -> int:
	return _driving.multimesh.visible_instance_count


## Draws up to MAX_DRIVING cars, interpolating alpha (0..1) into the current tick. Cars
## beyond the cap still exist in the engine; they are simply not drawn.
func _draw_driving(alpha: float) -> void:
	var mm := _driving.multimesh
	var n := 0
	for id in _cars:
		if n >= MAX_DRIVING:
			break
		var car: Dictionary = _cars[id]
		var t: float = (engine.state.tick - car["start"] + alpha) / car["ticks"]
		mm.set_instance_transform_2d(n, Transform2D(0.0, car["from"].lerp(car["to"], clampf(t, 0.0, 1.0))))
		mm.set_instance_color(n, car["color"])
		n += 1
	mm.visible_instance_count = n


func _make_layer(size: Vector2) -> MultiMeshInstance2D:
	var quad := QuadMesh.new()
	quad.size = size
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = quad
	var layer := MultiMeshInstance2D.new()
	layer.multimesh = mm
	add_child(layer)
	return layer


func _paint(i: int) -> void:
	var c := engine.state.grid.color[i]
	_paint_color(i, ASPHALT if c == GarageGrid.ASPHALT else _color(c))


func _paint_color(i: int, col: Color) -> void:
	_colors[i] = col
	_cells.multimesh.set_instance_color(i, col)


func _color(c: int) -> Color:
	return palette[c] if c < palette.size() else Color.from_hsv(c / 9.0, 0.6, 0.9)


func _cell_pos(i: int) -> Vector2:
	var w := engine.state.grid.w
	@warning_ignore("integer_division")
	return Vector2(i % w + 0.5, i / w + 0.5) * CELL


## Where a car leaves the garage: straight out through the nearest gate edge.
func _gate_pos(i: int) -> Vector2:
	var g := engine.state.grid
	var p := _cell_pos(i)
	var best := Vector2.INF
	for gate in LevelData.gates(engine.level):
		var q: Vector2
		match gate:
			"bottom": q = Vector2(p.x, (g.h + 0.5) * CELL)
			"top": q = Vector2(p.x, -0.5 * CELL)
			"left": q = Vector2(-0.5 * CELL, p.y)
			_: q = Vector2((g.w + 0.5) * CELL, p.y)
		if p.distance_squared_to(q) < p.distance_squared_to(best):
			best = q
	return best
