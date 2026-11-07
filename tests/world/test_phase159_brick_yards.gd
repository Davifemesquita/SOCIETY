extends GdUnitTestSuite
## Tijolos secando (Fase 159): cada olaria ganha o pátio em três células em fila encostadas no meio de um lado, livres, ao
## longo da parede; com o lado ocupado, vai para o próximo; o recheio deixa as células limpas; o pátio cabe nas três células e
## é baixo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func test_the_yard_lines_up_along_a_free_side() -> void:
	var id := SimFixture.place(_sim, &"brickworks", Vector2i(20, 10), 0)
	var found := BrickYardView.sites(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_bool(found.has(id)).is_true()
	var site: Array = found[id]
	var middle: Vector2i = site[0]
	var side: Vector2i = site[1]
	var record := _sim.world.building(id)
	var area := Footprint.rect(record.origin, _sim.data.building(&"brickworks").size, record.rotation)
	var along := Vector2i(side.y, side.x)
	for cell: Vector2i in [middle - along, middle, middle + along]:
		assert_bool(area.has_point(cell)).is_false()
		# encostada na olaria pelo lado
		assert_bool(area.has_point(cell - side)).is_true()
	var cells := BrickYardView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_int(cells.size()).is_equal(3)
	assert_int(cells[middle]).is_equal(id)


func test_a_busy_side_sends_the_yard_to_the_next_one() -> void:
	var id := SimFixture.place(_sim, &"brickworks", Vector2i(20, 10), 0)
	var first: Array = BrickYardView.sites(_sim.world, _sim.data, SimFixture.ISLAND)[id]
	var middle: Vector2i = first[0]
	var side: Vector2i = first[1]
	SimFixture.road(_sim, middle - Vector2i(side.y, side.x) * 2, middle + Vector2i(side.y, side.x) * 2)
	var second: Array = BrickYardView.sites(_sim.world, _sim.data, SimFixture.ISLAND)[id]
	var other: Vector2i = second[1]
	assert_bool(other == side).is_false()


func test_the_scatter_keeps_the_yard_clean() -> void:
	SimFixture.place(_sim, &"brickworks", Vector2i(20, 10), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, SimFixture.ISLAND)
	var doors: Dictionary[Vector2i, bool] = context[0]
	for cell: Vector2i in BrickYardView.cells(_sim.world, _sim.data, SimFixture.ISLAND):
		assert_bool(doors.has(cell)).is_true()


func test_the_yard_fits_its_three_cells_and_stays_low() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	BrickYardView.yard_mesh(tool, Transform3D.IDENTITY)
	tool.generate_normals()
	var box := tool.commit().get_aabb()
	var cell := _sim.config.cell_size_m
	assert_float(box.position.x).is_greater(-cell * 1.5)
	assert_float(box.end.x).is_less(cell * 1.5)
	assert_float(box.position.z).is_greater(-cell * 0.5)
	assert_float(box.end.z).is_less(cell * 0.5)
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(1.1)


func test_the_view_draws_one_yard_per_brickworks() -> void:
	SimFixture.place(_sim, &"brickworks", Vector2i(20, 10), 0)
	SimFixture.place(_sim, &"brickworks", Vector2i(40, 10), 1)
	var view: BrickYardView = auto_free(BrickYardView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.yard_count()).is_equal(2)


func test_the_yard_keeps_off_the_furnace_side() -> void:
	# a boca do forno da Fase 137 fica no lado de +X da frente: com os outros livres, o pátio não vai para ele
	for rotation: int in 4:
		var id := SimFixture.place(_sim, &"brickworks", Vector2i(10 + rotation * 16, 10), rotation)
		var site: Array = BrickYardView.sites(_sim.world, _sim.data, SimFixture.ISLAND)[id]
		var side: Vector2i = site[1]
		var front := Footprint.front_direction(rotation)
		assert_bool(side == Vector2i(-front.y, front.x)).is_false()
