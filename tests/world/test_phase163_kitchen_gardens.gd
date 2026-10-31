extends GdUnitTestSuite
## Horta no quintal (Fase 163): só as casas de camponeses e operários do resto GARDEN_REST têm horta, na célula de trás (a da
## fogueira e do varal, que usam outros restos); sem a célula livre, nada; o recheio e as bombas a deixam limpa; o canteiro
## cabe na célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


## Casas em fila na rua y = 20 (acima dela, de frente para ela), até ter n de cada resto do id.
func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 4, 20, tier, 5.0))
	return ids


func test_the_garden_goes_behind_the_houses_of_its_rest() -> void:
	var ids := _houses(&"peasants", 9)
	var found := KitchenGardenView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	var gardens := 0
	for id: int in ids:
		var record := _sim.world.building(id)
		var has := found.values().has(id)
		assert_bool(has).is_equal(posmod(id, KitchenGardenView.GARDEN_EVERY) == KitchenGardenView.GARDEN_REST)
		if not has:
			continue
		gardens += 1
		var cell: Vector2i = found.keys()[found.values().find(id)]
		# atrás da casa: do outro lado da rua, encostada na área
		var area := Footprint.rect(record.origin, Vector2i(3, 3), record.rotation)
		assert_bool(area.has_point(cell)).is_false()
		assert_bool(area.has_point(cell - Footprint.front_direction(record.rotation) * -1)).is_true()
		# a mesma célula da fogueira e do varal, que usam outros restos
		var spot: Variant = LampView.bonfire_spot(_sim, record)
		assert_bool(spot is Vector3).is_true()
		var point: Vector3 = spot
		assert_bool(_sim.world.island(SimFixture.ISLAND).world_to_cell(point) == cell).is_true()
	assert_int(gardens).is_greater(0)
	assert_int(KitchenGardenView.GARDEN_REST).is_not_equal(YardView.CLOTHESLINE_REST)
	assert_int(KitchenGardenView.GARDEN_REST).is_not_equal(0)


func test_only_peasants_and_workers_and_only_on_a_free_cell() -> void:
	var artisans := _houses(&"artisans", 6)
	assert_int(KitchenGardenView.cells(_sim.world, _sim.data, SimFixture.ISLAND).size()).is_equal(0)
	for id: int in artisans:
		_sim.world.building(id).tier = &"workers"
	var found := KitchenGardenView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	assert_int(found.size()).is_greater(0)
	# uma estrada atrás tira a horta
	var cell: Vector2i = found.keys()[0]
	SimFixture.road(_sim, Vector2i(0, cell.y), Vector2i(119, cell.y))
	assert_bool(KitchenGardenView.cells(_sim.world, _sim.data, SimFixture.ISLAND).has(cell)).is_false()


func test_the_scatter_and_the_pumps_keep_off_the_garden() -> void:
	_houses(&"peasants", 9)
	var context := ScatterView.island_context(_sim.world, _sim.data, SimFixture.ISLAND)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, SimFixture.ISLAND)
	for cell: Vector2i in KitchenGardenView.cells(_sim.world, _sim.data, SimFixture.ISLAND):
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()


func test_the_bed_fits_the_cell() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	KitchenGardenView.garden_mesh(tool, Transform3D.IDENTITY)
	tool.generate_normals()
	var box := tool.commit().get_aabb()
	var half := _sim.config.cell_size_m * 0.5
	assert_float(maxf(absf(box.position.x), absf(box.end.x))).is_less(half)
	assert_float(maxf(absf(box.position.z), absf(box.end.z))).is_less(half)
	assert_float(box.end.y).is_less(1.8)
	assert_float(box.position.y).is_greater(-0.1)
