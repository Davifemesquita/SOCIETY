extends GdUnitTestSuite
## Costa lisa (Fase 54): a distância até a costa parte de onde a altura cruza o zero (não do meio da célula), a malha do
## terreno divide cada quadrado pela diagonal que segue o relevo, e a praia do shader sai dessa distância (contorno liso),
## nunca em cima da falésia nem na rocha.

const SIDE := 33
const SPACING := 2.0


func test_a_diagonal_coast_gets_a_true_distance_not_a_staircase() -> void:
	# costa reta a 30°: a altura é a distância com sinal até a reta (vezes 0,5), então o zero cai entre os cantos
	var normal := Vector2(cos(deg_to_rad(30.0)), sin(deg_to_rad(30.0)))
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			heights[y * SIDE + x] = (Vector2(x, y).dot(normal) - 16.3) * 0.5
	var coast := TerrainBake.signed_coast(heights, SIDE, SPACING, 64.0)
	var worst := 0.0
	for y: int in range(6, SIDE - 6):
		for x: int in range(6, SIDE - 6):
			var exact := (Vector2(x, y).dot(normal) - 16.3) * SPACING
			if absf(exact) > 12.0:
				continue
			worst = maxf(worst, absf(coast[y * SIDE + x] - exact))
	# o chanfro erra um pouco fora dos eixos; com a linha no meio da célula o erro chegava a uma célula inteira
	assert_float(worst).is_less(1.2)


func test_each_terrain_quad_follows_the_relief_diagonal() -> void:
	var view: TerrainView = auto_free(TerrainView.new())
	var config := GameConfig.new()
	# o quadrado comum: com 5 m de desnível ele viraria a subgrade da falésia (Fase 62)
	config.terrain_cliff_refine_relief_m = 0.0
	view.set(&"_config", config)
	# um quadrado com a crista em a–d e outro com a crista em b–c
	var heights := PackedFloat32Array([0.0, 5.0, 5.0, 0.0, 0.0, 5.0, 5.0, 0.0, 0.0])
	var mesh: ArrayMesh = view.call(&"_chunk_mesh", heights, 3, Vector2.ZERO, 0, 0)
	var indices: PackedInt32Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	# quadrado de cima à esquerda: cantos 0 (0 m), 1 (5 m), 3 (5 m), 4 (0 m); a diagonal 0–4 é a de menor diferença
	var first := Array(indices.slice(0, 6))
	assert_bool(first.has(0) and first.has(4) and first.count(0) == 2 and first.count(4) == 2).is_true()
	# quadrado de cima à direita: cantos 1 (5 m), 2 (5 m), 4 (0 m), 5 (5 m); |h1 − h5| = 0 < |h2 − h4| = 5, então a
	# diagonal é 1–5
	var second := Array(indices.slice(6, 12))
	assert_int(second.count(1)).is_equal(2)
	assert_int(second.count(5)).is_equal(2)


func test_the_beach_comes_from_the_coast_distance() -> void:
	var code := (load("res://shaders/terrain.gdshader") as Shader).code
	for line: String in ["uniform float beach_m", "uniform float beach_top_m", "float to_sea = texture(coast_distance, cell).r"]:
		assert_str(code).override_failure_message(line).contains(line)
