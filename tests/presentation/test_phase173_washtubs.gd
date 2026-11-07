extends GdUnitTestSuite
## Tina de lavar (Fase 173): cada varal ganha a tina ao lado, na mesma célula de trás, mais para longe da casa; a tina é baixa e
## cabe com a tábua na metade da célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true


func test_every_clothesline_gets_its_washtub_beside_it() -> void:
	for i: int in 12:
		SimFixture.house(_sim, 2 + i * 4, 20, &"peasants" if i % 2 == 0 else &"workers", 5.0)
	var view: YardView = auto_free(YardView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.clothesline_count()).is_greater(0)
	assert_int(view.tub_count()).is_equal(view.clothesline_count())
	var grid := _sim.world.island(SimFixture.ISLAND)
	for building_id: int in _sim.world.building_ids():
		var record := _sim.world.building(building_id)
		if building_id % YardView.CLOTHESLINE_EVERY != YardView.CLOTHESLINE_REST:
			continue
		var spot: Variant = LampView.bonfire_spot(_sim, record)
		if not spot is Vector3:
			continue
		var point: Vector3 = spot
		var tub := YardView.tub_place(record, point)
		# na mesma célula do varal, mais para longe da casa que o meio dele
		assert_bool(grid.world_to_cell(tub.origin) == grid.world_to_cell(point)).is_true()
		var house := grid.rect_world(Footprint.rect(record.origin, Vector2i(3, 3), record.rotation))
		assert_float(Vector2(tub.origin.x - house.x, tub.origin.z - house.z).length()).is_greater(
				Vector2(point.x - house.x, point.z - house.z).length())


func test_the_tub_is_low_and_fits_half_a_cell() -> void:
	var box := YardView.tub_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(0.75)
	assert_float(maxf(box.size.x, box.size.z)).is_less(_sim.config.cell_size_m * 0.5)
