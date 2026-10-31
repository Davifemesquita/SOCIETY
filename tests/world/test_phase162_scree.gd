extends GdUnitTestSuite
## Cascalho nas encostas (Fase 162): a peça nova entra no fim das listas do campo aberto, da beira da mata e da costa (o sorteio
## das peças de antes não muda); aparece só nas células de encosta, deitada no plano dela; a malha é um montinho baixo de
## pedrinhas; o desnível e a normal da célula saem dos cantos.

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


func test_the_scree_comes_last_in_the_open_forest_and_coast_lists() -> void:
	for rules: Array[Array] in [ScatterView.OPEN, ScatterView.NEAR_FOREST, ScatterView.NEAR_SEA]:
		assert_bool(_appended(rules, ScatterView.Kind.SCREE)).is_true()
	assert_int(ScatterView.Kind.SCREE).is_greater(ScatterView.Kind.DRIFTWOOD)


func test_the_relief_and_the_normal_come_from_the_corners() -> void:
	var grid := IslandGrid.new(Vector2i(4, 4))
	grid.flat = false
	grid.corner_heights.resize(25)
	grid.corner_heights.fill(0.0)
	assert_float(ScatterView.cell_relief(grid, Vector2i(1, 1))).is_equal(0.0)
	assert_bool(ScatterView.cell_normal(grid, Vector2i(1, 1)).is_equal_approx(Vector3.UP)).is_true()
	# subindo 1 m por célula para +x: os cantos da direita 1 m acima
	for y: int in 5:
		for x: int in 5:
			grid.corner_heights[grid.corner_index(x, y)] = float(x)
	assert_float(ScatterView.cell_relief(grid, Vector2i(1, 1))).is_equal_approx(1.0, 0.001)
	var normal := ScatterView.cell_normal(grid, Vector2i(1, 1))
	assert_float(normal.x).is_less(0.0)
	assert_float(absf(normal.z)).is_less(0.001)


func test_scree_lies_on_the_slopes_only() -> void:
	var data := GameData.get_default()
	var count := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var stones: Array = items[ScatterView.Kind.SCREE]
				for item: Array in stones:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					# na encosta (o montinho anda pouco do meio da célula: confere a célula e as vizinhas)
					var steep := false
					for step: Vector2i in [Vector2i.ZERO] + ScatterView.AROUND:
						var other := cell + step
						if grid.in_bounds(other) and ScatterView.cell_relief(grid, other) >= ScatterView.SCREE_MIN_RELIEF_M:
							steep = true
					assert_bool(steep).is_true()
					# deitado na encosta: o y da peça não é o do mundo
					assert_float(place.basis.y.normalized().dot(Vector3.UP)).is_less(0.9999)
				count += stones.size()
	assert_int(count).is_greater(0)


func test_the_heap_is_low_and_small() -> void:
	var box := ScatterView.scree_mesh().get_aabb()
	assert_float(box.end.y).is_less(0.25)
	assert_float(maxf(box.size.x, box.size.z)).is_less(ScatterView.SCREE_RADIUS_M * 2.0 + 0.5)
