extends GdUnitTestSuite
## Orla da mata (Fase 278): a árvore nova só nas células de mata temperada que dão para o campo, em boa parte delas, pequena,
## puxada para o lado aberto sem sair da própria célula, e de abeto, bétula ou folhosa; nenhuma no miolo da mata nem na ilha
## tropical.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


## Se a célula de mata dá para o campo (um lado de terra sem árvore).
func _is_edge(grid: IslandGrid, cell: Vector2i) -> bool:
	for side: Vector2i in TreeView.SIDES:
		var other := cell + side
		if grid.in_bounds(other) and grid.trees[grid.index(other)] == 0 and grid.ground[grid.index(other)] == IslandGrid.Ground.LAND:
			return true
	return false


func test_young_trees_line_the_edge_of_the_temperate_forest() -> void:
	var grid := _sim.world.island(0)
	var edges := 0
	var young := 0
	var kinds := {}
	for index: int in grid.trees.size():
		if grid.trees[index] == 0:
			continue
		var cell := grid.cell_at(index)
		var entry := TreeView.young_entry(grid, 0, cell)
		var edge := _is_edge(grid, cell)
		if edge:
			edges += 1
		if entry.is_empty():
			continue
		# só na beira
		assert_bool(edge).is_true()
		young += 1
		var model: int = entry[0]
		kinds[model] = true
		assert_int(model).is_less(TreeView.BROADLEAF.size() + 2)
		var floats: PackedFloat32Array = entry[1]
		# pequena: a escala é o comprimento da primeira coluna da base
		var scale := Vector3(floats[0], floats[4], floats[8]).length()
		assert_float(scale).is_between(TreeView.YOUNG_SCALE.x - 0.01, TreeView.YOUNG_SCALE.y + 0.01)
		# dentro da própria célula
		assert_object(grid.world_to_cell(Vector3(floats[3], 0.0, floats[11]))).is_equal(cell)
	assert_int(edges).is_greater(50)
	var share := float(young) / edges
	assert_float(share).is_between(TreeView.YOUNG_CHANCE - 0.12, TreeView.YOUNG_CHANCE + 0.12)
	# abetos, bétulas e outras folhosas
	var spruce := false
	var birch := false
	var other := false
	for model: int in kinds:
		if model >= TreeView.BROADLEAF.size():
			spruce = true
		elif model >= 4:
			birch = true
		else:
			other = true
	assert_bool(spruce and birch and other).is_true()


func test_the_young_tree_leans_to_the_open_side() -> void:
	var grid := _sim.world.island(0)
	var checked := 0
	for index: int in grid.trees.size():
		if grid.trees[index] == 0 or checked >= 40:
			continue
		var cell := grid.cell_at(index)
		var entry := TreeView.young_entry(grid, 0, cell)
		if entry.is_empty():
			continue
		var open := Vector2.ZERO
		for side: Vector2i in TreeView.SIDES:
			var other := cell + side
			if grid.in_bounds(other) and grid.trees[grid.index(other)] == 0 and grid.ground[grid.index(other)] == IslandGrid.Ground.LAND:
				open += Vector2(side)
		if open == Vector2.ZERO:
			continue
		var floats: PackedFloat32Array = entry[1]
		var middle := grid.cell_world(cell)
		var offset := Vector2(floats[3] - middle.x, floats[11] - middle.z)
		# na média, para o lado aberto (o sorteio dentro da célula ainda mexe)
		checked += 1
		assert_float(offset.dot(open.normalized())).is_greater(-0.6)
	assert_int(checked).is_greater(10)


## O miolo da mata fica sem árvore nova. A ilha tropical também: a vista só chama a orla nas temperadas, e o
## `test_phase276_crowns.gd` confere que as malhas temperadas desenhadas são exatamente as das ilhas temperadas.
func test_no_young_trees_inside_the_forest() -> void:
	var grid := _sim.world.island(0)
	var inside := 0
	for index: int in grid.trees.size():
		if grid.trees[index] > 0 and not _is_edge(grid, grid.cell_at(index)):
			inside += 1
			assert_bool(TreeView.young_entry(grid, 0, grid.cell_at(index)).is_empty()).is_true()
	assert_int(inside).is_greater(0)
