extends GdUnitTestSuite
## Fase 32: nenhum nível gráfico fica sem antisserrilhado e nenhum usa MSAA; o Settings põe no viewport o AA de cada
## nível (e desliga o AA de tela quando o FSR 2.2 já faz o papel); a troca de nível pelas opções passa pela cortina.

var _config: GameConfig
var _preset_before: int
var _scale_before: float


func before_test() -> void:
	_config = GameConfig.get_default()
	_preset_before = Settings.graphics_preset
	_scale_before = Settings.render_scale


func after_test() -> void:
	Settings.graphics_preset = _preset_before
	Settings.render_scale = _scale_before
	Settings.apply()
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "1")


func test_every_preset_has_antialiasing_at_any_scale() -> void:
	for preset: GraphicsPresetDef in _config.graphics_presets:
		assert_array(Array(preset.validate())).is_empty()
		for scale: float in [_config.render_scale_min, preset.render_scale, 1.0]:
			var temporal := preset.uses_temporal(scale)
			var screen := preset.screen_aa_for(scale)
			assert_bool(temporal or screen != Viewport.SCREEN_SPACE_AA_DISABLED) \
					.override_failure_message("%s a %.2f sem AA" % [preset.id, scale]).is_true()
			# com o FSR ligado, o AA de tela é desperdício (e borra o que o FSR já resolveu)
			if temporal:
				assert_int(screen).is_equal(Viewport.SCREEN_SPACE_AA_DISABLED)


func test_presets_follow_the_phase_32_table() -> void:
	var presets := _config.graphics_presets
	assert_int(presets[0].screen_space_aa).is_equal(Viewport.SCREEN_SPACE_AA_FXAA)
	assert_int(presets[1].screen_space_aa).is_equal(Viewport.SCREEN_SPACE_AA_SMAA)
	assert_int(presets[2].screen_space_aa).is_equal(Viewport.SCREEN_SPACE_AA_SMAA)
	assert_bool(presets[3].temporal_native).is_true()
	for index: int in 3:
		assert_bool(presets[index].temporal_native).is_false()


func test_a_preset_without_any_antialiasing_is_invalid() -> void:
	var preset: GraphicsPresetDef = _config.graphics_presets[2].duplicate()
	preset.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	assert_array(Array(preset.validate())).is_not_empty()
	preset.temporal_native = true
	assert_array(Array(preset.validate())).is_empty()


func test_settings_put_the_preset_antialiasing_on_the_viewport() -> void:
	var root := get_tree().root
	for index: int in _config.graphics_presets.size():
		var preset := _config.graphics_presets[index]
		Settings.set_graphics_preset(index)
		Settings.set_render_scale(1.0)
		Settings.apply()
		assert_int(root.msaa_3d).is_equal(Viewport.MSAA_DISABLED)
		assert_int(root.screen_space_aa).is_equal(preset.screen_aa_for(1.0))
		var mode := Viewport.SCALING_3D_MODE_FSR2 if preset.temporal_native else Viewport.SCALING_3D_MODE_BILINEAR
		assert_int(root.scaling_3d_mode).is_equal(mode)
		assert_float(root.fsr_sharpness).is_equal_approx(preset.fsr_sharpness, 0.001)
	# abaixo de 100% o FSR liga em qualquer nível e o AA de tela sai
	Settings.set_graphics_preset(1)
	Settings.set_render_scale(0.75)
	Settings.apply()
	assert_int(root.scaling_3d_mode).is_equal(Viewport.SCALING_3D_MODE_FSR2)
	assert_int(root.screen_space_aa).is_equal(Viewport.SCREEN_SPACE_AA_DISABLED)


func test_changing_the_preset_in_the_options_goes_behind_the_curtain() -> void:
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "0")
	if SceneFader.is_instant():
		# sem tela a cortina é sempre direta: não há o que conferir
		return
	Settings.set_graphics_preset(0)
	Settings.apply()
	var options: OptionsDialog = auto_free(OptionsDialog.new())
	add_child(options)
	var quality: OptionButton = options.find_child("Quality", true, false)
	quality.select(3)
	quality.item_selected.emit(3)
	# a troca só acontece no escuro
	assert_bool(SceneFader.busy).is_true()
	assert_int(Settings.graphics_preset).is_equal(0)
	await SceneFader.finished
	assert_int(Settings.graphics_preset).is_equal(3)
	assert_float(SceneFader.curtain_alpha()).is_equal(0.0)
	# o controle da escala acompanha logo depois que a cortina termina
	await get_tree().process_frame
	var slider: HSlider = (options.find_child("RenderScale", true, false) as Control).get_child(0)
	assert_float(slider.value).is_equal_approx(Settings.render_scale, 0.001)
	remove_child(options)
