extends GdUnitTestSuite
## Cor no jeito do Anno (Fase 53): grama verde e saturada, areia clara, rocha escura, folhas mais vivas, água turquesa
## junto à costa, menos névoa de longe e, no v3, nada de praia desenhada em cima da falésia.


func test_the_terrain_grades_grass_green_sand_light_and_rock_dark() -> void:
	var code := (load("res://shaders/terrain.gdshader") as Shader).code
	for line: String in ["uniform vec3 grass_grade", "uniform float grass_saturation", "uniform float dry_strength",
			"uniform vec3 sand_grade", "uniform vec3 rock_grade", "grass_a.rgb *= grass_grade", "rock_a.rgb *= rock_grade",
			"sand_a.rgb *= sand_grade"]:
		assert_str(code).override_failure_message(line).contains(line)


func test_leaves_are_greener_than_before() -> void:
	# antes da Fase 53: carvalho (0.24, 0.35, 0.14), faia (0.33, 0.45, 0.17), pinheiro (0.15, 0.27, 0.15)
	assert_float(TreeModel.OAK_LEAF.g).is_greater(0.35)
	assert_float(TreeModel.BEECH_LEAF.g).is_greater(0.45)
	assert_float(TreeModel.PINE_NEEDLE.g).is_greater(0.27)
	for leaf: Color in [TreeModel.OAK_LEAF, TreeModel.BEECH_LEAF, TreeModel.PINE_NEEDLE]:
		assert_float(leaf.g).is_greater(leaf.r)
		assert_float(leaf.g).is_greater(leaf.b)


func test_the_haze_is_lighter() -> void:
	var config := GameConfig.get_default()
	assert_float(config.sky_fog_density).is_less_equal(0.0002)
	assert_float(config.volumetric_fog_density).is_less_equal(0.0018)


func test_the_shelf_water_is_turquoise() -> void:
	var source := (load("res://world/water/water_view.gd") as GDScript).source_code
	assert_str(source).contains("&\"color_shelf\", Color(0.24, 0.76, 0.72")
	var turquoise := Color(0.24, 0.76, 0.72)
	assert_float(turquoise.g).is_greater(turquoise.r * 2.5)


func test_no_beach_is_drawn_on_top_of_a_v3_cliff() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([120])
	config.tropical_island_sizes_cells = PackedInt32Array()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data, -1, -1, 3)
	var region := ArchipelagoGenerator.region_corners(world, 0, config, data)
	var heights: PackedFloat32Array = region["heights"]
	var surface: PackedByteArray = region["surface"]
	var high_sand := 0
	var high_land := 0
	for i: int in heights.size():
		if heights[i] > ArchipelagoGenerator.CLIFF_SAND_MAX_M + 0.5:
			high_land += 1
			if surface[i] == ArchipelagoGenerator.Surface.SAND:
				high_sand += 1
	assert_int(high_land).is_greater(100)
	assert_int(high_sand).is_equal(0)
