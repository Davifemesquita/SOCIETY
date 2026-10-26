class_name OptionsDialog
extends PanelContainer
## Opções (seção 10): gráficos (tela cheia, vsync, escala 3D com FSR 2, limite de FPS), áudio (os
## cinco barramentos), controles (pan pela borda e as teclas, remapeáveis), idioma e interface
## (escala de 80% a 150% e modo para daltonismo). Cada mudança vale na hora; fechar grava.

signal closed()

const LANGUAGE_KEYS: Dictionary[String, String] = {"pt_BR": "LANGUAGE_PT_BR", "en": "LANGUAGE_EN"}

var tabs := TabContainer.new()
## Ação esperando a tecla nova (vazio = nenhuma).
var waiting_action: StringName = &""
var _key_buttons: Dictionary[StringName, Button] = {}
var _sample := HBoxContainer.new()


func _init() -> void:
	name = "Options"
	theme_type_variation = &"MenuPanel"
	custom_minimum_size = Vector2(720, 560)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	add_child(column)
	column.add_child(UiKit.header("OPTIONS_TITLE", close))
	tabs.focus_mode = Control.FOCUS_NONE
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	_add_tab(_graphics(), "OPTIONS_GRAPHICS", "option_graphics")
	_add_tab(_audio(), "OPTIONS_AUDIO", "option_audio")
	_add_tab(_controls(), "OPTIONS_CONTROLS", "option_controls")
	_add_tab(_language(), "OPTIONS_LANGUAGE", "option_language")
	_add_tab(_interface(), "OPTIONS_INTERFACE", "option_interface")
	_add_tab(_game(), "OPTIONS_GAME", "option_game")
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	buttons.add_child(UiKit.button("UI_DONE", "action_confirm", close))


func close() -> void:
	Settings.save()
	closed.emit()


func _add_tab(page: Control, title_key: String, icon_name: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = title_key
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	tabs.add_child(scroll)
	var index := tabs.get_tab_count() - 1
	tabs.set_tab_title(index, tr(title_key))
	tabs.set_tab_icon(index, Icons.get_icon(icon_name))


static func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 24)
	grid.add_theme_constant_override(&"v_separation", 12)
	return grid


func _graphics() -> Control:
	var grid := _grid()
	grid.add_child(UiKit.label("OPTIONS_QUALITY"))
	var quality := OptionButton.new()
	quality.name = "Quality"
	quality.tooltip_text = "OPTIONS_QUALITY_TIP"
	quality.focus_mode = Control.FOCUS_NONE
	for preset: GraphicsPresetDef in GameConfig.get_default().graphics_presets:
		quality.add_item(preset.name_key)
	quality.select(Settings.graphics_preset)
	grid.add_child(quality)
	grid.add_child(UiKit.label("OPTIONS_FULLSCREEN"))
	grid.add_child(_check("OPTIONS_FULLSCREEN_TIP", Settings.fullscreen, func(on: bool) -> void: Settings.fullscreen = on))
	grid.add_child(UiKit.label("OPTIONS_VSYNC"))
	grid.add_child(_check("OPTIONS_VSYNC_TIP", Settings.vsync, func(on: bool) -> void: Settings.vsync = on))
	# Fase 37: a gradação de cor de época, para comparar com o visual de antes
	grid.add_child(UiKit.label("OPTIONS_PERIOD_LOOK"))
	var period := _check("OPTIONS_PERIOD_LOOK_TIP", Settings.period_look, func(on: bool) -> void: Settings.period_look = on)
	period.name = "PeriodLook"
	grid.add_child(period)
	grid.add_child(UiKit.label("OPTIONS_RENDER_SCALE"))
	var scale := _slider("OPTIONS_RENDER_SCALE_TIP", GameConfig.get_default().render_scale_min, 1.0, 0.05, Settings.render_scale,
			func(value: float) -> void: Settings.set_render_scale(value))
	scale.name = "RenderScale"
	grid.add_child(scale)
	# o nível sugere a escala: o controle acompanha. Fase 32: a troca recompila pipelines e cai no escuro da cortina
	quality.item_selected.connect(func(index: int) -> void:
		await SceneFader.change_with(func() -> void:
			Settings.set_graphics_preset(index)
			Settings.apply(), "LOADING_GRAPHICS")
		if is_instance_valid(scale):
			var slider := scale.get_child(0) as HSlider
			slider.value = Settings.render_scale)
	grid.add_child(UiKit.label("OPTIONS_MAX_FPS"))
	var fps := OptionButton.new()
	fps.name = "MaxFps"
	fps.tooltip_text = "OPTIONS_MAX_FPS_TIP"
	fps.focus_mode = Control.FOCUS_NONE
	for limit: int in Settings.FPS_LIMITS:
		fps.add_item(tr("OPTIONS_FPS_UNLIMITED") if limit == 0 else str(limit), limit)
	fps.select(maxi(0, fps.get_item_index(Settings.max_fps)))
	fps.item_selected.connect(func(index: int) -> void:
		Settings.max_fps = fps.get_item_id(index)
		Settings.apply())
	grid.add_child(fps)
	var note := UiKit.label("OPTIONS_GRAPHICS_NOTE", &"DimLabel")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var column := VBoxContainer.new()
	column.add_child(grid)
	column.add_child(note)
	return column


## Jogo (Fase 10): salvamento automático, o conselheiro e a velocidade da câmera.
func _game() -> Control:
	var grid := _grid()
	grid.add_child(UiKit.label("OPTIONS_AUTOSAVE"))
	var autosave := OptionButton.new()
	autosave.name = "Autosave"
	autosave.tooltip_text = "OPTIONS_AUTOSAVE_TIP"
	autosave.focus_mode = Control.FOCUS_NONE
	for minutes: float in Settings.AUTOSAVE_CHOICES:
		autosave.add_item(tr("OPTIONS_AUTOSAVE_OFF") if minutes <= 0.0 else tr("OPTIONS_AUTOSAVE_EVERY") % Fmt.integer(minutes))
	autosave.select(maxi(0, Settings.AUTOSAVE_CHOICES.find(Settings.autosave_minutes)))
	autosave.item_selected.connect(func(index: int) -> void:
		Settings.autosave_minutes = Settings.AUTOSAVE_CHOICES[index]
		Settings.apply())
	grid.add_child(autosave)
	grid.add_child(UiKit.label("OPTIONS_ADVISOR"))
	grid.add_child(_check("OPTIONS_ADVISOR_TIP", Settings.advisor, func(on: bool) -> void: Settings.advisor = on))
	grid.add_child(UiKit.label("OPTIONS_CAMERA_SPEED"))
	grid.add_child(_slider("OPTIONS_CAMERA_SPEED_TIP", Settings.CAMERA_SPEED_RANGE.x, Settings.CAMERA_SPEED_RANGE.y, 0.1,
			Settings.camera_speed, func(value: float) -> void: Settings.camera_speed = value))
	return grid


func _audio() -> Control:
	var grid := _grid()
	for bus: StringName in Settings.AUDIO_BUSES:
		grid.add_child(UiKit.label("AUDIO_BUS_" + String(bus).to_upper()))
		var slider := _slider("OPTIONS_VOLUME_TIP", 0.0, 1.0, 0.05, Settings.volume(bus), func(value: float) -> void: Settings.set_volume(bus, value))
		slider.name = "Volume_" + bus
		grid.add_child(slider)
	return grid


func _controls() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	var top := HBoxContainer.new()
	column.add_child(top)
	top.add_child(_check("OPTIONS_EDGE_PAN_TIP", Settings.edge_pan, func(on: bool) -> void: Settings.edge_pan = on))
	top.add_child(UiKit.label("OPTIONS_EDGE_PAN"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var reset := UiKit.button("OPTIONS_KEYS_RESET", "action_reset", func() -> void:
		Settings.reset_keys()
		_refresh_keys(), "OPTIONS_KEYS_RESET_TIP")
	reset.name = "ResetKeys"
	top.add_child(reset)
	column.add_child(UiKit.label("OPTIONS_KEYS_HINT", &"DimLabel"))
	var grid := _grid()
	column.add_child(grid)
	for action: StringName in InputActions.remappable():
		grid.add_child(UiKit.label("ACTION_" + String(action).to_upper()))
		var button := UiKit.button("", "option_controls", func() -> void: _wait_key(action), "OPTIONS_KEY_TIP")
		button.name = "Key_" + action
		button.custom_minimum_size.x = 200
		grid.add_child(button)
		_key_buttons[action] = button
	_refresh_keys()
	return column


func _language() -> Control:
	var grid := _grid()
	grid.add_child(UiKit.label("OPTIONS_LANGUAGE"))
	var option := OptionButton.new()
	option.name = "Language"
	option.tooltip_text = "OPTIONS_LANGUAGE_TIP"
	option.focus_mode = Control.FOCUS_NONE
	var locales := GameConfig.get_default().supported_locales
	for locale: String in locales:
		var language_key: String = LANGUAGE_KEYS.get(locale, locale)
		option.add_icon_item(Icons.get_icon("option_language"), tr(language_key))
	option.select(maxi(0, locales.find(Settings.locale)))
	option.item_selected.connect(func(index: int) -> void:
		Settings.set_locale(locales[index])
		Settings.apply())
	grid.add_child(option)
	return grid


func _interface() -> Control:
	var config := GameConfig.get_default()
	var grid := _grid()
	grid.add_child(UiKit.label("OPTIONS_UI_SCALE"))
	grid.add_child(_slider("OPTIONS_UI_SCALE_TIP", config.ui_scale_min, config.ui_scale_max, 0.05, Settings.ui_scale,
			func(value: float) -> void: Settings.set_ui_scale(value)))
	grid.add_child(UiKit.label("OPTIONS_COLORBLIND"))
	var colorblind := _check("OPTIONS_COLORBLIND_TIP", Settings.colorblind, func(on: bool) -> void: Settings.colorblind = on)
	colorblind.name = "Colorblind"
	grid.add_child(colorblind)
	_sample.add_theme_constant_override(&"separation", 10)
	for status: UiPalette.Status in [UiPalette.Status.GOOD, UiPalette.Status.PARTIAL, UiPalette.Status.BAD]:
		_sample.add_child(UiKit.icon_rect(Icons.status(status), 20))
	grid.add_child(UiKit.label("OPTIONS_COLORBLIND_SAMPLE", &"DimLabel"))
	grid.add_child(_sample)
	# método, não função anônima: a ligação some sozinha quando a janela é liberada
	EventBus.settings_changed.connect(_paint_sample)
	_paint_sample()
	return grid


func _paint_sample() -> void:
	for index: int in _sample.get_child_count():
		var marker: TextureRect = _sample.get_child(index)
		marker.modulate = UiPalette.status(index as UiPalette.Status)


## Caixa de marcar que aplica na hora.
func _check(tooltip_key: String, value: bool, on_change: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.button_pressed = value
	check.tooltip_text = tooltip_key
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(on: bool) -> void:
		on_change.call(on)
		Settings.apply())
	return check


## Controle deslizante com o valor em porcentagem ao lado.
func _slider(tooltip_key: String, low: float, high: float, step: float, value: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.custom_minimum_size.x = 260
	slider.tooltip_text = tooltip_key
	slider.focus_mode = Control.FOCUS_NONE
	var shown := UiKit.label(Fmt.percent(value))
	shown.custom_minimum_size.x = 56
	slider.value_changed.connect(func(changed: float) -> void:
		on_change.call(changed)
		shown.text = Fmt.percent(changed)
		Settings.apply())
	row.add_child(slider)
	row.add_child(shown)
	return row


func _wait_key(action: StringName) -> void:
	waiting_action = action
	_refresh_keys()


## Tecla apertada enquanto uma ação espera: vira a tecla dela (o Esc cancela).
func _input(event: InputEvent) -> void:
	if waiting_action == &"" or not event is InputEventKey:
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	if key.physical_keycode != KEY_ESCAPE:
		Settings.bind_key(waiting_action, key.physical_keycode)
	waiting_action = &""
	_refresh_keys()


func _refresh_keys() -> void:
	for action: StringName in _key_buttons:
		var button := _key_buttons[action]
		if action == waiting_action:
			button.text = tr("OPTIONS_KEY_WAITING")
			continue
		var names: PackedStringArray = []
		for keycode: int in Settings.keys_of(action):
			names.append(InputActions.key_name(keycode))
		button.text = " / ".join(names) if not names.is_empty() else tr("OPTIONS_KEY_NONE")
