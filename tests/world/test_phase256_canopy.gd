extends GdUnitTestSuite
## Copas verdes (Fase 256): folhas mais claras, o alto da copa puxando para o amarelo do sol e a luz própria das folhas de dia,
## que some à noite (sem ela o lado da sombra de uma mata fechada ficava quase preto).


func test_leaves_are_lighter_than_in_phase_53() -> void:
	# na Fase 53: carvalho 0,5, faia 0,6 e pinheiro 0,38 de verde
	assert_float(TreeModel.OAK_LEAF.g).is_greater(0.5)
	assert_float(TreeModel.BEECH_LEAF.g).is_greater(0.6)
	assert_float(TreeModel.PINE_NEEDLE.g).is_greater(0.38)
	assert_float(TreeModel.CROWN_SHADE).is_greater(0.74)
	# o sol do alto da copa é amarelo: mais vermelho que azul, sem apagar o verde
	assert_float(TreeModel.CROWN_SUN.r).is_greater(TreeModel.CROWN_SUN.b)
	assert_float(TreeModel.CROWN_SUN.g).is_greater_equal(1.0)


func test_the_top_of_the_crown_is_yellower_than_the_bottom() -> void:
	var mesh := TreeModel.mesh(TreeModel.Species.OAK, 0)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var top := -INF
	var bottom := INF
	var top_ratio := 0.0
	var bottom_ratio := 0.0
	for i: int in vertices.size():
		var color := colors[i]
		if color.g < color.r * 1.05:
			continue
		var ratio := color.r / color.g
		if vertices[i].y > top:
			top = vertices[i].y
			top_ratio = ratio
		if vertices[i].y < bottom:
			bottom = vertices[i].y
			bottom_ratio = ratio
	assert_float(top_ratio).is_greater(bottom_ratio)


func test_the_leaves_light_themselves_only_with_the_sun_up() -> void:
	var code := (load("res://shaders/foliage.gdshader") as Shader).code
	# Fase 260: pela altura do sol, não mais pela noite
	for line: String in ["global uniform vec3 sun_direction", "uniform float leaf_fill = 0.0",
			"EMISSION = base * leaf_fill * leafy * smoothstep(0.0, 0.5, sun_direction.y)"]:
		assert_str(code).override_failure_message(line).contains(line)
	var material := TreeModel.mesh(TreeModel.Species.BEECH, 1).surface_get_material(0) as ShaderMaterial
	var fill: float = material.get_shader_parameter(&"leaf_fill")
	assert_float(fill).is_equal_approx(TreeModel.LEAF_FILL, 0.0001)
	assert_float(TreeModel.LEAF_FILL).is_between(0.1, 0.4)
