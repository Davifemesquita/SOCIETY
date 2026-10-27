extends GdUnitTestSuite
## Malha fina na linha d'água (Fase 55): só os quadrados que a costa atravessa viram subgrade, os cantos da grade não
## mudam, a borda comum sai igual dos dois lados (sem fresta), a borda com um quadrado comum fica na reta dele, e a costa
## curva fica mais perto do relevo de verdade do que a reta entre os cantos.

const SIDE := 12
const SPACING := 2.0


## Ilha redonda e lisa: a altura cai com o quadrado da distância ao centro (zero no raio 4 células).
func _round_island() -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			heights[y * SIDE + x] = _true_height(x, y)
	return heights


func _true_height(x: float, y: float) -> float:
	return 4.0 - 0.25 * (Vector2(x, y) - Vector2(5.3, 5.6)).length_squared()


func _view(subdivisions: int) -> TerrainView:
	var view: TerrainView = auto_free(TerrainView.new())
	var config := GameConfig.new()
	config.terrain_coast_subdivisions = subdivisions
	view.set(&"_config", config)
	return view


func test_only_quads_on_the_waterline_are_refined() -> void:
	var heights := _round_island()
	var crossing := 0
	for y: int in SIDE - 1:
		for x: int in SIDE - 1:
			if CoastRefine.crosses(heights, SIDE, x, y):
				crossing += 1
	assert_int(crossing).is_greater(0)
	var plain: ArrayMesh = _view(1).call(&"_chunk_mesh", heights, SIDE, Vector2.ZERO, 0, 0)
	var fine: ArrayMesh = _view(3).call(&"_chunk_mesh", heights, SIDE, Vector2.ZERO, 0, 0)
	var plain_indices: PackedInt32Array = plain.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var fine_indices: PackedInt32Array = fine.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var plain_triangles := plain_indices.size() / 3
	var fine_triangles := fine_indices.size() / 3
	assert_int(plain_triangles).is_equal((SIDE - 1) * (SIDE - 1) * 2)
	# cada quadrado da costa troca 2 triângulos por 3 × 3 × 2
	assert_int(fine_triangles).is_equal(plain_triangles + crossing * 16)


func test_grid_corners_keep_the_simulation_height() -> void:
	var heights := _round_island()
	for y: int in SIDE:
		for x: int in SIDE:
			assert_float(CoastRefine.height(heights, SIDE, x * 3, y * 3, 3, 0.8, false)).is_equal(heights[y * SIDE + x])


func test_a_shared_edge_has_no_gap() -> void:
	var heights := _round_island()
	for y: int in SIDE - 1:
		for x: int in SIDE - 2:
			if not (CoastRefine.crosses(heights, SIDE, x, y) and CoastRefine.crosses(heights, SIDE, x + 1, y)):
				continue
			# o mesmo ponto da borda pedido como lado direito de um quadrado e esquerdo do outro: a conta é a mesma
			for j: int in 4:
				var h := CoastRefine.height(heights, SIDE, (x + 1) * 3, y * 3 + j, 3, 0.8, false)
				var low := minf(heights[y * SIDE + x + 1], heights[mini(y + 1, SIDE - 1) * SIDE + x + 1])
				var high := maxf(heights[y * SIDE + x + 1], heights[mini(y + 1, SIDE - 1) * SIDE + x + 1])
				# só os dois cantos da borda limitam o ponto dela
				assert_float(h).is_between(low, high)


func test_an_edge_next_to_a_plain_quad_stays_straight() -> void:
	var heights := _round_island()
	var fine: ArrayMesh = _view(3).call(&"_chunk_mesh", heights, SIDE, Vector2.ZERO, 0, 0)
	var vertices: PackedVector3Array = fine.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var checked := 0
	for vertex: Vector3 in vertices:
		var gx := vertex.x / SPACING
		var gy := vertex.z / SPACING
		var on_x := is_equal_approx(gx, roundf(gx))
		var on_y := is_equal_approx(gy, roundf(gy))
		if on_x == on_y:
			continue
		# ponto no meio de uma borda vertical (x inteiro) ou horizontal (y inteiro)
		var a := Vector2i(roundi(gx), floori(gy)) if on_x else Vector2i(floori(gx), roundi(gy))
		var b := a + (Vector2i(0, 1) if on_x else Vector2i(1, 0))
		var left := a - (Vector2i(1, 0) if on_x else Vector2i(0, 1))
		var both := CoastRefine.crosses(heights, SIDE, left.x, left.y) and CoastRefine.crosses(heights, SIDE, a.x, a.y)
		if both:
			continue
		var t := (gy - a.y) if on_x else (gx - a.x)
		var straight := lerpf(heights[a.y * SIDE + a.x], heights[b.y * SIDE + b.x], t)
		assert_float(vertex.y).is_equal_approx(straight, 0.0001)
		checked += 1
	assert_int(checked).is_greater(0)


func test_the_curved_coast_follows_the_relief_better_than_the_straight_one() -> void:
	var heights := _round_island()
	var curved_error := 0.0
	var straight_error := 0.0
	for y: int in SIDE - 1:
		for x: int in SIDE - 1:
			if not CoastRefine.crosses(heights, SIDE, x, y):
				continue
			for j: int in range(1, 3):
				for i: int in range(1, 3):
					var truth := _true_height(x + i / 3.0, y + j / 3.0)
					var curved := CoastRefine.height(heights, SIDE, x * 3 + i, y * 3 + j, 3, 0.8, false)
					var straight := CoastRefine.height(heights, SIDE, x * 3 + i, y * 3 + j, 3, 0.8, true)
					curved_error += absf(curved - truth)
					straight_error += absf(straight - truth)
	assert_float(curved_error).is_less(straight_error * 0.5)


func test_the_config_checks_the_subdivisions() -> void:
	var config := GameConfig.new()
	assert_array(config.validate()).is_empty()
	config.terrain_coast_subdivisions = 0
	assert_array(config.validate()).is_not_empty()
