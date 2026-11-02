extends GdUnitTestSuite
## Tapete de capim (Fase 286): o tufo de folhas finas, escuras no pé e claras na ponta; só no capim livre (sem árvore, prédio,
## estrada, praia, margem do rio nem encosta); os blocos em volta do ponto da câmera, refeitos aos poucos e soltos quando saem do
## raio; uma obra marca o bloco e o refaz sem tufo no lote; escondido sem câmera perto; o shader compila (com tela).

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([140])
	_config.tropical_island_sizes_cells = PackedInt32Array([])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


## A célula de capim livre com as vizinhas a duas células também livres, mais perto do meio da ilha.
func _meadow(grid: IslandGrid) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := INF
	for y: int in range(4, grid.size.y - 4):
		for x: int in range(4, grid.size.x - 4):
			var cell := Vector2i(x, y)
			var score := Vector2(cell - grid.size / 2).length()
			if score >= best_score:
				continue
			var open := true
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if not GrassCarpetView.grows_at(grid, cell + Vector2i(dx, dy)):
						open = false
			if open:
				best_score = score
				best = cell
	return best


func test_the_tuft_is_thin_blades_dark_at_the_foot() -> void:
	var mesh := GrassCarpetView.tuft_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	# as folhas e (Fase 287) as pétalas da flor
	assert_int(vertices.size()).is_equal((GrassCarpetView.BLADES + GrassCarpetView.FLOWER_PETALS) * 3)
	var box := mesh.get_aabb()
	assert_float(box.end.y).is_between(GrassCarpetView.BLADE_HEIGHT_M.y * 0.9, GrassCarpetView.BLADE_HEIGHT_M.y + 0.01)
	assert_float(box.position.y).is_greater_equal(-0.001)
	for i: int in vertices.size():
		if vertices[i].y < 0.01:
			assert_float(colors[i].get_luminance()).is_less(GrassCarpetView.TIP_COLOR.get_luminance())


func test_the_carpet_grows_only_on_free_grass() -> void:
	var grid := _sim.world.island(0)
	var free := 0
	for index: int in grid.ground.size():
		var cell := grid.cell_at(index)
		if not GrassCarpetView.grows_at(grid, cell):
			continue
		free += 1
		assert_int(grid.ground[index]).is_equal(IslandGrid.Ground.LAND)
		assert_int(grid.trees[index]).is_equal(0)
		assert_int(grid.occupancy[index]).is_equal(0)
		assert_int(grid.roads[index]).is_equal(0)
		assert_float(grid.area_relief(Rect2i(cell, Vector2i.ONE))).is_less_equal(GrassCarpetView.MAX_RELIEF_M)
		# nada de mar a três células (a praia)
		for dy: int in range(-3, 4):
			for dx: int in range(-3, 4):
				assert_int(grid.ground_at(cell + Vector2i(dx, dy))).is_not_equal(IslandGrid.Ground.SEA)
	assert_int(free).is_greater(100)


func test_the_tufts_stay_in_their_cell_on_the_ground() -> void:
	var grid := _sim.world.island(0)
	var cell := _meadow(grid)
	var places := GrassCarpetView.tufts(grid, 0, cell)
	assert_int(places.size()).is_equal(GrassCarpetView.TUFTS_PER_CELL)
	for place: Transform3D in places:
		assert_object(grid.world_to_cell(place.origin)).is_equal(cell)
		assert_float(place.origin.y).is_equal_approx(grid.height_at(place.origin.x, place.origin.z) - 0.02, 0.001)
	# o mesmo sorteio da mesma célula
	assert_bool(GrassCarpetView.tufts(grid, 0, cell)[0].is_equal_approx(places[0])).is_true()


func test_blocks_follow_the_focus_and_leave_the_lots() -> void:
	var grid := _sim.world.island(0)
	var cell := _meadow(grid)
	assert_object(cell).is_not_equal(Vector2i(-1, -1))
	var view: GrassCarpetView = auto_free(GrassCarpetView.new())
	add_child(view)
	view.setup(_sim)
	view.set_process(false)
	view.focus_override = grid.cell_world(cell)
	var started := Time.get_ticks_usec()
	view.refresh(1000)
	print("tapete: %d blocos em %.1f ms" % [view.block_count(), (Time.get_ticks_usec() - started) / 1000.0])
	var wanted := GrassCarpetView.wanted_blocks(_sim.world, Vector2(view.focus_override.x, view.focus_override.z), view.radius_m)
	assert_int(view.block_count()).is_equal(wanted.size())
	assert_int(view.tuft_count()).is_greater(500)
	# aos poucos: um orçamento pequeno faz um bloco por vez
	view.clear()
	view.refresh(2)
	assert_int(view.block_count()).is_equal(2)
	view.refresh(1000)
	# uma casa no meio do prado: o bloco é refeito sem tufo no lote
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"house", cell, 0)).ok()).is_true()
	view.refresh(1000)
	var lot := Rect2i(cell, Vector2i(2, 2))
	for places: Array in view.block_places.values():
		for place: Transform3D in places:
			assert_bool(lot.has_point(grid.world_to_cell(place.origin))).is_false()
	# o foco longe: os blocos de antes saem
	view.focus_override = grid.cell_world(Vector2i(2, 2)) + Vector3(-2000.0, 0.0, -2000.0)
	view.refresh(1000)
	assert_int(view.block_count()).is_equal(0)


func test_hidden_without_a_close_camera() -> void:
	var view: GrassCarpetView = auto_free(GrassCarpetView.new())
	add_child(view)
	view.setup(_sim)
	view.set_process(false)
	view.refresh(10)
	# sem câmera na cena de teste (ou com ela alta demais) o tapete some
	if get_viewport().get_camera_3d() == null:
		assert_bool(view.visible).is_false()


func test_the_shader_compiles_with_its_uniforms() -> void:
	var shader := load("res://shaders/grass_carpet.gdshader") as Shader
	var names: Array[String] = []
	for uniform: Dictionary in shader.get_shader_uniform_list():
		var uniform_name: String = uniform["name"]
		names.append(uniform_name)
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for wanted: String in ["sway_calm", "sway_wind", "fade_from_m", "fade_to_m", "meadow_patch_m", "tall_tint", "short_tint"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
