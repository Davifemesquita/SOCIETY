extends GdUnitTestSuite
## O que a tela mostra do mundo gerado (seção 7): o terreno desenhado na altura que a simulação
## usa, as árvores da grade (e as que a construção derrubou somem), e a água turva perto de
## prédio poluidor.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(5, _config, GameData.get_default()))
	_sim.free_build = true


func test_terrain_mesh_sits_on_the_simulation_heights() -> void:
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(_sim.world, _config, _sim.data)
	assert_int(view.chunk_count()).is_greater(0)
	var grid := _sim.world.island(0)
	var checked := 0
	for child: Node in view.get_children():
		var mesh := (child as MeshInstance3D).mesh as ArrayMesh
		var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex: Vector3 in vertices:
			var cell := grid.world_to_cell(vertex)
			if grid.in_bounds(cell) and grid.in_bounds(cell - Vector2i.ONE):
				var simulated := grid.height_at(vertex.x, vertex.z)
				if simulated >= 0.0:
					assert_float(vertex.y).is_equal_approx(simulated, 0.001)
					checked += 1
				else:
					# no mar o fundo desenhado só desce
					assert_float(vertex.y).is_between(_config.deep_sea_floor_m - 0.001, simulated + 0.001)
	assert_int(checked).is_greater(1000)


## O fundo do mar desenhado desce até o fundo profundo na borda da região (sem degrau contra o mar
## aberto, onde não há terreno) e longe da costa; o rio, dentro da ilha, fica como a simulação.
func test_drawn_sea_floor_reaches_the_deep_floor_without_touching_rivers() -> void:
	for index: int in _sim.world.islands.size():
		var grid := _sim.world.island(index)
		var region := ArchipelagoGenerator.region_corners(_sim.world, index, _config, _sim.data)
		var side: int = region["side"]
		var origin: Vector2 = region["origin"]
		var heights: PackedFloat32Array = region["heights"]
		for k: int in side:
			for corner: Vector2i in [Vector2i(k, 0), Vector2i(0, k), Vector2i(k, side - 1), Vector2i(side - 1, k)]:
				assert_float(heights[corner.y * side + corner.x]).is_equal_approx(_config.deep_sea_floor_m, 0.01)
		var first := Vector2i(((grid.origin_m - origin) / _config.cell_size_m).round())
		var rivers := 0
		for i: int in grid.ground.size():
			if grid.ground[i] != IslandGrid.Ground.RIVER:
				continue
			var cell := grid.cell_at(i)
			var corner := first + cell + Vector2i.ONE
			assert_float(heights[corner.y * side + corner.x]).is_equal_approx(grid.corner_height(cell.x + 1, cell.y + 1), 0.05)
			rivers += 1
		if index == 0:
			assert_int(rivers).is_greater(0)


func test_trees_follow_the_grid_and_building_clears_them() -> void:
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(_sim.world)
	var before := view.instance_count()
	assert_int(before).is_greater(0)
	var grid := _sim.world.island(0)
	var forest: Array[Vector2i] = []
	for i: int in grid.trees.size():
		if grid.trees[i] > 0 and PlacementRules.check_road_cell(grid, grid.cell_at(i), _config) == PlacementRules.OK:
			forest.append(grid.cell_at(i))
			if forest.size() == 10:
				break
	for cell: Vector2i in forest:
		var one: Array[Vector2i] = [cell]
		_sim.execute(BuildRoadCommand.new(0, one))
	assert_int(view.instance_count()).is_less(before)


func test_polluting_building_clouds_the_water_around_it() -> void:
	var water: WaterView = auto_free(WaterView.new())
	add_child(water)
	water.setup(_sim)
	var grid := _sim.world.island(0)
	var site := SiteFinder.find(_sim, &"brickworks", 0, grid.size / 2, 60)
	assert_array(site).is_not_empty()
	var origin: Vector2i = site[0]
	var rotation: int = site[1]
	var center := grid.rect_world(Footprint.rect(origin, _sim.data.building(&"brickworks").size, rotation))
	assert_float(water.pollution_at(center.x, center.z)).is_equal(0.0)
	_sim.execute(PlaceBuildingCommand.new(0, &"brickworks", origin, rotation))
	assert_float(water.pollution_at(center.x, center.z)).is_greater(0.3)
	var far := grid.world_rect().end + Vector2(30.0, 30.0)
	assert_float(water.pollution_at(far.x, far.y)).is_equal(0.0)
