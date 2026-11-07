extends GdUnitTestSuite
## Fase 60: sub-bosque tropical no recheio (ScatterView) — bananeira e samambaia no lugar do arbusto nas ilhas
## tropicais; as temperadas continuam com o arbusto e nenhuma planta tropical. Fase 61: e a helicônia no lugar das
## flores do campo.


func test_banana_and_fern_meshes_stand_on_the_ground_in_their_size() -> void:
	var banana := ScatterView.piece_mesh(ScatterView.Kind.BANANA).get_aabb()
	var fern := ScatterView.piece_mesh(ScatterView.Kind.FERN).get_aabb()
	assert_float(banana.position.y).is_between(-0.01, 0.6)
	assert_float(banana.end.y).is_between(2.0, 3.2)
	assert_float(minf(banana.size.x, banana.size.z)).is_greater(1.8)
	# a dobra da lâmina desce uns centímetros na ponta
	assert_float(fern.position.y).is_between(-0.05, 0.1)
	assert_float(fern.end.y).is_between(0.3, 0.8)
	assert_float(minf(fern.size.x, fern.size.z)).is_greater(1.0)
	# Fase 61: a helicônia, em pé, com as brácteas vermelhas no alto
	var heliconia_mesh := ScatterView.piece_mesh(ScatterView.Kind.HELICONIA)
	var heliconia := heliconia_mesh.get_aabb()
	assert_float(heliconia.position.y).is_between(-0.05, 0.1)
	assert_float(heliconia.end.y).is_between(0.9, 1.5)
	var arrays := heliconia_mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var lowest_red := INF
	for i: int in points.size():
		if colors[i].r > 0.7 and colors[i].g < 0.3:
			lowest_red = minf(lowest_red, points[i].y)
	assert_float(lowest_red).is_greater(0.4)


func _island_items(world: WorldState, data: GameData, config: GameConfig, index: int) -> Dictionary:
	var totals: Dictionary[int, int] = {}
	var grid := world.island(index)
	var context := ScatterView.island_context(world, data, index)
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(world, data, config, index, Vector2i(cx, cy), context)
			for kind: int in items:
				var list: Array = items[kind]
				var before: int = totals.get(kind, 0)
				totals[kind] = before + list.size()
	return totals


func test_tropical_islands_grow_bananas_and_ferns_instead_of_bushes() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data)
	var tropical := Vector3i.ZERO
	var temperate := Vector3i.ZERO
	var tropical_flowers := Vector2i.ZERO
	var temperate_flowers := Vector2i.ZERO
	for index: int in world.islands.size():
		if world.island(index).flat:
			continue
		var totals := _island_items(world, data, config, index)
		var bushes: int = totals.get(ScatterView.Kind.BUSH, 0)
		var bananas: int = totals.get(ScatterView.Kind.BANANA, 0)
		var ferns: int = totals.get(ScatterView.Kind.FERN, 0)
		var counts := Vector3i(bushes, bananas, ferns)
		var flowers: int = totals.get(ScatterView.Kind.FLOWERS, 0)
		var heliconias: int = totals.get(ScatterView.Kind.HELICONIA, 0)
		if world.is_tropical(index, data):
			tropical += counts
			tropical_flowers += Vector2i(flowers, heliconias)
		else:
			temperate += counts
			temperate_flowers += Vector2i(flowers, heliconias)
	print("tropical (arbusto, bananeira, samambaia): %s; temperada: %s" % [tropical, temperate])
	assert_int(tropical.x).is_equal(0)
	assert_int(tropical.y).is_greater(0)
	assert_int(tropical.z).is_greater(tropical.y)
	assert_int(temperate.x).is_greater(0)
	assert_int(temperate.y + temperate.z).is_equal(0)
	# Fase 61: flores do campo (x) e helicônias (y)
	print("flores tropicais: %s; temperadas: %s" % [tropical_flowers, temperate_flowers])
	assert_int(tropical_flowers.x).is_equal(0)
	assert_int(tropical_flowers.y).is_greater(0)
	assert_int(temperate_flowers.x).is_greater(0)
	assert_int(temperate_flowers.y).is_equal(0)
