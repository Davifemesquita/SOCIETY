extends GdUnitTestSuite
## Pinheiro-anão na encosta (Fase 207): a peça nova entra no fim das listas do campo aberto e da beira da mata (o sorteio das
## peças de antes não muda); aparece só nas encostas íngremes das ilhas temperadas, de pé; a malha é uma árvore baixa e torta.

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


func test_the_pine_comes_last_in_the_open_and_forest_lists() -> void:
	for rules: Array[Array] in [ScatterView.OPEN, ScatterView.NEAR_FOREST]:
		assert_bool(_appended(rules, ScatterView.Kind.ROCK_PINE)).is_true()
	assert_int(ScatterView.Kind.ROCK_PINE).is_greater(ScatterView.Kind.REEDS)
	assert_bool(ScatterView.Kind.ROCK_PINE in ScatterView.PLANTS).is_true()


func test_pines_grow_upright_on_steep_temperate_slopes_only() -> void:
	var data := GameData.get_default()
	var count := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var tropical := _world.is_tropical(island_id, data)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var pines: Array = items[ScatterView.Kind.ROCK_PINE]
				for item: Array in pines:
					assert_bool(tropical).is_false()
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					assert_float(ScatterView.cell_relief(grid, cell)).is_greater_equal(ScatterView.ROCK_PINE_MIN_RELIEF_M)
					# de pé: o y da peça segue o do mundo
					assert_float(place.basis.y.normalized().dot(Vector3.UP)).is_greater(0.999)
					count += 1
	assert_int(count).is_greater(0)


func test_the_pine_is_low_and_crooked() -> void:
	var box := ScatterView.rock_pine_mesh().get_aabb()
	assert_float(box.end.y).is_between(ScatterView.ROCK_PINE_HEIGHT_M, ScatterView.ROCK_PINE_HEIGHT_M + 0.6)
	# mais larga que funda ou alta pela metade: o galho deitado para o lado
	assert_float(box.size.x).is_greater(box.size.y * 0.5)
