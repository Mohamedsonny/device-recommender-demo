extends GutTest

const H := preload("res://tests/helpers.gd")


func _grid(rows: Array, gates := ["bottom"]) -> GarageGrid:
	var lv := {"w": rows[0].length(), "h": rows.size(), "rows": rows}
	var g := GarageGrid.new()
	g.setup(lv["w"], lv["h"], LevelData.cells(lv), gates)
	Freedom.build(g)
	return g


func _free_cells(g: GarageGrid) -> Array:
	var out := []
	for i in g.free.size():
		if g.free[i] == 1:
			out.append(i)
	return out


func _drive_out(g: GarageGrid, cell: int) -> void:
	g.remove_car(cell)
	Freedom.on_car_left(g, cell)


func test_only_gate_row_free_in_full_garage():
	var g := _grid(["000", "111", "222"])
	assert_eq(_free_cells(g), [6, 7, 8])
	assert_true(g.has_free(2))
	assert_false(g.has_free(0))
	assert_false(g.has_free(1))


func test_asphalt_on_gate_row_frees_its_neighbours():
	var g := _grid(["000", "111", "2.2"])
	assert_eq(_free_cells(g), [4, 6, 8])


func test_enclosed_lot_opens_when_blocking_car_leaves():
	var g := _grid(["111", "1.1", "111"])
	assert_eq(_free_cells(g), [6, 7, 8])
	assert_eq(g.connected[4], 0, "inner lot not reachable yet")
	assert_eq(g.call_car(1), 6)
	assert_eq(g.call_car(1), 7)
	_drive_out(g, 7)
	assert_eq(g.connected[4], 1, "inner lot now connected")
	# (0,1), (2,1) and (1,0) touch the lot; diagonals are not freed by it
	assert_eq(_free_cells(g), [1, 3, 5, 6, 8])


func test_called_car_is_reserved_once():
	var g := _grid(["11"])
	var a := g.call_car(1)
	var b := g.call_car(1)
	assert_ne(a, b)
	assert_eq(g.call_car(1), -1)
	assert_eq(g.reserved[a], 1)
	assert_eq(g.reserved[b], 1)


func test_cars_free_in_the_order_they_were_unlocked():
	var g := _grid(["1", "1", "1"])
	var order := []
	for i in 3:
		var cell := g.call_car(1)
		order.append(cell)
		_drive_out(g, cell)
	assert_eq(order, [2, 1, 0], "nearest to the gate first")


func test_gates_on_all_edges():
	var g := _grid(["111", "121", "111"], ["bottom", "top", "left", "right"])
	assert_eq(_free_cells(g), [0, 1, 2, 3, 5, 6, 7, 8])
	assert_false(g.has_free(2))


func test_two_gates():
	var g := _grid(["000", "111", "222"], ["bottom", "top"])
	assert_eq(_free_cells(g), [0, 1, 2, 6, 7, 8])


func test_fixture_initial_freedom():
	var e := H.engine_for(H.fixture())
	var g := e.state.grid
	# the gate row is color 0 and all free; nothing behind it can get out yet
	assert_eq(_free_cells(g), [30, 31, 32, 33, 34, 35])
	assert_eq(g.remaining_by_color, {0: 14, 1: 12, 2: 10})
