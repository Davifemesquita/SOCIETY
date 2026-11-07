extends GdUnitTestSuite
## Tábuas secando na serraria (Fase 215): cada serraria ganha as duas células do meio do lado oposto à roda d'água, encostadas
## nela; com uma delas bloqueada, a pilha vai para os fundos; outros prédios não têm; o recheio e as bombas deixam as células; a
## pilha cabe na célula e fica de pé no chão.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_planks_sit_opposite_the_waterwheel() -> void:
	for rotation: int in 4:
		_sim = SimFixture.simulation(Vector2i(60, 40))
		_sim.free_build = true
		var id := SimFixture.place(_sim, &"sawmill", Vector2i(20, 15), rotation)
		var record := _sim.world.building(id)
		var grid := _sim.world.island(0)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var found := PlankStackView.sites(_sim.world, _sim.data, 0)
		assert_bool(found.has(id)).is_true()
		var site: Array = found[id]
		var pair: Array[Vector2i] = site[0]
		var side: Vector2i = site[1]
		assert_int(pair.size()).is_equal(2)
		# a roda d'água fica no +X do modelo: as tábuas, do outro lado
		var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
		var rotor := BuildingKit.rotor(spec)
		var model := BuildingView.model_place(grid, record, area)
		var wheel := model * rotor.pivot.origin
		for cell: Vector2i in pair:
			assert_bool(area.has_point(cell)).is_false()
			assert_bool(area.has_point(cell - side)).is_true()
			var to_wheel := wheel - grid.cell_world(cell)
			var to_area := grid.cell_world(cell - side) - grid.cell_world(cell)
			assert_float(Vector2(to_wheel.x, to_wheel.z).dot(Vector2(to_area.x, to_area.z))).is_greater(0.0)
			assert_float(Vector2(to_wheel.x, to_wheel.z).length()).is_greater(grid.cell_size * 3.5)


func test_a_blocked_cell_moves_the_planks_to_the_back() -> void:
	var id := SimFixture.place(_sim, &"sawmill", Vector2i(20, 15), 0)
	var first: Array = PlankStackView.sites(_sim.world, _sim.data, 0)[id]
	var pair: Array[Vector2i] = first[0]
	SimFixture.road(_sim, pair[1], pair[1] + Vector2i(0, 1))
	var found := PlankStackView.sites(_sim.world, _sim.data, 0)
	assert_bool(found.has(id)).is_true()
	var second: Array = found[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_int(side_before.x * side_after.x + side_before.y * side_after.y).is_equal(0)
	var front := Footprint.front_direction(0)
	assert_bool(side_after == -front).is_true()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"mill", Vector2i(20, 15), 0)
	assert_int(PlankStackView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"sawmill", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.taken_cells(_sim.world, _sim.data, 0)
	var found := PlankStackView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(2)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_true()


func test_the_stack_stands_in_its_cell() -> void:
	var box := PlankStackView.stack_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_between(0.8, 1.2)
	assert_float(box.size.x).is_less(2.0)
	# encostada na parede: de −1 m (a parede) até menos de 1 m para fora
	assert_float(box.position.z).is_greater_equal(-1.05)
	assert_float(box.end.z).is_less(1.0)
