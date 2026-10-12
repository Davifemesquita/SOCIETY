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
	_settings.set_ui_scale(3.0)
	assert_float(_settings.ui_scale).is_equal(1.5)
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
