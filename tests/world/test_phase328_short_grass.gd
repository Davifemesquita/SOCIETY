extends GdUnitTestSuite
## Capim rente (Fase 328): o tapete de capim da Fase 286 tinha folhas de 0,4 a 0,75 m (até ~1,3 m no capim alto), do verde escuro
## ao verde-limão, que de perto se liam como fios espetados sobre o chão; agora é mais baixo, mais cerrado e no tom do capim do
## terreno.


func test_the_blades_are_short() -> void:
	assert_float(GrassCarpetView.BLADE_HEIGHT_M.y).is_less_equal(0.4)
	assert_float(GrassCarpetView.BLADE_HEIGHT_M.x).is_greater(0.1)
	var code := FileAccess.get_file_as_string("res://shaders/grass_carpet.gdshader")
	assert_str(code).contains("uniform float tall_height = 1.45;")
	# a folha mais alta do capim alto (o maior tufo é 1,25 vezes o modelo) fica abaixo de 0,7 m
	assert_float(GrassCarpetView.BLADE_HEIGHT_M.y * 1.45 * 1.25).is_less(0.7)


func test_the_carpet_is_denser() -> void:
	# antes: 8 tufos de 7 folhas por célula
	assert_int(GrassCarpetView.TUFTS_PER_CELL * GrassCarpetView.BLADES).is_greater_equal(8 * 7 * 2)
	assert_float(GrassCarpetView.BLADE_HALF_M).is_greater(0.04)


func test_the_blades_take_the_tone_of_the_ground() -> void:
	# a ponta era 0,5/0,68/0,22 (verde-limão, 2,5 vezes o pé); agora fica perto do pé e no matiz do capim do terreno
	var base := GrassCarpetView.BASE_COLOR
	var tip := GrassCarpetView.TIP_COLOR
	assert_float(tip.get_luminance()).is_greater(base.get_luminance())
	assert_float(tip.get_luminance() / base.get_luminance()).is_less(1.5)
	assert_float(tip.g).is_less(0.5)
	for color: Color in [base, tip]:
		assert_float(color.r / color.g).is_between(0.65, 0.85)
		assert_float(color.b / color.g).is_between(0.25, 0.4)


func test_the_flower_stands_above_the_blades() -> void:
	assert_float(GrassCarpetView.FLOWER_HEIGHT_M).is_greater(lerpf(GrassCarpetView.BLADE_HEIGHT_M.x, GrassCarpetView.BLADE_HEIGHT_M.y, 0.5))
	assert_float(GrassCarpetView.FLOWER_HEIGHT_M).is_less(GrassCarpetView.BLADE_HEIGHT_M.y)
