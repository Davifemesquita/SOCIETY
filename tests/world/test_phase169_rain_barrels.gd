extends GdUnitTestSuite
## Barril de chuva (Fase 169): só as casas de camponeses e operários do resto certo têm o barril, encostado atrás da quina de −X,
## na célula de trás quando ela está livre; a célula do barril é a mesma que o recheio e as bombas deixam limpa; a calha sobe
## até o beiral; o barril é baixo e redondo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 4, 20, tier, 5.0))
	return ids


func test_the_barrel_stands_behind_the_houses_of_its_rest() -> void:
	var ids := _houses(&"workers", 8)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := 0
	for id: int in ids:
		var record := _sim.world.building(id)
		var found: Variant = RainBarrelView.spot(_sim, record)
		var expected := posmod(id, RainBarrelView.BARREL_EVERY) == RainBarrelView.BARREL_REST
		assert_bool(found is Array).is_equal(expected)
		if not expected:
			continue
		count += 1
		var pair: Array = found
		var place: Transform3D = pair[0]
		var eave: float = pair[1]
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var cell := grid.world_to_cell(place.origin)
		# atrás da casa (a casa fica acima da rua: a frente é +y, então atrás é −y), fora do lote
		assert_bool(area.has_point(cell)).is_false()
		assert_int(cell.y).is_equal(area.position.y - 1)
		# a célula do barril é a que as outras peças deixam limpa
		assert_bool(RainBarrelView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_true()
		# a calha sobe até o beiral (pelo menos um andar)
		assert_float(eave).is_greater(2.0)
	assert_int(count).is_greater(0)


func test_only_peasants_and_workers_and_only_on_a_free_cell() -> void:
	var ids := _houses(&"artisans", 6)
	for id: int in ids:
		assert_bool(RainBarrelView.spot(_sim, _sim.world.building(id)) is Array).is_false()
	for id: int in ids:
		_sim.world.building(id).tier = &"peasants"
	var found := RainBarrelView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_int(found.size()).is_greater(0)
	var cell: Vector2i = found.keys()[0]
	SimFixture.road(_sim, Vector2i(0, cell.y), Vector2i(119, cell.y))
	assert_bool(RainBarrelView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_false()


func test_the_scatter_and_the_pumps_keep_off_the_barrel() -> void:
	_houses(&"peasants", 8)
	var context := ScatterView.island_context(_sim.world, _sim.data, SimFixture.ISLAND)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	for cell: Vector2i in RainBarrelView.cells(_sim.world, _sim.data, SimFixture.ISLAND):
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()


func test_the_barrel_is_low_and_round() -> void:
	var box := RainBarrelView.barrel_body_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	# a calha chega ao beiral: o cano esticado da curva até ele
	var pipe := RainBarrelView.pipe_place(Transform3D.IDENTITY, 5.0) * RainBarrelView.pipe_mesh().get_aabb()
	assert_float(pipe.end.y).is_equal_approx(5.0, 0.01)
	assert_float(pipe.position.y).is_equal_approx(RainBarrelView.BEND_M, 0.01)
	# o barril é mais largo que fundo só pela calha, que fica atrás (−Z)
	assert_float(box.position.z).is_less(-RainBarrelView.RADIUS_M)
	assert_float(box.end.z).is_equal_approx(RainBarrelView.RADIUS_M + 0.012, 0.02)
