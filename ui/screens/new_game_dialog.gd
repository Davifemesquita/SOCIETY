class_name NewGameDialog
extends PanelContainer
## Jogo novo (seção 10): semente do arquipélago (o dado sorteia outra), tamanho do arquipélago
## (pequeno, médio, grande: 4, 6 ou 8 ilhas menores) e dificuldade (dinheiro inicial e limite do
## saldo negativo), e se a partida tem eventos e encomendas e companhias rivais (Fase 11). Começar avisa pelo sinal start.

signal start(seed_value: int, archipelago_size: int, difficulty: int)
signal closed()

const SIZE_KEYS: Array[String] = ["NEW_GAME_SIZE_SMALL", "NEW_GAME_SIZE_MEDIUM", "NEW_GAME_SIZE_LARGE"]
const DIFFICULTY_KEYS: Array[String] = ["NEW_GAME_EASY", "NEW_GAME_NORMAL", "NEW_GAME_HARD"]
## Maior semente aceita (cabe no int e no campo).
const MAX_SEED := 999_999_999

var seed_edit := LineEdit.new()
var size_option := OptionButton.new()
var difficulty_option := OptionButton.new()
var events_check := CheckBox.new()
var rivals_check := CheckBox.new()
var risks_check := CheckBox.new()
## Objetivo (Fase 12): 0 = partida livre, depois os de GameConfig.victory_kinds; e o prazo.
var objective_option := OptionButton.new()
var deadline_option := OptionButton.new()
## Fase 44: a carta do arquipélago da semente, gerada numa thread a cada troca (com um respiro de PREVIEW_DELAY_S para
## não gerar a cada dígito), e o texto enquanto ela não sai. As prévias velhas ficam aqui até a tarefa ser recolhida.
const PREVIEW_DELAY_S := 0.35
var preview := TextureRect.new()
var preview_label := Label.new()
var _current: ArchipelagoPreview
var _pending: Array[ArchipelagoPreview] = []
var _preview_wait: float = -1.0


func _init() -> void:
	name = "NewGame"
	theme_type_variation = &"MenuPanel"
	var config := GameConfig.get_default()
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	add_child(column)
	column.add_child(UiKit.header("NEW_GAME_TITLE", func() -> void: closed.emit()))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 12)
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 24)
	column.add_child(body)
	body.add_child(grid)
	# Fase 44: a prévia da carta, à direita
	var chart_column := VBoxContainer.new()
	chart_column.add_theme_constant_override(&"separation", 6)
	body.add_child(chart_column)
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"PlainCard"
	chart_column.add_child(frame)
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(340, 340)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.tooltip_text = "NEW_GAME_PREVIEW_TIP"
	frame.add_child(preview)
	preview_label.name = "PreviewLabel"
	preview_label.theme_type_variation = &"DimLabel"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chart_column.add_child(preview_label)
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_seed"), 30))
	grid.add_child(UiKit.label("NEW_GAME_SEED"))
	var seed_row := HBoxContainer.new()
	seed_edit.custom_minimum_size.x = 220
	seed_edit.tooltip_text = "NEW_GAME_SEED_TIP"
	seed_edit.max_length = 9
	seed_edit.text_changed.connect(func(text: String) -> void:
		var digits := ""
		for character: String in text:
			if character >= "0" and character <= "9":
				digits += character
		if digits != text:
			seed_edit.text = digits
			seed_edit.caret_column = digits.length()
		_ask_preview())
	seed_row.add_child(seed_edit)
	var dice := UiKit.icon_button("action_dice", "NEW_GAME_RANDOM_TIP", roll)
	dice.name = "Dice"
	seed_row.add_child(dice)
	grid.add_child(seed_row)
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_island"), 30))
	grid.add_child(UiKit.label("NEW_GAME_SIZE"))
	for index: int in SIZE_KEYS.size():
		size_option.add_icon_item(Icons.get_icon("hud_island"), tr(SIZE_KEYS[index]) % (config.island_count_for(index) - 1))
	size_option.tooltip_text = "NEW_GAME_SIZE_TIP"
	size_option.select(mini(1, SIZE_KEYS.size() - 1))
	size_option.item_selected.connect(func(_index: int) -> void: _ask_preview())
	grid.add_child(size_option)
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_money"), 30))
	grid.add_child(UiKit.label("NEW_GAME_DIFFICULTY"))
	for index: int in DIFFICULTY_KEYS.size():
		difficulty_option.add_icon_item(Icons.get_icon("hud_money"), tr(DIFFICULTY_KEYS[index]) % [Fmt.integer(config.starting_money_for(index)),
				Fmt.integer(config.min_balance_for(index))])
	difficulty_option.tooltip_text = "NEW_GAME_DIFFICULTY_TIP"
	difficulty_option.select(config.default_difficulty)
	grid.add_child(difficulty_option)
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_event"), 30))
	grid.add_child(UiKit.label("NEW_GAME_EVENTS"))
	events_check.name = "Events"
	events_check.focus_mode = Control.FOCUS_NONE
	events_check.tooltip_text = "NEW_GAME_EVENTS_TIP"
	events_check.button_pressed = true
	grid.add_child(events_check)
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_rival"), 30))
	grid.add_child(UiKit.label("NEW_GAME_RIVALS"))
	rivals_check.name = "Rivals"
	rivals_check.focus_mode = Control.FOCUS_NONE
	rivals_check.tooltip_text = "NEW_GAME_RIVALS_TIP"
	rivals_check.button_pressed = true
	grid.add_child(rivals_check)
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_risk"), 30))
	grid.add_child(UiKit.label("NEW_GAME_RISKS"))
	risks_check.name = "Risks"
	risks_check.focus_mode = Control.FOCUS_NONE
	risks_check.tooltip_text = "NEW_GAME_RISKS_TIP"
	risks_check.button_pressed = true
	grid.add_child(risks_check)
	var data := GameData.get_default()
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_objective"), 30))
	grid.add_child(UiKit.label("NEW_GAME_OBJECTIVE"))
	objective_option.name = "Objective"
	objective_option.tooltip_text = "NEW_GAME_OBJECTIVE_TIP"
	objective_option.add_item(tr("OBJECTIVE_FREE"))
	for index: int in config.victory_kinds.size():
		objective_option.add_item(ObjectiveText.describe(config.victory_kinds[index], config.victory_targets[index],
				config.victory_amounts[index], data))
	objective_option.item_selected.connect(func(index: int) -> void: deadline_option.disabled = index == 0)
	grid.add_child(objective_option)
	grid.add_child(UiKit.icon_rect(Icons.get_icon("hud_clock"), 30))
	grid.add_child(UiKit.label("NEW_GAME_DEADLINE"))
	deadline_option.name = "Deadline"
	deadline_option.tooltip_text = "NEW_GAME_DEADLINE_TIP"
	for minutes: float in config.deadline_choices_min:
		deadline_option.add_item(ObjectiveText.deadline(minutes))
	deadline_option.disabled = true
	grid.add_child(deadline_option)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override(&"separation", 12)
	column.add_child(buttons)
	buttons.add_child(UiKit.button("UI_BACK", "action_back", func() -> void: closed.emit()))
	var go := UiKit.button("NEW_GAME_START", "action_new_game", confirm, "NEW_GAME_START_TIP")
	go.name = "Start"
	go.theme_type_variation = &"MenuButtonLarge"
	buttons.add_child(go)
	roll()


func roll() -> void:
	seed_edit.text = str(randi() % 1_000_000)
	_ask_preview()


## A semente ou o tamanho mudou: a prévia de agora é cancelada e uma nova sai depois do respiro.
func _ask_preview() -> void:
	if _current != null:
		_current.cancel()
		_pending.append(_current)
		_current = null
	_preview_wait = PREVIEW_DELAY_S
	preview_label.text = tr("NEW_GAME_PREVIEW_WORKING")


## A semente que o campo pede agora (a mesma conta do confirm()).
func chosen_seed() -> int:
	return clampi(seed_edit.text.to_int(), 0, MAX_SEED) if seed_edit.text.is_valid_int() else -1


func _process(delta: float) -> void:
	if _preview_wait >= 0.0:
		_preview_wait -= delta
		if _preview_wait < 0.0:
			start_preview()
	if _current != null and _current.poll() and preview.texture == null:
		var image := _current.image()
		if image != null:
			preview.texture = ImageTexture.create_from_image(image)
			preview_label.text = tr("NEW_GAME_PREVIEW_DONE") % _current.seed_value
	for old: ArchipelagoPreview in _pending.duplicate():
		if old.poll():
			_pending.erase(old)


## Começa a prévia da semente e do tamanho de agora (sem esperar o respiro: testes).
func start_preview(threaded: bool = true) -> void:
	_preview_wait = -1.0
	var seed_value := chosen_seed()
	if seed_value < 0:
		preview_label.text = ""
		return
	preview.texture = null
	_current = ArchipelagoPreview.new(seed_value, size_option.selected, GameConfig.get_default(), GameData.get_default())
	_current.start(threaded)
	preview_label.text = tr("NEW_GAME_PREVIEW_WORKING")


## A prévia de agora e as velhas ainda esperando (testes).
func current_preview() -> ArchipelagoPreview:
	return _current


func pending_previews() -> int:
	return _pending.size()


## Fechar com uma prévia no meio: as tarefas vão para ArchipelagoPreview.adopt (recolhidas sem travar a tela).
func _exit_tree() -> void:
	if _current != null:
		_current.cancel()
		_pending.append(_current)
		_current = null
	for old: ArchipelagoPreview in _pending:
		ArchipelagoPreview.adopt(old)
	_pending.clear()


func confirm() -> void:
	var seed_value := clampi(seed_edit.text.to_int(), 0, MAX_SEED) if seed_edit.text.is_valid_int() else randi() % 1_000_000
	start.emit(seed_value, size_option.selected, difficulty_option.selected)


## Põe o objetivo escolhido no jogo novo (GameScreen); partida livre zera.
func apply_objective() -> void:
	var config := GameConfig.get_default()
	GameScreen.reset_new_game()
	var index := objective_option.selected - 1
	if index < 0 or index >= config.victory_kinds.size():
		return
	GameScreen.victory_kind = config.victory_kinds[index]
	GameScreen.victory_target = config.victory_targets[index]
	GameScreen.victory_amount = config.victory_amounts[index]
	GameScreen.victory_deadline_min = config.deadline_choices_min[clampi(deadline_option.selected, 0, config.deadline_choices_min.size() - 1)]
