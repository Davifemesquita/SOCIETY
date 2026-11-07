extends GdUnitTestSuite
## Carrinho de mão (Fase 172): só as oficinas do resto certo (fora as fazendas de campo) têm o carrinho, na célula livre atrás
## delas; casas não; uma estrada na célula tira o carrinho; o recheio e as bombas deixam a célula; o carrinho é do tamanho de um
## carrinho, com a roda na frente.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


func _workshops(count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 6), Vector2i(119, 6))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.place(_sim, &"lumberjack", Vector2i(2 + i * 5, 7), 0))
	return ids


func test_workshops_of_its_rest_get_a_barrow_behind_them() -> void:
	var ids := _workshops(6)
	var found := WheelbarrowView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	var count := 0
	for id: int in ids:
		var has := found.values().has(id)
		assert_bool(has).is_equal(posmod(id, WheelbarrowView.BARROW_EVERY) == WheelbarrowView.BARROW_REST)
		if not has:
			continue
		count += 1
		var cell: Vector2i = found.keys()[found.values().find(id)]
		var record := _sim.world.building(id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		# atrás: a frente é −y (a rua em y = 6), então a célula fica logo abaixo do lote
		assert_bool(area.has_point(cell)).is_false()
		assert_int(cell.y).is_equal(area.end.y)
	assert_int(count).is_greater(0)


func test_houses_get_none_and_a_road_takes_the_cell() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	for i: int in 4:
		SimFixture.house(_sim, 2 + i * 4, 20, &"peasants", 5.0)
	assert_int(WheelbarrowView.cells(_sim.world, _sim.data, SimFixture.ISLAND).size()).is_equal(0)
	_workshops(4)
	var found := WheelbarrowView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	var cell: Vector2i = found.keys()[0]
	SimFixture.road(_sim, Vector2i(0, cell.y), Vector2i(119, cell.y))
	assert_bool(WheelbarrowView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_false()


func test_the_scatter_and_the_pumps_keep_off_the_barrow() -> void:
	_workshops(6)
	var context := ScatterView.island_context(_sim.world, _sim.data, SimFixture.ISLAND)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	for cell: Vector2i in WheelbarrowView.cells(_sim.world, _sim.data, SimFixture.ISLAND):
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()


func test_the_barrow_is_barrow_sized_with_the_wheel_in_front() -> void:
	var box := WheelbarrowView.barrow_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_between(0.5, 0.8)
	assert_float(box.size.z).is_between(1.2, 1.9)
	assert_float(box.size.x).is_less(0.8)
	# a roda é a ponta da frente (−Z)
	assert_float(box.position.z).is_less(-0.6)
