extends GdUnitTestSuite
## Malha fina na face da falésia (Fase 62): o quadrado seco com desnível de terrain_cliff_refine_relief_m ou mais vira
## subgrade como o da costa, os cantos da grade não mudam, a borda com um quadrado comum fica reta, a aspereza de rocha
## mexe nos pontos novos sem sair dos cantos que pesam nem da folga da reta, e nada muda no plano nem na encosta suave.

const SIDE := 12
const N := 3


## Planalto de 7 m (x até 4), falésia até um patamar de 1 m (x de 5 em diante), e mar nas duas últimas colunas.
func _cliff() -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			var h := 7.0 if x <= 4 else 1.0
			if x >= SIDE - 2:
				h = -3.0
			heights[y * SIDE + x] = h + 0.05 * y
	return heights


func _view(relief: float) -> TerrainView:
	var view: TerrainView = auto_free(TerrainView.new())
	var config := GameConfig.new()
	config.terrain_cliff_refine_relief_m = relief
	view.set(&"_config", config)
	return view


func _count(heights: PackedFloat32Array, relief: float) -> int:
	var refined := 0
	for y: int in SIDE - 1:
		for x: int in SIDE - 1:
			if CoastRefine.refines(heights, SIDE, x, y, relief):
				refined += 1
	return refined


func test_dry_cliff_quads_are_refined_and_the_rest_are_not() -> void:
	var heights := _cliff()
	var config := GameConfig.new()
	var relief := config.terrain_cliff_refine_relief_m
	var steep := 0
	for y: int in SIDE - 1:
		for x: int in SIDE - 1:
			if CoastRefine.steep(heights, SIDE, x, y, relief):
				steep += 1
				# só a coluna da falésia (do canto 4 ao 5)
				assert_int(x).is_equal(4)
	assert_int(steep).is_equal(SIDE - 1)
	var plain: ArrayMesh = _view(0.0).call(&"_chunk_mesh", heights, SIDE, Vector2.ZERO, 0, 0)
	var fine: ArrayMesh = _view(relief).call(&"_chunk_mesh", heights, SIDE, Vector2.ZERO, 0, 0)
	var plain_indices: PackedInt32Array = plain.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var fine_indices: PackedInt32Array = fine.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	# com a falésia desligada, só a costa se divide; ligada, a face também (cada uma troca 2 triângulos por 18)
	assert_int(fine_indices.size() / 3 - plain_indices.size() / 3).is_equal((_count(heights, relief) - _count(heights, 0.0)) * 16)


func test_the_threshold_stays_above_the_steepest_road() -> void:
	var config := GameConfig.new()
	assert_float(config.terrain_cliff_refine_relief_m).is_greater(config.max_road_relief_m)
	assert_array(config.validate()).is_empty()
	config.terrain_cliff_refine_relief_m = config.max_road_relief_m
	assert_array(config.validate()).is_not_empty()
	config.terrain_cliff_refine_relief_m = 0.0
	assert_array(config.validate()).is_empty()
	# um quadrado com o desnível da estrada mais íngreme nunca se divide
	var heights := PackedFloat32Array([1.0, 1.0 + config.max_road_relief_m, 1.0, 1.0 + config.max_road_relief_m])
	assert_bool(CoastRefine.steep(heights, 2, 0, 0, GameConfig.new().terrain_cliff_refine_relief_m)).is_false()


func test_rough_points_stay_inside_the_corners_and_the_slack() -> void:
	var heights := _cliff()
	var config := GameConfig.new()
	var relief := config.terrain_cliff_refine_relief_m
	var rough := config.terrain_cliff_rough_m
	var max_m := config.terrain_coast_refine_max_m
	var moved := 0
	for y: int in SIDE - 1:
		var x := 4
		for j: int in N + 1:
			for i: int in N + 1:
				var sx := x * N + i
				var sy := y * N + j
				var smooth := CoastRefine.height(heights, SIDE, sx, sy, N, max_m, false)
				var rocky := CoastRefine.height(heights, SIDE, sx, sy, N, max_m, false, rough, relief)
				var straight := CoastRefine.height(heights, SIDE, sx, sy, N, max_m, true)
				if (i == 0 or i == N) and (j == 0 or j == N):
					# canto da grade: a altura da simulação
					assert_float(rocky).is_equal(heights[(y + j / N) * SIDE + x + i / N])
					continue
				if absf(rocky - smooth) > 0.01:
					moved += 1
				assert_float(rocky).is_between(1.0 - 0.001, 7.0 + 0.05 * SIDE + 0.001)
				assert_float(absf(rocky - straight)).is_less_equal(max_m + 0.0001)
	assert_int(moved).is_greater(SIDE)


func test_flat_land_and_gentle_slopes_do_not_change() -> void:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			heights[y * SIDE + x] = 2.0 + 0.3 * x
	var relief := GameConfig.new().terrain_cliff_refine_relief_m
	assert_int(_count(heights, relief)).is_equal(0)
	var with_cliff: ArrayMesh = _view(relief).call(&"_chunk_mesh", heights, SIDE, Vector2.ZERO, 0, 0)
	var without: ArrayMesh = _view(0.0).call(&"_chunk_mesh", heights, SIDE, Vector2.ZERO, 0, 0)
	var a: PackedVector3Array = with_cliff.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var b: PackedVector3Array = without.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_bool(a == b).is_true()
