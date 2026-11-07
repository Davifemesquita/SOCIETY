extends GdUnitTestSuite
## Capim alto nos terrenos vazios (Fase 167): a peça nova entra no fim da lista do campo aberto (o sorteio das peças de antes não
## muda); as manchas são juntas pelo ruído, não coincidem com as papoulas e mudam de ilha para ilha; o capim só aparece nas
## manchas das temperadas, fora dos canteiros de papoulas; a touceira é leve, cabe na célula e é mais alta que o capim baixo.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


## Se a peça está na lista com só peças mais velhas antes dela e só mais novas depois (o sorteio de antes não mudou).
func _appended(rules: Array[Array], kind: int) -> bool:
	var seen := false
	for rule: Array in rules:
		var other: int = rule[0]
		if other == kind:
			seen = true
		elif (other > kind) != seen:
			return false
	return seen


func test_the_tall_grass_comes_last_in_the_open_field() -> void:
	assert_bool(_appended(ScatterView.OPEN, ScatterView.Kind.TALL_GRASS)).is_true()
	assert_int(ScatterView.Kind.TALL_GRASS).is_greater(ScatterView.Kind.SCREE)


func test_the_patches_clump_and_differ_from_the_poppies() -> void:
	var inside := 0
	var together := 0
	var shared := 0
	var size := 200
	for y: int in size:
		for x: int in size:
			if not ScatterView.tall_grass_patch(0, Vector2i(x, y)):
				continue
			inside += 1
			if ScatterView.tall_grass_patch(0, Vector2i(x + 1, y)) or ScatterView.tall_grass_patch(0, Vector2i(x, y + 1)):
				together += 1
			if ScatterView.poppy_patch(0, Vector2i(x, y)):
				shared += 1
	assert_float(inside / float(size * size)).is_between(0.03, 0.3)
	assert_float(together / float(inside)).is_greater(0.8)
	# quase nada em comum com os canteiros de papoulas
	assert_float(shared / float(inside)).is_less(0.3)


func test_tall_grass_grows_in_its_patches_on_temperate_islands_only() -> void:
	var data := GameData.get_default()
	var temperate := 0
	var tropical := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var clumps: Array = items[ScatterView.Kind.TALL_GRASS]
				for item: Array in clumps:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					assert_bool(ScatterView.tall_grass_patch(island_id, cell)).is_true()
					assert_bool(ScatterView.poppy_patch(island_id, cell)).is_false()
				if _world.is_tropical(island_id, data):
					tropical += clumps.size()
				else:
					temperate += clumps.size()
	assert_int(temperate).is_greater(0)
	assert_int(tropical).is_equal(0)


func test_the_clump_is_light_tall_and_fits_the_cell() -> void:
	var mesh := ScatterView.tall_grass_mesh()
	var box := mesh.get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_greater(ScatterView.TALL_GRASS_HEIGHT_M.x)
	assert_float(box.end.y).is_less(1.3)
	assert_float(maxf(absf(box.position.x), absf(box.end.x))).is_less(1.2)
	var indices: PackedInt32Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	assert_int(indices.size() / 3).is_less(ScatterView.TALL_GRASS_BLADES * 4)
