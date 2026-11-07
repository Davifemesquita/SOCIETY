extends GdUnitTestSuite
## Tronco caído com cogumelos (Fase 246): a peça nova vem no fim da lista da beira da mata (o sorteio das peças de antes não muda) e
## depois das outras no enum; aparece nas ilhas temperadas, perto da mata e deitada com o chão, nunca nas tropicais; a malha é
## comprida e baixa.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_log_is_the_last_rule_of_the_forest_edge() -> void:
	assert_bool(_appended(ScatterView.NEAR_FOREST, ScatterView.Kind.MOSSY_LOG)).is_true()
	assert_int(ScatterView.Kind.MOSSY_LOG).is_greater(ScatterView.Kind.SEAWEED)
	assert_bool(ScatterView.Kind.MOSSY_LOG in ScatterView.SHADOWED).is_true()
	assert_bool(ScatterView.Kind.MOSSY_LOG in ScatterView.PLANTS).is_false()


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


func test_logs_lie_by_the_forest_on_temperate_islands_only() -> void:
	var data := GameData.get_default()
	var count := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var tropical := _world.is_tropical(island_id, data)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var logs: Array = items[ScatterView.Kind.MOSSY_LOG]
				if tropical:
					assert_int(logs.size()).is_equal(0)
				for item: Array in logs:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					assert_float(ScatterView.cell_relief(grid, cell)).is_less_equal(ScatterView.SCREE_MIN_RELIEF_M)
					# deitado: o tronco (x da peça) quase na horizontal
					assert_float(absf(place.basis.x.normalized().y)).is_less(0.45)
				count += logs.size()
	assert_int(count).is_greater(0)


func test_the_log_is_long_and_low() -> void:
	var box := ScatterView.mossy_log_mesh().get_aabb()
	assert_float(box.size.x).is_greater(ScatterView.MOSSY_LOG_M * 0.95)
	assert_float(box.end.y).is_less(0.6)
	assert_float(box.position.y).is_greater(-0.15)
