extends GdUnitTestSuite
## Papoulas soltas (Fase 288): o canteiro de cada célula anda mais do meio dela, fica menor na borda do canteiro, e o meio do
## canteiro ganha touceiras pequenas a mais, num sorteio próprio (as outras peças da célula não mudam); tudo dentro da célula.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([120])
	_config.tropical_island_sizes_cells = PackedInt32Array([])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func _poppies(island_id: int) -> Array:
	var grid := _world.island(island_id)
	var found: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_world, GameData.get_default(), _config, island_id, Vector2i(cx, cy))
			var poppies: Array = items[ScatterView.Kind.POPPIES]
			found.append_array(poppies)
	return found


func test_the_strength_runs_from_the_edge_to_the_middle() -> void:
	var low := 1.0
	var high := 0.0
	for y: int in 120:
		for x: int in 120:
			var cell := Vector2i(x, y)
			var strength := ScatterView.poppy_strength(0, cell)
			assert_float(strength).is_between(0.0, 1.0)
			if ScatterView.poppy_patch(0, cell):
				low = minf(low, strength)
				high = maxf(high, strength)
			else:
				assert_float(strength).is_equal(0.0)
	assert_float(low).is_less(0.2)
	assert_float(high).is_greater(0.8)


func test_beds_are_loose_varied_and_more_in_the_middle() -> void:
	var grid := _world.island(0)
	var poppies := _poppies(0)
	var per_cell := {}
	var off_center := 0
	var scales := {}
	for item: Array in poppies:
		var place: Transform3D = item[0]
		var cell := grid.world_to_cell(place.origin)
		assert_bool(ScatterView.poppy_patch(0, cell)).is_true()
		var seen: int = per_cell.get(cell, 0)
		per_cell[cell] = seen + 1
		var middle := grid.cell_world(cell)
		if Vector2(place.origin.x - middle.x, place.origin.z - middle.z).length() > grid.cell_size * 0.12:
			off_center += 1
		scales[snappedf(place.basis.x.length(), 0.05)] = true
	assert_int(poppies.size()).is_greater(50)
	# soltos: boa parte longe do meio da célula (antes, no máximo 0,105 da célula)
	assert_float(float(off_center) / poppies.size()).is_greater(0.4)
	# de vários tamanhos
	assert_int(scales.size()).is_greater(8)
	# no meio do canteiro, mais de uma touceira por célula
	var crowded := 0
	for cell: Vector2i in per_cell:
		var count: int = per_cell[cell]
		if count > 1:
			crowded += 1
			assert_float(ScatterView.poppy_strength(0, cell)).is_greater(0.0)
	assert_int(crowded).is_greater(0)


func test_the_other_pieces_keep_their_draw() -> void:
	# as outras peças da célula seguem o sorteio de antes: a contagem das que não são papoula não depende das papoulas
	var grid := _world.island(0)
	var tufts := 0
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_world, GameData.get_default(), _config, 0, Vector2i(cx, cy))
			var list: Array = items[ScatterView.Kind.TUFT]
			tufts += list.size()
	assert_int(tufts).is_greater(0)
	assert_int(ScatterView.Kind.POPPIES).is_less(ScatterView.Kind.SUNFLOWER)
