extends GdUnitTestSuite
## Árvores de quintal (Fase 105): o recheio põe macieiras pequenas nas células junto das casas, no meio da célula (a copa
## não chega à parede); só junto de casa; na ilha tropical a árvore de quintal vira bananeira.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _yard_trees(island_id: int) -> Array:
	var trees: Array = _all(island_id)[ScatterView.Kind.YARD_TREE]
	return trees


func _all(island_id: int) -> Dictionary:
	var grid := _sim.world.island(island_id)
	var merged: Dictionary = {}
	for kind: int in ScatterView.Kind.values():
		merged[kind] = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, island_id, Vector2i(cx, cy))
			for kind: int in items.keys():
				var list: Array = merged[kind]
				var found: Array = items[kind]
				list.append_array(found)
	return merged


## Casas numa fileira com uma célula livre entre elas, no lugar livre perto do meio da ilha principal.
func _houses() -> Array[int]:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"house", 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var ids: Array[int] = []
	_sim.ignore_terrain = true
	for i: int in 8:
		var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", origin + Vector2i(i * 4, 0), 0))
		if result.ok():
			ids.append(result.placed[0])
	_sim.ignore_terrain = false
	return ids


func test_yard_trees_grow_beside_houses_in_the_middle_of_the_cell() -> void:
	var before := _yard_trees(0).size()
	var ids := _houses()
	assert_int(ids.size()).is_greater(4)
	var grid := _sim.world.island(0)
	var trees := _yard_trees(0)
	assert_int(trees.size()).is_greater(before)
	for item: Array in trees:
		var place: Transform3D = item[0]
		var cell := grid.world_to_cell(place.origin)
		# no meio da célula (folga do sorteio) e numa célula livre encostada numa casa
		var middle := grid.cell_world(cell)
		assert_float(Vector2(place.origin.x - middle.x, place.origin.z - middle.z).length()).is_less(0.2)
		assert_int(grid.occupancy[grid.index(cell)]).is_equal(0)
		var beside_house := false
		for side: Vector2i in ScatterView.SIDES:
			var other := cell + side
			if grid.in_bounds(other):
				var building := grid.occupancy[grid.index(other)]
				if building != 0 and _sim.world.building(building).is_house():
					beside_house = true
		assert_bool(beside_house).is_true()
		# a copa não passa do raio dela
		assert_float(place.basis.get_scale().x).is_less_equal(1.0)


func test_the_crown_stays_off_the_wall() -> void:
	var mesh := ScatterView.piece_mesh(ScatterView.Kind.YARD_TREE)
	var box := mesh.get_aabb()
	# meia célula (1 m) menos a folga da parede (0,15 m) e o desvio do meio da célula
	assert_float(maxf(absf(box.position.x), absf(box.end.x))).is_less(0.8)
	assert_float(maxf(absf(box.position.z), absf(box.end.z))).is_less(0.8)
	assert_float(box.end.y).is_greater(2.0)


func test_tropical_islands_get_bananas_instead() -> void:
	for index: int in _sim.world.islands.size():
		if _sim.world.is_tropical(index, _sim.data) and not _sim.world.island(index).flat:
			assert_int(_yard_trees(index).size()).is_equal(0)
