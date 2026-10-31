extends GdUnitTestSuite
## Papoulas no prado (Fase 156): a peça nova vem no fim das listas do campo aberto e da beira da estrada (o sorteio das peças
## de antes não muda); os canteiros são manchas pelo ruído, não flores soltas, só nas ilhas temperadas e acima da areia da
## praia; o canteiro é baixo, cabe na célula e é leve.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_poppies_are_the_last_rule_of_the_open_field_and_the_road_side() -> void:
	var open: Array = ScatterView.OPEN.back()
	var road: Array = ScatterView.NEAR_ROAD.back()
	assert_int(open[0]).is_equal(ScatterView.Kind.POPPIES)
	assert_int(road[0]).is_equal(ScatterView.Kind.POPPIES)
	assert_int(ScatterView.Kind.POPPIES).is_equal(ScatterView.Kind.size() - 1)


func test_the_patches_cover_a_small_share_of_the_land_in_clumps() -> void:
	var inside := 0
	var together := 0
	var size := 200
	for y: int in size:
		for x: int in size:
			if not ScatterView.poppy_patch(0, Vector2i(x, y)):
				continue
			inside += 1
			if ScatterView.poppy_patch(0, Vector2i(x + 1, y)) or ScatterView.poppy_patch(0, Vector2i(x, y + 1)):
				together += 1
	var share := inside / float(size * size)
	assert_float(share).is_between(0.02, 0.2)
	# manchas: quase toda célula de canteiro tem outra encostada
	assert_float(together / float(inside)).is_greater(0.8)
	# outra ilha, outros canteiros
	var same := 0
	for y: int in 60:
		for x: int in 60:
			if ScatterView.poppy_patch(0, Vector2i(x, y)) == ScatterView.poppy_patch(1, Vector2i(x, y)):
				same += 1
	assert_int(same).is_less(60 * 60)


func test_poppies_grow_in_patches_on_temperate_islands_only() -> void:
	var data := GameData.get_default()
	var temperate := 0
	var tropical := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var poppies: Array = items[ScatterView.Kind.POPPIES]
				for item: Array in poppies:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					assert_bool(ScatterView.poppy_patch(island_id, cell)).is_true()
					# acima da areia da praia (o canteiro anda pouco do meio da célula)
					assert_float(place.origin.y).is_greater(ScatterView.POPPY_MIN_HEIGHT_M - 0.6)
				if _world.is_tropical(island_id, data):
					tropical += poppies.size()
				else:
					temperate += poppies.size()
	assert_int(temperate).is_greater(0)
	assert_int(tropical).is_equal(0)


func test_the_patch_is_low_fits_the_cell_and_is_light() -> void:
	var mesh := ScatterView.poppy_mesh()
	var box := mesh.get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(0.75)
	assert_float(maxf(absf(box.position.x), absf(box.end.x))).is_less(1.0)
	assert_float(maxf(absf(box.position.z), absf(box.end.z))).is_less(1.0)
	var indices: PackedInt32Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	assert_int(indices.size() / 3).is_less(ScatterView.POPPY_FLOWERS * 12)
	# as flores são vermelhas
	var red := 0
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	for color: Color in colors:
		if color.r > 0.5 and color.g < 0.2:
			red += 1
	assert_int(red).is_greater(colors.size() / 3)
