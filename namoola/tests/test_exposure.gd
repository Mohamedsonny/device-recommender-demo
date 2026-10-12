extends GutTest

const H := preload("res://tests/helpers.gd")


func _board(rows: Array, entry := ["bottom"]) -> BoardState:
	var lv := {"w": rows[0].length(), "h": rows.size(), "rows": rows}
	var b := BoardState.new()
	b.setup(lv["w"], lv["h"], LevelData.cells(lv), entry)
	Exposure.build(b)
	return b


func _exposed_cells(b: BoardState) -> Array:
	var out := []
	for i in b.exposed.size():
		if b.exposed[i] == 1:
			out.append(i)
	return out


func test_only_entry_edge_exposed_on_full_board():
	var b := _board(["000", "111", "222"])
	assert_eq(_exposed_cells(b), [6, 7, 8])
	assert_true(b.has_exposed(2))
	assert_false(b.has_exposed(0))
	assert_false(b.has_exposed(1))


func test_empty_entry_cells_expose_their_neighbours():
	# bottom-middle is empty and on the entry edge -> (1,1), (0,2), (2,2) exposed
	var b := _board(["000", "111", "2.2"])
	assert_eq(_exposed_cells(b), [4, 6, 8])


func test_enclosed_cavity_opens_when_wall_is_eaten():
	var b := _board(["111", "1.1", "111"])
	assert_eq(_exposed_cells(b), [6, 7, 8])
	assert_eq(b.connected[4], 0, "cavity not reachable yet")
	assert_eq(b.take_exposed(1), 6)
	assert_eq(b.take_exposed(1), 7)
	b.remove_pixel(7)
	Exposure.on_removed(b, 7)
	assert_eq(b.connected[4], 1, "cavity now connected")
	# (0,1), (2,1) and (1,0) are next to the cavity; diagonals are not exposed by it
	assert_eq(_exposed_cells(b), [1, 3, 5, 6, 8])


func test_take_exposed_reserves_once():
	var b := _board(["11"])
	var a := b.take_exposed(1)
	var c := b.take_exposed(1)
	assert_ne(a, c)
	assert_eq(b.take_exposed(1), -1)
	assert_eq(b.reserved[a], 1)
	assert_eq(b.reserved[c], 1)


func test_all_edges_entry():
	var b := _board(["111", "121", "111"], ["bottom", "top", "left", "right"])
	assert_eq(_exposed_cells(b), [0, 1, 2, 3, 5, 6, 7, 8])
	assert_false(b.has_exposed(2))


func test_fixture_initial_exposure():
	var e := H.engine_for(H.fixture())
	var b := e.state.board
	# bottom row is color 0 and fully exposed; nothing above it is reachable yet
	assert_eq(_exposed_cells(b), [30, 31, 32, 33, 34, 35])
	assert_eq(b.remaining_by_color, {0: 14, 1: 12, 2: 10})
