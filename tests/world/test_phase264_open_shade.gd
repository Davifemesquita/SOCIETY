extends GdUnitTestSuite
## Sombra aberta (Fase 264): a oclusão de ambiente (SSAO) mais leve, de 1,6 para 0,9: o vão entre as copas e o pé das matas
## deixam de ficar quase pretos. O nível que liga o SSAO recebe a força nova.


func test_the_ambient_occlusion_is_lighter() -> void:
	var config := GameConfig.get_default()
	assert_float(config.ssao_intensity).is_less_equal(1.0)
	assert_float(config.ssao_intensity).is_greater(0.5)
	for preset: GraphicsPresetDef in config.graphics_presets:
		var environment := Environment.new()
		GraphicsQuality.apply_to_environment(environment, preset, config)
		assert_bool(environment.ssao_enabled).is_equal(preset.ssao)
		assert_float(environment.ssao_intensity).is_equal_approx(config.ssao_intensity, 0.0001)
