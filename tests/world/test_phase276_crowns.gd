extends GdUnitTestSuite
## Copas na medida (Fase 276): as folhosas e o pinheiro com a copa mais estreita, da mesma altura; na mata temperada uma árvore
## por célula e só em parte das células (vãos), na tropical as de antes; o tamanho mais variado; e o desenho batendo com a
## regra (os tocos da clareira saem dela também).

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func test_the_crowns_are_narrower_and_as_tall() -> void:
	var oak := TreeModel.mesh(TreeModel.Species.OAK, 0).get_aabb()
	var beech := TreeModel.mesh(TreeModel.Species.BEECH, 0).get_aabb()
	var pine := TreeModel.mesh(TreeModel.Species.SCOTS_PINE, 0).get_aabb()
	print("carvalho ", oak.size, ", faia ", beech.size, ", pinheiro ", pine.size)
	# eram ~7,8, ~5,8 e ~5 m de largura
	assert_float(maxf(oak.size.x, oak.size.z)).is_less(6.2)
	assert_float(maxf(beech.size.x, beech.size.z)).is_less(4.8)
	assert_float(maxf(pine.size.x, pine.size.z)).is_less(4.6)
	assert_float(oak.end.y).is_greater(6.0)
	assert_float(beech.end.y).is_greater(8.0)
	assert_float(pine.end.y).is_greater(9.0)


func test_part_of_the_temperate_cells_draw_one_tree_and_the_tropics_up_to_two() -> void:
	for island_id: int in _sim.world.islands.size():
		var grid := _sim.world.island(island_id)
		var tropical := _sim.world.is_tropical(island_id, _sim.data)
		var cells := 0
		var drawn := 0
		for index: int in grid.trees.size():
			var count := grid.trees[index]
			if count == 0:
				continue
			cells += 1
			var seeds := TreeView.drawn_seeds(island_id, index, count, tropical)
			drawn += seeds.size()
			if tropical:
				assert_int(seeds.size()).is_equal(mini(count, TreeView.DRAWN_PER_CELL))
			else:
				assert_int(seeds.size()).is_less_equal(TreeView.TEMPERATE_PER_CELL)
		if cells == 0:
			continue
		var share := float(drawn) / cells
		if tropical:
			assert_float(share).is_greater(1.0)
		else:
			assert_float(share).is_between(0.5, 0.8)


func test_the_size_spreads_wider() -> void:
	var low := INF
	var high := -INF
	for i: int in 1000:
		var scale := TreeView.tree_scale(hash([0, i, 0]))
		low = minf(low, scale)
		high = maxf(high, scale)
	assert_float(low).is_between(TreeView.SCALE_MIN, TreeView.SCALE_MIN + 0.02)
	assert_float(high).is_between(TreeView.SCALE_MIN + TreeView.SCALE_SPREAD - 0.02, TreeView.SCALE_MIN + TreeView.SCALE_SPREAD)
	assert_float(TreeView.SCALE_MIN).is_less(0.75)


func test_the_view_draws_what_the_rule_says() -> void:
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(_sim.world, _sim.data, _config)
	var temperate: Array[Mesh] = []
	for tree: Array in TreeView.BROADLEAF + TreeView.CONIFER:
		var species: TreeModel.Species = tree[0]
		var variant: int = tree[1]
		temperate.append(TreeModel.mesh(species, variant))
	var shown := 0
	for node: Node in view.get_children():
		var layer := node as MultiMeshInstance3D
		if layer != null and layer.multimesh.mesh in temperate:
			shown += layer.multimesh.instance_count
	var expected := 0
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			continue
		var grid := _sim.world.island(island_id)
		for index: int in grid.trees.size():
			if grid.trees[index] > 0:
				expected += TreeView.drawn_seeds(island_id, index, grid.trees[index], false).size()
				# Fase 278: e a árvore nova da orla
				if not TreeView.young_entry(grid, island_id, grid.cell_at(index)).is_empty():
					expected += 1
	assert_int(shown).is_equal(expected)
	assert_int(shown).is_greater(0)
