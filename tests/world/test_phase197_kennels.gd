extends GdUnitTestSuite
## Casinha do cão (Fase 197): só as casas que têm cão na porta ganham a casinha, na célula do lado de −X do lote, na fileira da
## frente, com a porta virada para a frente da casa; célula ocupada não tem; o recheio e as bombas deixam a célula; a casinha
## cabe na célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


## Casas espaçadas na rua y = 20 (duas células livres entre elas), de frente para ela.
func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 5, 20, tier, 5.0))
	return ids


func test_the_kennel_stands_beside_the_houses_with_a_dog() -> void:
	var ids := _houses(&"workers", 12)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := 0
	for id: int in ids:
		var record := _sim.world.building(id)
		var found: Variant = KennelView.spot(_sim, record)
		assert_bool(found is Transform3D).is_equal(id % AnimalView.DOG_EVERY == 0)
		if not found is Transform3D:
			continue
		count += 1
		var place: Transform3D = found
		var def := _sim.def_of(record)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var cell := grid.world_to_cell(place.origin)
		assert_bool(area.has_point(cell)).is_false()
		assert_bool(area.grow(1).has_point(cell)).is_true()
		assert_bool(KennelView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_true()
		# no referencial do modelo da casa: do lado de −X, na metade da frente
		var model := BuildingView.model_place(grid, record, area)
		var local := model.affine_inverse() * place.origin
		assert_float(local.x).is_less(-float(def.size.x) * grid.cell_size * 0.5)
		assert_float(local.z).is_less(0.0)
		# a porta (−z da casinha) olha para a frente da casa, e a casinha assenta no chão
		var front := Footprint.front_direction(record.rotation)
		assert_float((-place.basis.z).normalized().dot(Vector3(front.x, 0.0, front.y))).is_greater(0.99)
		assert_float(place.origin.y).is_equal_approx(grid.height_at(place.origin.x, place.origin.z), 0.001)
	assert_int(count).is_greater(0)


func test_no_kennel_on_a_taken_cell() -> void:
	_houses(&"peasants", 12)
	var found := KennelView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_int(found.size()).is_greater(0)
	var cell: Vector2i = found.keys()[0]
	SimFixture.road(_sim, Vector2i(cell.x, 0), Vector2i(cell.x, cell.y))
	assert_bool(KennelView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_false()


func test_the_scatter_and_the_pumps_keep_off_the_kennel() -> void:
	_houses(&"artisans", 12)
	var context := ScatterView.island_context(_sim.world, _sim.data, SimFixture.ISLAND)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	var found := KennelView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_int(found.size()).is_greater(0)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()


func test_the_kennel_fits_in_its_cell() -> void:
	var box := KennelView.kennel_mesh().get_aabb()
	assert_float(box.size.x).is_less(_sim.config.cell_size_m * 0.6)
	assert_float(box.size.z).is_less(_sim.config.cell_size_m)
	assert_float(box.size.y).is_between(KennelView.RIDGE_M, KennelView.RIDGE_M + 0.1)
	assert_float(box.position.y).is_greater_equal(-0.001)
