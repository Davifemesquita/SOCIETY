extends GdUnitTestSuite
## Árvore seca (Fase 141): a peça nova vem no fim das listas da beira da mata e da costa (o sorteio das peças de antes não
## muda), aparece nas ilhas temperadas e nunca nas tropicais; a malha é alta e nua.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_snag_is_the_last_rule_of_the_forest_edge_and_the_coast() -> void:
	# entrou no fim das duas listas: antes dela só peças mais velhas, depois só as que vieram depois (fim do enum)
	for rules: Array[Array] in [ScatterView.NEAR_FOREST, ScatterView.NEAR_SEA]:
		assert_bool(_appended(rules, ScatterView.Kind.SNAG)).is_true()
	assert_int(ScatterView.Kind.SNAG).is_greater(ScatterView.Kind.STREET_PALM)


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


func test_snags_grow_on_temperate_islands_only() -> void:
	var data := GameData.get_default()
	var temperate := 0
	var tropical := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var count := 0
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var snags: Array = items[ScatterView.Kind.SNAG]
				count += snags.size()
		if _world.is_tropical(island_id, data):
			tropical += count
		else:
			temperate += count
	assert_int(temperate).is_greater(0)
	assert_int(tropical).is_equal(0)


func test_the_snag_is_tall_and_bare() -> void:
	var mesh := ScatterView.snag_mesh()
	var box := mesh.get_aabb()
	assert_float(box.size.y).is_greater(ScatterView.SNAG_HEIGHT_M * 0.9)
	assert_float(box.position.y).is_greater(-0.1)
	# sem folha: só as duas cores da madeira
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	for color: Color in colors:
		var wood := absf(color.r - ScatterView.SNAG_WOOD.r) + absf(color.g - ScatterView.SNAG_WOOD.g)
		var dark := absf(color.r - ScatterView.SNAG_DARK.r) + absf(color.g - ScatterView.SNAG_DARK.g)
		assert_float(minf(wood, dark)).is_less(0.02)
