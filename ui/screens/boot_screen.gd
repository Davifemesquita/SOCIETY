extends Control
## Menu principal (seção 10): continuar (o save mais recente), jogo novo (semente, tamanho do
## arquipélago, dificuldade, objetivo), cenários e conquistas (Fase 12), carregar com miniaturas,
## opções, créditos e sair. Ao abrir, valida a
## configuração e os dados: problema vai para o log e aparece no rodapé.
## Atalhos de linha de comando (também no .exe): `-- --novo-jogo` abre direto uma partida nova,
## `-- --carregar` abre o save rápido, `-- --benchmark` roda o benchmark da fase e mostra o
## resultado e `-- --semente 1234` escolhe o arquipélago do jogo novo.

const GAME_SCENE := "res://ui/screens/game_screen.tscn"

var continue_button: Button
var load_button: Button
var _layer := Control.new()
var _problems := PackedStringArray()


func _ready() -> void:
	_problems = GameConfig.get_default().validate()
	_problems.append_array(GameData.get_default().validate())
	for problem: String in _problems:
		push_error("GameConfig: " + problem)
	_build()
	_play_menu_music()
	EventBus.settings_changed.connect(_rebuild)
	var args := OS.get_cmdline_user_args()
	var seed_at := args.find("--semente")
	if seed_at >= 0 and seed_at + 1 < args.size() and args[seed_at + 1].is_valid_int():
		GameScreen.world_seed = args[seed_at + 1].to_int()
	if "--benchmark" in args:
		get_tree().change_scene_to_file.call_deferred("res://tools/benchmark.tscn")
	elif "--novo-jogo" in args:
		_start.call_deferred("")
	elif "--carregar" in args and SaveSystem.has_slot(GameScreen.QUICK_SLOT):
		_start.call_deferred(GameScreen.QUICK_SLOT)


## Refaz a tela (troca de idioma: os textos montados com tr() mudam).
func _rebuild() -> void:
	for child: Node in get_children():
		if child != _layer and child.name != &"MenuMusic":
			remove_child(child)
			child.queue_free()
	_build()


func _build() -> void:
	var background := MenuBackground.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 90)
	add_child(row)
	var title_column := VBoxContainer.new()
	title_column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(title_column)
	var title := UiKit.label("GAME_TITLE", &"BigLabel")
	title.add_theme_font_size_override(&"font_size", 120)
	title_column.add_child(title)
	var subtitle := UiKit.label("BOOT_SUBTITLE", &"HeaderLabel")
	subtitle.add_theme_font_size_override(&"font_size", 28)
	title_column.add_child(subtitle)
	var menu_center := CenterContainer.new()
	row.add_child(menu_center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.custom_minimum_size.x = 380
	menu_center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	panel.add_child(column)
	var latest := _latest_slot()
	continue_button = _menu_button(column, "BOOT_CONTINUE", "action_continue", func() -> void: _start(latest))
	continue_button.disabled = latest.is_empty()
	var new_game := _menu_button(column, "BOOT_NEW_GAME", "action_new_game", open_new_game)
	_menu_button(column, "BOOT_SCENARIOS", "action_scenarios", open_scenarios)
	load_button = _menu_button(column, "BOOT_LOAD_GAME", "action_load", open_load)
	load_button.disabled = SaveSystem.list_slots().is_empty()
	_menu_button(column, "BOOT_OPTIONS", "action_options", func() -> void: Modal.open(_layer, OptionsDialog.new()))
	_menu_button(column, "BOOT_ACHIEVEMENTS", "action_achievements", open_achievements)
	_menu_button(column, "BOOT_CREDITS", "action_credits", func() -> void: Modal.open(_layer, CreditsDialog.new()))
	_menu_button(column, "BOOT_QUIT", "action_exit", func() -> void: get_tree().quit())
	new_game.grab_focus()
	var footer := Label.new()
	footer.name = "Footer"
	footer.text = tr("BOOT_VERSION") % str(ProjectSettings.get_setting("application/config/version", ""))
	if not _problems.is_empty():
		footer.text += "  ·  " + tr("BOOT_CONFIG_ERRORS") % _problems.size()
		UiPalette.paint(footer, UiPalette.Status.BAD)
	footer.theme_type_variation = &"DimLabel"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position += Vector2(36, -48)
	add_child(footer)
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _layer.get_parent() == null:
		add_child(_layer)
	else:
		move_child(_layer, get_child_count() - 1)


func _menu_button(column: VBoxContainer, text_key: String, icon_name: String, action: Callable) -> Button:
	var button := UiKit.button(text_key, icon_name, action, text_key + "_TIP")
	button.name = text_key
	button.theme_type_variation = &"MenuButtonLarge"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	column.add_child(button)
	return button


func open_new_game() -> NewGameDialog:
	var dialog := NewGameDialog.new()
	if GameScreen.world_seed >= 0:
		dialog.seed_edit.text = str(GameScreen.world_seed)
	dialog.start.connect(func(seed_value: int, archipelago_size: int, difficulty: int) -> void:
		GameScreen.world_seed = seed_value
		GameScreen.archipelago_size = archipelago_size
		GameScreen.difficulty = difficulty
		GameScreen.events_enabled = dialog.events_check.button_pressed
		GameScreen.rivals_enabled = dialog.rivals_check.button_pressed
		GameScreen.risks_enabled = dialog.risks_check.button_pressed
		dialog.apply_objective()
		_start(""))
	Modal.open(_layer, dialog)
	return dialog


## Cenários (Fase 12): jogar abre a partida já configurada.
func open_scenarios() -> ScenarioDialog:
	var dialog := ScenarioDialog.new()
	dialog.start.connect(func(id: StringName) -> void:
		GameScreen.apply_scenario(GameData.get_default().scenario(id))
		_start(""))
	Modal.open(_layer, dialog)
	return dialog


func open_achievements() -> AchievementsDialog:
	var dialog := AchievementsDialog.new()
	Modal.open(_layer, dialog)
	return dialog


func open_load() -> SaveLoadDialog:
	var dialog := SaveLoadDialog.new(SaveLoadDialog.Mode.LOAD)
	dialog.load_chosen.connect(_start)
	Modal.open(_layer, dialog)
	return dialog


## O save mais recente (o que "continuar" abre), ou vazio.
static func _latest_slot() -> String:
	var slots := SaveSystem.list_slots()
	return slots[0] if not slots.is_empty() else ""


func _start(slot: String) -> void:
	GameScreen.load_slot_on_start = slot
	get_tree().change_scene_to_file(GAME_SCENE)


## Música calma no menu (Fase 10): a mesma da partida, no barramento Music.
func _play_menu_music() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var player := AudioStreamPlayer.new()
	player.name = "MenuMusic"
	player.bus = &"Music"
	player.stream = MusicDirector.build_stream(GameConfig.get_default().music_fade_seconds)
	add_child(player)
	player.play()
