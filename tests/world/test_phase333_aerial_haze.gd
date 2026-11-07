extends GdUnitTestSuite
## Ar de longe (Fase 333): a neblina atmosférica do Sky3D só começa a sky_fog_start_m da câmera (perto nada muda) e fica cheia em
## sky_fog_end_m, mais densa que a de antes: as ilhas do fundo clareiam e azulam. O domo recebe os três valores.


func test_the_haze_starts_far_and_is_thicker() -> void:
	var config := GameConfig.get_default()
	assert_array(Array(config.validate())).is_empty()
	assert_float(config.sky_fog_start_m).is_greater_equal(200.0)
	assert_float(config.sky_fog_end_m).is_greater(config.sky_fog_start_m * 4.0)
	assert_float(config.sky_fog_density).is_greater(0.0005)


func test_the_dome_gets_the_haze() -> void:
	var config := GameConfig.get_default()
	var sky: SkyAdapter = auto_free(SkyAdapter.new())
	add_child(sky)
	sky.setup(config, true)
	var dome: Node = sky.get_child(0).get(&"sky")
	var start: float = dome.get(&"fog_start")
	var end: float = dome.get(&"fog_end")
	var density: float = dome.get(&"fog_density")
	assert_float(start).is_equal_approx(config.sky_fog_start_m, 0.01)
	assert_float(end).is_equal_approx(config.sky_fog_end_m, 0.01)
	assert_float(density).is_equal_approx(config.sky_fog_density, 0.000001)
