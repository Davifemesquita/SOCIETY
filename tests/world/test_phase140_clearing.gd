extends GdUnitTestSuite
## Clareira do lenhador (Fase 140): em volta do lenhador, parte das células de mata fica cortada no desenho (mais perto,
## mais cortada); a TreeView não desenha as árvores delas e a StumpView põe um toco por árvore e algumas toras; a ilha
## plana não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


## Origem de um lenhador no meio da mata mais cerrada da ilha principal (a área 3 × 3 dentro da grade).
func _forest_origin() -> Vector2i:
	var grid := _sim.world.island(0)
	var best := Vector2i(-1, -1)
	var best_trees := -1
	for y: int in range(6, grid.size.y - 9, 3):
		for x: int in range(6, grid.size.x - 9, 3):
			var trees := grid.trees_in(Rect2i(x, y, 3, 3).grow(5))
			if trees > best_trees:
				best_trees = trees
				best = Vector2i(x, y)
	return best


func test_the_cut_cells_ring_the_lumberjack_and_thin_out() -> void:
	var origin := _forest_origin()
	var id := SimFixture.place(_sim, &"lumberjack", origin)
	var record := _sim.world.building(id)
	var area := Footprint.rect(record.origin, Vector2i(3, 3), record.rotation)
	var grid := _sim.world.island(0)
	var cut := StumpView.cut_cells(_sim.world, _sim.data, _config, 0)
	assert_int(cut.size()).is_greater(0)
	var near := 0
	var far := 0
	for cell: Vector2i in cut:
		assert_int(cut[cell]).is_equal(id)
		assert_bool(area.has_point(cell)).is_false()
		assert_bool(area.grow(_config.lumberjack_radius_cells).has_point(cell)).is_true()
		assert_int(grid.trees[grid.index(cell)]).is_greater(0)
		if area.grow(2).has_point(cell):
			near += 1
		else:
			far += 1
	# os anéis de perto (16 + 24 células) cortam mais que os de longe (32 + 40 + 48), por célula
	assert_float(near / 40.0).is_greater(far / 120.0)


func test_the_trees_go_and_the_stumps_come() -> void:
	var trees: TreeView = auto_free(TreeView.new())
	add_child(trees)
	trees.setup(_sim.world, _sim.data, _config)
	var stumps: StumpView = auto_free(StumpView.new())
	add_child(stumps)
	stumps.setup(_sim)
	var before := trees.instance_count()
	var id := SimFixture.place(_sim, &"lumberjack", _forest_origin())
	# as duas esperam o quadro seguinte; aqui, já
	trees.flush()
	stumps.refresh()
	var cut := StumpView.cut_cells(_sim.world, _sim.data, _config, 0)
	var grid := _sim.world.island(0)
	var expected := 0
	for cell: Vector2i in cut:
		assert_bool(trees.is_cut(0, cell)).is_true()
		expected += mini(grid.trees[grid.index(cell)], TreeView.DRAWN_PER_CELL)
	# as árvores das células cortadas saíram do desenho (e as do lote, derrubadas pela obra)
	assert_int(before - trees.instance_count()).is_greater_equal(expected)
	assert_int(stumps.stump_count()).is_equal(expected)
	assert_int(stumps.log_count()).is_greater(0)
	# sem o lenhador, a mata volta
	_sim.execute(DemolishCommand.new(0, Footprint.rect(_sim.world.building(id).origin, Vector2i(3, 3), 0)))
	trees.flush()
	stumps.refresh()
	assert_int(stumps.stump_count()).is_equal(0)
	for cell: Vector2i in cut:
		assert_bool(trees.is_cut(0, cell)).is_false()


func test_other_buildings_leave_the_clearing_alone() -> void:
	var trees: TreeView = auto_free(TreeView.new())
	add_child(trees)
	trees.setup(_sim.world, _sim.data, _config)
	SimFixture.place(_sim, &"lumberjack", _forest_origin())
	trees.flush()
	# uma casa longe não marca trecho nenhum para refazer
	SimFixture.place(_sim, &"house", Vector2i(2, 2))
	assert_bool(trees._pending.is_empty()).is_true()


func test_the_flat_island_has_no_clearing() -> void:
	var flat := SimFixture.simulation()
	flat.free_build = true
	SimFixture.place(flat, &"lumberjack", Vector2i(20, 10))
	assert_int(StumpView.cut_cells(flat.world, flat.data, flat.config, 0).size()).is_equal(0)
