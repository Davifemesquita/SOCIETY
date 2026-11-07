extends GdUnitTestSuite
## Algas na praia (Fase 239): a peça nova vem no fim da lista da costa (o sorteio das peças de antes não muda) e depois das outras
## no enum; aparece nas ilhas, só nas células baixas e planas junto do mar, deitada no chão; a malha é uma faixa chata e comprida.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_seaweed_is_the_last_rule_of_the_coast() -> void:
	assert_bool(_appended(ScatterView.NEAR_SEA, ScatterView.Kind.SEAWEED)).is_true()
	assert_int(ScatterView.Kind.SEAWEED).is_greater(ScatterView.Kind.ROCK_PINE)
	assert_bool(ScatterView.Kind.SEAWEED in ScatterView.PLANTS).is_false()
	assert_bool(ScatterView.Kind.SEAWEED in ScatterView.SHADOWED).is_false()


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


func test_seaweed_lies_low_on_the_beach() -> void:
	var data := GameData.get_default()
	var count := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var weeds: Array = items[ScatterView.Kind.SEAWEED]
				for item: Array in weeds:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					assert_float(place.origin.y).is_less(ScatterView.SEAWEED_MAX_HEIGHT_M + 0.5)
					assert_float(ScatterView.cell_relief(grid, cell)).is_less_equal(ScatterView.SEAWEED_MAX_RELIEF_M)
					# na costa: alguma vizinha de lado é mar (ou fora da grade)
					var by_sea := false
					for step: Vector2i in ScatterView.SIDES:
						var other := cell + step
						if not grid.in_bounds(other) or not grid.is_land(other):
							by_sea = true
					assert_bool(by_sea).is_true()
					# deitadas: o alto da peça quase para cima
					assert_float(place.basis.y.normalized().y).is_greater(0.85)
				count += weeds.size()
	assert_int(count).is_greater(0)


func test_the_wrack_is_a_flat_long_line() -> void:
	var box := ScatterView.seaweed_mesh().get_aabb()
	assert_float(box.size.x).is_greater(ScatterView.SEAWEED_LENGTH_M)
	assert_float(box.size.z).is_greater(box.size.y * 4.0)
	assert_float(box.size.x).is_greater(box.size.z * 1.5)
	assert_float(box.end.y).is_less(0.2)
	assert_float(box.position.y).is_greater(-0.1)
