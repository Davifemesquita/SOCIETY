extends GdUnitTestSuite
## Lanterna nas carroças (Fase 209): a lanterna vai na malha do corpo da carroça (a mesma instância); fica no
## canto da frente, acima da caçamba e à frente dela, e o vidro usa o material dos lampiões (aceso pelo night_light).

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(140, 40), 50, true)
	SimFixture.port(_sim)


func test_the_lantern_rides_in_the_body_mesh() -> void:
	var body := CartView.model_mesh()
	var merged := CartView.with_lantern(body)
	# o corpo, a armação e o vidro: a lanterna anda na mesma instância, sem camada a mais
	assert_int(merged.get_surface_count()).is_equal(body.get_surface_count() + 2)
	var glass := merged.surface_get_material(merged.get_surface_count() - 1) as ShaderMaterial
	assert_object(glass).is_not_null()
	assert_str(glass.shader.resource_path).is_equal("res://shaders/night_glow.gdshader")
	# o vidro marcado pelo alfa 0 do vértice (a chama do night_glow é 1)
	var colors: PackedColorArray = merged.surface_get_arrays(merged.get_surface_count() - 1)[Mesh.ARRAY_COLOR]
	for color: Color in colors:
		assert_float(color.a).is_equal(0.0)
	var view: CartView = auto_free(CartView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	assert_int(view._bodies.multimesh.mesh.get_surface_count()).is_equal(merged.get_surface_count())


func test_the_lantern_hangs_in_front_of_the_bed() -> void:
	var lantern := CartView.lantern_mesh().get_aabb()
	var cart := CartView.model_mesh().get_aabb()
	# à frente da caçamba (o −z do modelo, para o lado do cavalo: a frente dela fica onde a lona começa), atrás da ponta dos
	# varais, acima da caçamba e dentro da largura
	assert_float(CartView.LANTERN_AT.z).is_less(CartView.CANVAS_CENTER_Z - CartView.CANVAS_HALF_M)
	assert_float(lantern.position.z).is_greater(cart.position.z)
	assert_float(lantern.end.y).is_greater(CartView.BED_M - CartView.HEIGHT_M + 0.5)
	assert_float(absf(CartView.LANTERN_AT.x)).is_less(maxf(absf(cart.position.x), absf(cart.end.x)))
	var glass := CartView.lantern_glass_mesh()
	assert_bool(glass.surface_get_material(0) is ShaderMaterial).is_true()
	var shader := (glass.surface_get_material(0) as ShaderMaterial).shader
	assert_str(shader.resource_path).is_equal("res://shaders/night_glow.gdshader")
	assert_bool(glass.get_aabb().has_point(CartView.LANTERN_AT)).is_true()
