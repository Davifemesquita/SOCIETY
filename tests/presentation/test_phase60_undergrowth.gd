extends GdUnitTestSuite
## Fase 60: sub-bosque tropical no recheio (ScatterView) — bananeira e samambaia no lugar do arbusto nas ilhas
## tropicais; as temperadas continuam com o arbusto e nenhuma planta tropical.


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
	for index: int in world.islands.size():
		if world.island(index).flat:
			continue
		var totals := _island_items(world, data, config, index)
		var bushes: int = totals.get(ScatterView.Kind.BUSH, 0)
		var bananas: int = totals.get(ScatterView.Kind.BANANA, 0)
		var ferns: int = totals.get(ScatterView.Kind.FERN, 0)
		var counts := Vector3i(bushes, bananas, ferns)
		if world.is_tropical(index, data):
			tropical += counts
		else:
			temperate += counts
	print("tropical (arbusto, bananeira, samambaia): %s; temperada: %s" % [tropical, temperate])
	assert_int(tropical.x).is_equal(0)
	assert_int(tropical.y).is_greater(0)
	assert_int(tropical.z).is_greater(tropical.y)
	assert_int(temperate.x).is_greater(0)
	assert_int(temperate.y + temperate.z).is_equal(0)
