extends GdUnitTestSuite
## Luz e cor de época (Fase 37): a gradação de época (LUT gerado no código) ergue o preto, esquenta os realces, esfria
## as sombras e contém verdes e azuis; o Environment só a recebe com a opção ligada e volta ao de antes ao desligar;
## SSR e o sol com tamanho (PCSS) ficam só no ultra; a opção é gravada nas preferências.

const SettingsScript := preload("res://core/settings.gd")
const TEST_PATH := "user://test_phase37_settings.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(TEST_PATH)


func test_grade_lifts_black_warms_highlights_and_cools_shadows() -> void:
	var black := PeriodGrade.grade(Color.BLACK)
	assert_float(black.r).is_greater(0.0)
	assert_float(black.r).is_less(0.05)
	# sombra puxada para o frio, realce para o âmbar
	assert_float(black.b).is_greater(black.r)
	var white := PeriodGrade.grade(Color.WHITE)
	assert_float(white.b).is_less(white.r)
	# o cinza do meio continua quase cinza: não vira sépia
	var gray := PeriodGrade.grade(Color(0.5, 0.5, 0.5))
	assert_float(absf(gray.r - gray.b)).is_less(0.05)


func test_grade_quiets_greens_and_blues_but_not_reds() -> void:
	var green := Color(0.25, 0.6, 0.2)
	var blue := Color(0.2, 0.35, 0.7)
	var red := Color(0.7, 0.25, 0.2)
	assert_float(PeriodGrade.grade(green).s).is_less(green.s)
	assert_float(PeriodGrade.grade(blue).s).is_less(blue.s)
	assert_float(PeriodGrade.grade(red).s).is_greater(red.s * 0.95)


func test_lut_is_33_cubed() -> void:
	var lut := PeriodGrade.texture()
	assert_object(lut).is_not_null()
	assert_int(lut.get_width()).is_equal(PeriodGrade.SIZE)
	assert_int(lut.get_height()).is_equal(PeriodGrade.SIZE)
	assert_int(lut.get_depth()).is_equal(PeriodGrade.SIZE)


func test_environment_gets_the_grade_only_when_the_option_is_on() -> void:
	var config := GameConfig.get_default()
	var preset := config.graphics_presets[2]
	var environment := Environment.new()
	var untouched := Environment.new()
	GraphicsQuality.apply_to_environment(environment, preset, config, true)
	assert_bool(environment.adjustment_enabled).is_true()
	assert_object(environment.adjustment_color_correction).is_same(PeriodGrade.texture())
	assert_float(environment.tonemap_agx_white).is_equal_approx(config.period_agx_white, 0.0001)
	assert_float(environment.tonemap_agx_contrast).is_equal_approx(config.period_agx_contrast, 0.0001)
	# desligada, tudo volta ao que era antes da fase
	GraphicsQuality.apply_to_environment(environment, preset, config, false)
	assert_bool(environment.adjustment_enabled).is_false()
	assert_object(environment.adjustment_color_correction).is_null()
	assert_float(environment.tonemap_agx_white).is_equal(untouched.tonemap_agx_white)
	assert_float(environment.tonemap_agx_contrast).is_equal(untouched.tonemap_agx_contrast)


func test_ssr_and_soft_sun_only_on_ultra() -> void:
	var config := GameConfig.get_default()
	var last := config.graphics_presets.size() - 1
	for index: int in config.graphics_presets.size():
		var preset := config.graphics_presets[index]
		assert_array(Array(preset.validate())).is_empty()
		var environment := Environment.new()
		GraphicsQuality.apply_to_environment(environment, preset, config)
		assert_bool(environment.ssr_enabled).is_equal(index == last)
		assert_bool(preset.sun_angular_distance_deg > 0.0).is_equal(index == last)
	# no ultra o SSR é na resolução cheia
	assert_bool(config.graphics_presets[last].ssr_half_size).is_false()


func test_period_look_is_saved_and_off_by_default() -> void:
	var settings: SettingsScript = auto_free(SettingsScript.new())
	settings.load_from("user://nao_existe.cfg")
	assert_bool(settings.period_look).is_false()
	settings.period_look = true
	assert_int(settings.save_to(TEST_PATH)).is_equal(OK)
	var other: SettingsScript = auto_free(SettingsScript.new())
	other.load_from(TEST_PATH)
	assert_bool(other.period_look).is_true()
