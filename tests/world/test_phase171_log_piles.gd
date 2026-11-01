extends GdUnitTestSuite
## Lenha na parede (Fase 171): só as casas de camponeses e operários do resto certo têm a pilha, encostada do lado do corpo, na
## célula do lado quando ela está livre; o recheio e as bombas deixam a célula; a pilha é baixa, comprida ao longo da parede e
## cabe na célula de fundo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


## Casas espaçadas na rua y = 20 (uma célula livre entre elas), de frente para ela.
func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 5, 20, tier, 5.0))
	return ids


func test_the_pile_leans_on_the_side_of_the_houses_of_its_rest() -> void:
	var ids := _houses(&"workers", 9)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := 0
	for id: int in ids:
		var record := _sim.world.building(id)
		var found: Variant = LogPileView.spot(_sim, record)
		assert_bool(found is Transform3D).is_equal(posmod(id, LogPileView.PILE_EVERY) == LogPileView.PILE_REST)
		if not found is Transform3D:
			continue
		count += 1
		var place: Transform3D = found
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var cell := grid.world_to_cell(place.origin)
		assert_bool(area.has_point(cell)).is_false()
		# do lado: na mesma faixa de y da casa
		assert_bool(cell.y >= area.position.y and cell.y < area.end.y).is_true()
		assert_bool(LogPileView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_true()
		# o +Z da pilha aponta para longe da casa
		var middle := grid.rect_world(area)
		assert_float(place.basis.z.dot(place.origin - middle)).is_greater(0.0)
	assert_int(count).is_greater(0)


func test_only_peasants_and_workers_and_only_on_a_free_cell() -> void:
	var ids := _houses(&"artisans", 6)
	assert_int(LogPileView.cells(_sim.world, _sim.data, SimFixture.ISLAND).size()).is_equal(0)
	for id: int in ids:
		_sim.world.building(id).tier = &"peasants"
	var found := LogPileView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_int(found.size()).is_greater(0)
	var cell: Vector2i = found.keys()[0]
	SimFixture.road(_sim, Vector2i(cell.x, 0), Vector2i(cell.x, cell.y))
	assert_bool(LogPileView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_false()


func test_the_scatter_and_the_pumps_keep_off_the_pile() -> void:
	_houses(&"peasants", 9)
	var context := ScatterView.island_context(_sim.world, _sim.data, SimFixture.ISLAND)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	for cell: Vector2i in LogPileView.cells(_sim.world, _sim.data, SimFixture.ISLAND):
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()


func test_the_pile_is_low_and_long() -> void:
	var box := LogPileView.pile_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(1.1)
	assert_float(box.size.x).is_greater(LogPileView.LENGTH_M * 0.9)
	assert_float(box.size.z).is_less(_sim.config.cell_size_m * 0.5)
