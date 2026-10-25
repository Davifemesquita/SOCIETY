extends Node
## Preferências do jogador (seção 10, opções): gráficos, áudio, controles, idioma e interface,
## gravadas em ConfigFile. Nunca em .tres: arquivo vindo do usuário não pode carregar script.
## Valor inválido no arquivo volta ao padrão.

const SETTINGS_PATH := "user://settings.cfg"
## Barramentos de áudio (seção 11), criados ao iniciar se o projeto não os tiver.
const AUDIO_BUSES: Array[StringName] = [&"Master", &"Music", &"Ambience", &"Effects", &"Interface"]
const FPS_LIMITS: Array[int] = [0, 30, 60, 120, 144]
## Intervalos do salvamento automático oferecidos (minutos de jogo; 0 = desligado).
const AUTOSAVE_CHOICES: Array[float] = [0.0, 5.0, 10.0, 15.0, 30.0]
const CAMERA_SPEED_RANGE := Vector2(0.5, 2.0)

var locale: String = ""
var ui_scale: float = 1.0
## Pan da câmera ao encostar o mouse na borda da tela.
var edge_pan: bool = true
## Modo para daltonismo nos indicadores (azul, laranja e vermelhão no lugar do semáforo).
var colorblind: bool = false
var fullscreen: bool = false
var vsync: bool = true
## Escala da resolução 3D: abaixo de 1 usa o FSR 2.2.
var render_scale: float = 1.0
## Nível de qualidade gráfica (índice em GameConfig.graphics_presets).
var graphics_preset: int = 2
## Salvamento automático a cada tantos minutos de jogo (0 = desligado) e o conselheiro falando.
var autosave_minutes: float = 10.0
var advisor: bool = true
## Velocidade do pan da câmera (multiplica GameConfig.camera_pan_speed).
var camera_speed: float = 1.0
## Limite de quadros por segundo (0 = sem limite).
var max_fps: int = 0
## Volume de cada barramento, de 0 a 1.
var volumes: Dictionary[StringName, float] = {}
## Teclas trocadas pelo jogador: ação → teclas físicas. Ação ausente = a tecla padrão.
var key_bindings: Dictionary[StringName, PackedInt32Array] = {}

var _config: GameConfig = GameConfig.get_default()


func _ready() -> void:
	InputActions.register_defaults()
	ensure_audio_buses()
	load_from(SETTINGS_PATH)
	# para testes e capturas: SOCIETY_NIVEL_GRAFICO=0..3 troca o nível sem gravar nas preferências
	var forced := OS.get_environment("SOCIETY_NIVEL_GRAFICO")
	if forced.is_valid_int():
		set_graphics_preset(forced.to_int())
	apply()


func set_locale(value: String) -> void:
	locale = value if value in _config.supported_locales else _config.supported_locales[0]


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, _config.ui_scale_min, _config.ui_scale_max)


func set_render_scale(value: float) -> void:
	render_scale = clampf(value, _config.render_scale_min, 1.0)


## Troca o nível gráfico; a escala de resolução vai para a sugerida pelo nível (o jogador ainda
## pode mudá-la depois).
func set_graphics_preset(index: int) -> void:
	graphics_preset = clampi(index, 0, _config.graphics_presets.size() - 1)
	set_render_scale(preset().render_scale)


func preset() -> GraphicsPresetDef:
	return _config.graphics_presets[clampi(graphics_preset, 0, _config.graphics_presets.size() - 1)]


func set_volume(bus: StringName, value: float) -> void:
	if bus in AUDIO_BUSES:
		volumes[bus] = clampf(value, 0.0, 1.0)


func volume(bus: StringName) -> float:
	return volumes.get(bus, 1.0)


## Troca a tecla da ação. Outra ação que usava a mesma tecla fica com a padrão dela (ou sem tecla,
## se a padrão também é essa): uma tecla, uma ação.
func bind_key(action: StringName, physical_keycode: int) -> void:
	if not InputActions.remappable().has(action):
		return
	for other: StringName in InputActions.remappable():
		if other != action and keys_of(other).has(physical_keycode):
			var defaults: Array = InputActions.KEYS[other]
			key_bindings[other] = PackedInt32Array() if defaults.has(physical_keycode) else PackedInt32Array(defaults)
	key_bindings[action] = PackedInt32Array([physical_keycode])
	InputActions.apply_bindings(key_bindings)


func reset_keys() -> void:
	key_bindings.clear()
	InputActions.apply_bindings(key_bindings)


## Teclas físicas da ação agora (as trocadas ou as padrão).
func keys_of(action: StringName) -> PackedInt32Array:
	if key_bindings.has(action):
		return key_bindings[action]
	var defaults: Array = InputActions.KEYS.get(action, [])
	return PackedInt32Array(defaults)


func apply() -> void:
	TranslationServer.set_locale(locale)
	UiPalette.colorblind = colorblind
	InputActions.apply_bindings(key_bindings)
	for bus: StringName in AUDIO_BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume(bus), 0.0001)))
			AudioServer.set_bus_mute(index, volume(bus) <= 0.0)
	Engine.max_fps = max_fps
	if is_inside_tree():
		var root := get_tree().root
		root.content_scale_factor = ui_scale
		# Fase 32: o FSR 2.2 (abaixo de 100% ou, no ultra, na cheia) já é o AA; sem ele, o AA de tela do nível
		root.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2 if preset().uses_temporal(render_scale) else Viewport.SCALING_3D_MODE_BILINEAR
		root.scaling_3d_scale = render_scale
		root.fsr_sharpness = preset().fsr_sharpness
		root.screen_space_aa = preset().screen_aa_for(render_scale)
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.mesh_lod_threshold = preset().mesh_lod_threshold
		RenderingServer.directional_shadow_atlas_set_size(preset().shadow_atlas_size, true)
		RenderingServer.directional_soft_shadow_filter_set_quality(preset().soft_shadow_quality as RenderingServer.ShadowQuality)
		_apply_window()
	EventBus.settings_changed.emit()


## Janela e vsync só com tela de verdade (os testes rodam sem).
func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var wanted := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	var current := DisplayServer.window_get_mode()
	var is_full := current in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	if is_full != fullscreen:
		DisplayServer.window_set_mode(wanted)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


func save() -> Error:
	return save_to(SETTINGS_PATH)


func save_to(path: String) -> Error:
	var file := ConfigFile.new()
	file.set_value("interface", "locale", locale)
	file.set_value("interface", "ui_scale", ui_scale)
	file.set_value("interface", "colorblind", colorblind)
	file.set_value("controls", "edge_pan", edge_pan)
	file.set_value("graphics", "fullscreen", fullscreen)
	file.set_value("graphics", "vsync", vsync)
	file.set_value("graphics", "render_scale", render_scale)
	file.set_value("graphics", "max_fps", max_fps)
	file.set_value("graphics", "preset", graphics_preset)
	file.set_value("game", "autosave_minutes", autosave_minutes)
	file.set_value("game", "advisor", advisor)
	file.set_value("controls", "camera_speed", camera_speed)
	for bus: StringName in volumes:
		file.set_value("audio", String(bus), volumes[bus])
	for action: StringName in key_bindings:
		file.set_value("keys", String(action), key_bindings[action])
	return file.save(path)


## Lê as preferências; arquivo ausente ou valor inválido volta ao padrão.
func load_from(path: String) -> void:
	var file := ConfigFile.new()
	file.load(path)
	set_locale(str(file.get_value("interface", "locale", "")))
	set_ui_scale(_number(file.get_value("interface", "ui_scale", 1.0), 1.0))
	colorblind = _flag(file.get_value("interface", "colorblind", false), false)
	edge_pan = _flag(file.get_value("controls", "edge_pan", true), true)
	camera_speed = clampf(_number(file.get_value("controls", "camera_speed", 1.0), 1.0), CAMERA_SPEED_RANGE.x, CAMERA_SPEED_RANGE.y)
	var raw_autosave := _number(file.get_value("game", "autosave_minutes", _config.autosave_interval_minutes), _config.autosave_interval_minutes)
	autosave_minutes = raw_autosave if AUTOSAVE_CHOICES.has(raw_autosave) else _config.autosave_interval_minutes
	advisor = _flag(file.get_value("game", "advisor", true), true)
	fullscreen = _flag(file.get_value("graphics", "fullscreen", false), false)
	vsync = _flag(file.get_value("graphics", "vsync", true), true)
	var raw_preset: Variant = file.get_value("graphics", "preset", _config.default_graphics_preset)
	graphics_preset = raw_preset if raw_preset is int and raw_preset >= 0 and raw_preset < _config.graphics_presets.size() \
			else _config.default_graphics_preset
	set_render_scale(_number(file.get_value("graphics", "render_scale", preset().render_scale), preset().render_scale))
	var raw_fps: Variant = file.get_value("graphics", "max_fps", 0)
	max_fps = raw_fps if raw_fps is int and FPS_LIMITS.has(raw_fps) else 0
	volumes.clear()
	for bus: StringName in AUDIO_BUSES:
		set_volume(bus, _number(file.get_value("audio", String(bus), 1.0), 1.0))
	key_bindings.clear()
	if file.has_section("keys"):
		for action_name: String in file.get_section_keys("keys"):
			var action := StringName(action_name)
			var raw: Variant = file.get_value("keys", action_name)
			if InputActions.remappable().has(action) and raw is PackedInt32Array:
				key_bindings[action] = raw


static func _number(raw: Variant, fallback: float) -> float:
	if raw is float:
		return raw
	if raw is int:
		var whole: int = raw
		return float(whole)
	return fallback


static func _flag(raw: Variant, fallback: bool) -> bool:
	return raw if raw is bool else fallback


## Os barramentos da seção 11, na ordem, todos saindo no Master.
static func ensure_audio_buses() -> void:
	for bus: StringName in AUDIO_BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, &"Master")
