extends GdUnitTestSuite
## Abetos na rocha (Fase 294): a peça nova no fim do enum e das listas OPEN, NEAR_FOREST e NEAR_SEA (o sorteio das peças de antes
## não muda), com sombra, no material das árvores; só nas encostas íngremes das temperadas, de pé, pequena (o abeto reduzido).

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([120])
	_config.tropical_island_sizes_cells = PackedInt32Array([50])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


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


func _spruces(island_id: int) -> Array:
	var grid := _sim.world.island(island_id)
	var found: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, island_id, Vector2i(cx, cy))
			var list: Array = items[ScatterView.Kind.CLIFF_SPRUCE]
			found.append_array(list)
	return found


func test_the_spruce_is_the_last_rule_of_its_lists() -> void:
	assert_int(ScatterView.Kind.CLIFF_SPRUCE).is_greater(ScatterView.Kind.SUNFLOWER)
	for rules: Array[Array] in [ScatterView.OPEN, ScatterView.NEAR_FOREST, ScatterView.NEAR_SEA]:
		assert_bool(_appended(rules, ScatterView.Kind.CLIFF_SPRUCE)).is_true()
	assert_bool(ScatterView.Kind.CLIFF_SPRUCE in ScatterView.SHADOWED).is_true()


func test_spruces_cling_to_steep_temperate_slopes() -> void:
	var grid := _sim.world.island(0)
	var spruces := _spruces(0)
	print("abetos na rocha: ", spruces.size())
	assert_int(spruces.size()).is_greater(0)
	for item: Array in spruces:
		var place: Transform3D = item[0]
		var cell := grid.world_to_cell(place.origin)
		assert_float(ScatterView.cell_relief(grid, cell)).is_greater_equal(ScatterView.CLIFF_SPRUCE_MIN_RELIEF_M)
		# de pé e pequeno
		assert_float(place.basis.y.normalized().y).is_greater(0.99)
		assert_float(place.basis.y.length()).is_between(ScatterView.CLIFF_SPRUCE_SCALE * 0.79, ScatterView.CLIFF_SPRUCE_SCALE * 1.26)
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			assert_int(_spruces(island_id).size()).is_equal(0)


func test_the_piece_is_the_spruce_with_the_tree_material() -> void:
	var mesh := ScatterView.piece_mesh(ScatterView.Kind.CLIFF_SPRUCE)
	assert_object(mesh).is_same(TreeModel.mesh(TreeModel.Species.NORWAY_SPRUCE, 1))
	var material := mesh.surface_get_material(0) as ShaderMaterial
	assert_str(material.shader.resource_path).is_equal(TreeModel.TREE_SHADER)
	# pequeno: o abeto de ~9 m vira ~3,6 m
	assert_float(mesh.get_aabb().end.y * ScatterView.CLIFF_SPRUCE_SCALE).is_between(3.0, 4.5)
