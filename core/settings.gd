extends Node
## Preferências do jogador (idioma, escala da interface), gravadas em ConfigFile.
## Nunca em .tres: arquivo vindo do usuário não pode carregar script.

const SETTINGS_PATH := "user://settings.cfg"

var locale: String = ""
var ui_scale: float = 1.0

var _config: GameConfig = GameConfig.get_default()


func _ready() -> void:
	load_from(SETTINGS_PATH)
	apply()


func set_locale(value: String) -> void:
	locale = value if value in _config.supported_locales else _config.supported_locales[0]


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, _config.ui_scale_min, _config.ui_scale_max)


func apply() -> void:
	TranslationServer.set_locale(locale)
	if is_inside_tree():
		get_tree().root.content_scale_factor = ui_scale
	EventBus.settings_changed.emit()


func save_to(path: String) -> Error:
	var file := ConfigFile.new()
	file.set_value("interface", "locale", locale)
	file.set_value("interface", "ui_scale", ui_scale)
	return file.save(path)


## Lê as preferências; arquivo ausente ou valor inválido volta ao padrão.
func load_from(path: String) -> void:
	var file := ConfigFile.new()
	file.load(path)
	set_locale(str(file.get_value("interface", "locale", "")))
	var raw_scale: Variant = file.get_value("interface", "ui_scale", 1.0)
	var scale_value: float = raw_scale if raw_scale is float or raw_scale is int else 1.0
	set_ui_scale(scale_value)
