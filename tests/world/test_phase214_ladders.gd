extends GdUnitTestSuite
## Escada de mão (Fase 214): só as casas do resto certo, de duas águas e com a célula do lado livre, têm a escada, na parede de −X
## do corpo, na metade de trás, encostada nela e chegando ao beiral; célula com estrada não tem; o recheio e as bombas deixam a
## célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(160, 40))
	_sim.free_build = true


func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(159, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 5, 20, tier, 5.0))
	return ids


func test_the_ladder_leans_on_the_side_wall_up_to_the_eave() -> void:
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := 0
	for id: int in _houses(&"workers", 28):
		var record := _sim.world.building(id)
		var found: Variant = LadderView.spot(_sim, record)
		if posmod(id, LadderView.LADDER_EVERY) != LadderView.LADDER_REST:
			assert_object(found).is_null()
			continue
		if not found is Transform3D:
			continue
		count += 1
		var place: Transform3D = found
		var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
		var hall := spec.hall()
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var model := BuildingView.model_place(grid, record, area)
		var local := model.affine_inverse() * place.origin
		# o pé na parede de −X do corpo, na metade de trás
		assert_float(local.x).is_equal_approx(spec.hall_offset().x - hall.size_m().x * 0.5, 0.01)
		assert_float(local.z).is_greater(spec.hall_offset().z)
		# o alto da escada (y = HEIGHT_M na malha) chega ao beiral, encostado na parede (z = 0)
		var top := model.affine_inverse() * (place * Vector3(0.0, LadderView.HEIGHT_M, 0.0))
		assert_float(top.y - local.y).is_equal_approx(hall.height_m, 0.01)
		assert_float(top.x).is_equal_approx(local.x, 0.01)
		# o pé para fora da parede
		var foot := model.affine_inverse() * (place * Vector3(0.0, 0.0, LadderView.FOOT_OUT_M))
		assert_float(foot.x).is_less(local.x)
		assert_bool(LadderView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(grid.world_to_cell(place * Vector3(0.0,
				0.0, LadderView.FOOT_OUT_M * 0.5)))).is_true()
	assert_int(count).is_greater(0)


func test_no_ladder_on_a_taken_cell_and_the_scatter_keeps_off() -> void:
	_houses(&"peasants", 28)
	var found := LadderView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_int(found.size()).is_greater(0)
	var context := ScatterView.island_context(_sim.world, _sim.data, SimFixture.ISLAND)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()
	var cell: Vector2i = found.keys()[0]
	SimFixture.road(_sim, Vector2i(cell.x, 0), Vector2i(cell.x, cell.y))
	assert_bool(LadderView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_false()
