extends GdUnitTestSuite
## Madeira à deriva (Fase 161): a peça nova vem no fim da lista da costa (o sorteio das peças de antes não muda) e depois das
## papoulas no enum; aparece nas ilhas, só nas células baixas da costa e deitada com o terreno; a malha é comprida, baixa e só
## de madeira.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_driftwood_is_the_last_rule_of_the_coast() -> void:
	var coast: Array = ScatterView.NEAR_SEA.back()
	assert_int(coast[0]).is_equal(ScatterView.Kind.DRIFTWOOD)
	assert_int(ScatterView.Kind.DRIFTWOOD).is_greater(ScatterView.Kind.POPPIES)


func test_driftwood_washes_up_low_on_the_coast() -> void:
	var data := GameData.get_default()
	var count := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var logs: Array = items[ScatterView.Kind.DRIFTWOOD]
				for item: Array in logs:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					# baixo (o tronco anda pouco do meio da célula)
					assert_float(place.origin.y).is_less(ScatterView.DRIFTWOOD_MAX_HEIGHT_M + 0.8)
					# na costa: alguma vizinha de lado é mar (ou fora da grade)
					var by_sea := false
					for step: Vector2i in ScatterView.SIDES:
						var other := cell + step
						if not grid.in_bounds(other) or not grid.is_land(other):
							by_sea = true
					assert_bool(by_sea).is_true()
					# deitado: o tronco (x da peça) quase na horizontal
					assert_float(absf(place.basis.x.normalized().y)).is_less(0.45)
				count += logs.size()
	assert_int(count).is_greater(0)


func test_the_log_is_long_low_and_all_wood() -> void:
	var mesh := ScatterView.driftwood_mesh()
	var box := mesh.get_aabb()
	assert_float(box.size.x).is_greater(ScatterView.DRIFTWOOD_LENGTH_M * 0.9)
	assert_float(box.end.y).is_less(0.5)
	# meio afundado na areia, não enterrado
	assert_float(box.position.y).is_greater(-0.2)
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	for color: Color in colors:
		var bleached := absf(color.r - ScatterView.DRIFTWOOD_BLEACHED.r) + absf(color.g - ScatterView.DRIFTWOOD_BLEACHED.g)
		var dark := absf(color.r - ScatterView.DRIFTWOOD_DARK.r) + absf(color.g - ScatterView.DRIFTWOOD_DARK.g)
		assert_float(minf(bleached, dark)).is_less(0.02)
