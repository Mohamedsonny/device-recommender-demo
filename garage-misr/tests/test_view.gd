extends GutTest

const H := preload("res://tests/helpers.gd")


func _view_for(e: GameEngine, palette: Array) -> GarageView:
	var v := GarageView.new()
	add_child_autofree(v)
	v.setup(e, palette)
	return v


## A 32x40 garage (the largest grid), 9 colors, with an aisle at x=0 and an empty lane on
## every other row, so hundreds of cars are free at once.
func _big_level() -> Dictionary:
	var rows := []
	var counts := {}
	for y in 40:
		if y % 2 == 1:
			rows.append(".".repeat(32))
			continue
		var c := (y / 2) % 9
		rows.append("." + str(c).repeat(31))
		counts[c] = int(counts.get(c, 0)) + 31
	var queues := [[], [], [], [], []]
	for c in counts:
		queues[c % 5].append({"c": c, "n": counts[c]})
	return {"w": 32, "h": 40, "rows": rows, "queues": queues, "bays": 5, "cars_per_tick": 3}


func test_whole_garage_is_one_multimesh_not_a_node_per_car():
	var e := H.engine_for(H.fixture())
	var v := _view_for(e, H.fixture()["palette"])
	assert_eq(v.get_child_count(), 2, "parking layer + driving layer only")
	var layer: MultiMeshInstance2D = v.get_child(0)
	assert_eq(layer.multimesh.instance_count, 36)
	assert_eq(v.cell_color(30), Color("#C8A165"))
	assert_eq(v.cell_color(7), Color("#2BA39B"))


func test_view_follows_engine_events():
	var e := H.engine_for(H.fixture())
	var v := _view_for(e, H.fixture()["palette"])
	e.push_command({"type": "tap", "queue": 0})
	v.apply_events(e.step())
	assert_eq(v.driving_visible(), 3, "three cars called")
	var asphalt := 0
	for i in 36:
		if v.cell_color(i) == GarageView.ASPHALT:
			asphalt += 1
	assert_eq(asphalt, 3, "called cars left their parking cells")
	for i in 20:
		v.apply_events(e.step())
	assert_eq(v.driving_visible(), e.state.tasks.size())


func test_driving_cars_capped_at_150_on_the_largest_grid():
	var e := H.engine_for(_big_level())
	var v := _view_for(e, [])
	var peak_engine := 0
	var peak_view := 0
	for q in 5:
		e.push_command({"type": "tap", "queue": q})
	for i in 400:
		v.apply_events(e.step())
		peak_engine = maxi(peak_engine, e.state.tasks.size())
		peak_view = maxi(peak_view, v.driving_visible())
		assert_true(Rules.balance_ok(e.state))
	assert_gt(peak_engine, GarageView.MAX_DRIVING, "the engine really exceeds the cap")
	assert_eq(peak_view, GarageView.MAX_DRIVING, "view draws at most the cap")
	assert_eq(v.get_child_count(), 2)
	gut.p("32x40: peak cars driving in engine %d, drawn %d" % [peak_engine, peak_view])


func test_restart_rebuilds_the_view():
	var e := H.engine_for(H.fixture())
	var v := _view_for(e, H.fixture()["palette"])
	e.push_command({"type": "tap", "queue": 0})
	v.apply_events(e.step())
	e.push_command({"type": "restart"})
	v.apply_events(e.step())
	assert_eq(v.driving_visible(), 0)
	assert_eq(v.cell_color(30), Color("#C8A165"))
