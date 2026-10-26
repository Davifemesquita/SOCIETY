extends GdUnitTestSuite
## Preferências: limites da escala, idioma desconhecido e gravação em ConfigFile.

const SettingsScript := preload("res://core/settings.gd")
const TEST_PATH := "user://test_settings.cfg"

var _settings: SettingsScript


func before_test() -> void:
	_settings = auto_free(SettingsScript.new())


func after_test() -> void:
	DirAccess.remove_absolute(TEST_PATH)


func test_ui_scale_is_clamped_to_spec_range() -> void:
	# até 200% desde a Fase 43 (a escala aplicada ainda é limitada pela largura da janela)
	_settings.set_ui_scale(3.0)
	assert_float(_settings.ui_scale).is_equal(2.0)
	_settings.set_ui_scale(0.1)
	assert_float(_settings.ui_scale).is_equal(0.8)


func test_unknown_locale_falls_back_to_portuguese() -> void:
	_settings.set_locale("fr")
	assert_str(_settings.locale).is_equal("pt_BR")
	_settings.set_locale("en")
	assert_str(_settings.locale).is_equal("en")


func test_missing_file_gives_defaults() -> void:
	_settings.load_from("user://nao_existe.cfg")
	assert_str(_settings.locale).is_equal("pt_BR")
	assert_float(_settings.ui_scale).is_equal(1.0)


func test_save_and_load_round_trip() -> void:
	_settings.set_locale("en")
	_settings.set_ui_scale(1.25)
	assert_int(_settings.save_to(TEST_PATH)).is_equal(OK)
	var other: SettingsScript = auto_free(SettingsScript.new())
	other.load_from(TEST_PATH)
	assert_str(other.locale).is_equal("en")
	assert_float(other.ui_scale).is_equal(1.25)


func test_tampered_file_falls_back() -> void:
	var file := ConfigFile.new()
	file.set_value("interface", "locale", 42)
	file.set_value("interface", "ui_scale", "grande")
	file.save(TEST_PATH)
	_settings.load_from(TEST_PATH)
	assert_str(_settings.locale).is_equal("pt_BR")
	assert_float(_settings.ui_scale).is_equal(1.0)


func test_graphics_audio_and_interface_round_trip() -> void:
	_settings.fullscreen = true
	_settings.vsync = false
	_settings.set_render_scale(0.75)
	_settings.max_fps = 60
	_settings.colorblind = true
	_settings.set_volume(&"Music", 0.3)
	assert_int(_settings.save_to(TEST_PATH)).is_equal(OK)
	var other: SettingsScript = auto_free(SettingsScript.new())
	other.load_from(TEST_PATH)
	assert_bool(other.fullscreen).is_true()
	assert_bool(other.vsync).is_false()
	assert_float(other.render_scale).is_equal(0.75)
	assert_int(other.max_fps).is_equal(60)
	assert_bool(other.colorblind).is_true()
	assert_float(other.volume(&"Music")).is_equal_approx(0.3, 0.0001)
	assert_float(other.volume(&"Effects")).is_equal(1.0)


func test_render_scale_and_volumes_are_clamped() -> void:
	_settings.set_render_scale(0.1)
	assert_float(_settings.render_scale).is_equal(GameConfig.get_default().render_scale_min)
	_settings.set_volume(&"Master", 3.0)
	assert_float(_settings.volume(&"Master")).is_equal(1.0)
	_settings.set_volume(&"Desconhecido", 0.5)
	assert_bool(_settings.volumes.has(&"Desconhecido")).is_false()


func test_the_five_audio_buses_exist() -> void:
	SettingsScript.ensure_audio_buses()
	for bus: StringName in SettingsScript.AUDIO_BUSES:
		assert_int(AudioServer.get_bus_index(bus)).is_greater_equal(0)


func test_rebinding_a_key_frees_it_from_the_other_action() -> void:
	_settings.bind_key(&"build_road", KEY_E)
	assert_array(Array(_settings.keys_of(&"build_road"))).is_equal([KEY_E])
	# Q/E girava a câmera: o E sai de lá (a padrão dela era o E: fica sem tecla)
	assert_array(Array(_settings.keys_of(&"camera_rotate_right"))).is_empty()
	assert_bool(InputMap.action_has_event(&"build_road", _key_event(KEY_E))).is_true()
	assert_bool(InputMap.action_has_event(&"build_road", _key_event(KEY_T))).is_false()
	assert_int(_settings.save_to(TEST_PATH)).is_equal(OK)
	var other: SettingsScript = auto_free(SettingsScript.new())
	other.load_from(TEST_PATH)
	assert_array(Array(other.keys_of(&"build_road"))).is_equal([KEY_E])
	_settings.reset_keys()
	assert_array(Array(_settings.keys_of(&"build_road"))).is_equal([KEY_T])
	assert_bool(InputMap.action_has_event(&"build_road", _key_event(KEY_T))).is_true()
	assert_bool(InputMap.action_has_event(&"camera_rotate_right", _key_event(KEY_E))).is_true()


func test_debug_and_menu_keys_are_not_remappable() -> void:
	var actions := InputActions.remappable()
	for fixed: StringName in [&"game_menu", &"build_cancel", &"debug_grid", &"debug_cheat_resources"]:
		assert_bool(actions.has(fixed)).is_false()
	_settings.bind_key(&"debug_grid", KEY_G)
	assert_bool(_settings.key_bindings.has(&"debug_grid")).is_false()


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


## O limite automático de quadros (achado medindo no monitor de 180 Hz do dono): um ritmo que divide a taxa do monitor.
func test_the_automatic_frame_limit_divides_the_monitor_rate() -> void:
	assert_int(Settings.auto_fps(180.0)).is_equal(60)
	assert_int(Settings.auto_fps(100.0)).is_equal(50)
	assert_int(Settings.auto_fps(144.0)).is_equal(72)
	assert_int(Settings.auto_fps(165.0)).is_equal(55)
	assert_int(Settings.auto_fps(120.0)).is_equal(60)
	assert_int(Settings.auto_fps(240.0)).is_equal(60)
	assert_int(Settings.auto_fps(60.0)).is_equal(60)
	assert_int(Settings.auto_fps(75.0)).is_equal(75)
	assert_int(Settings.auto_fps(0.0)).is_equal(0)
	# o padrão é o automático, e ele vai e volta do arquivo; um valor fora da lista volta ao automático
	var fresh: SettingsScript = auto_free(SettingsScript.new())
	assert_int(fresh.max_fps).is_equal(Settings.FPS_AUTO)
	var path := "user://test_settings_fps.cfg"
	_settings.max_fps = 50
	_settings.save_to(path)
	var other: SettingsScript = auto_free(SettingsScript.new())
	other.load_from(path)
	assert_int(other.max_fps).is_equal(50)
	var file := ConfigFile.new()
	file.set_value("graphics", "max_fps", 77)
	file.save(path)
	other.load_from(path)
	assert_int(other.max_fps).is_equal(Settings.FPS_AUTO)
	DirAccess.remove_absolute(path)
	# o escolhido vale como está
	_settings.max_fps = 100
	assert_int(_settings.effective_max_fps()).is_equal(100)
