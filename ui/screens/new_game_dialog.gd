class_name NewGameDialog
extends PanelContainer
## Jogo novo (seção 10): semente do arquipélago (o dado sorteia outra), tamanho do arquipélago
## (pequeno, médio, grande: 4, 6 ou 8 ilhas menores) e dificuldade (dinheiro inicial e limite do
## saldo negativo), e se a partida tem eventos e encomendas (Fase 11). Começar avisa pelo sinal start.

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
	column.add_child(grid)
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
			seed_edit.caret_column = digits.length())
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


func confirm() -> void:
	var seed_value := clampi(seed_edit.text.to_int(), 0, MAX_SEED) if seed_edit.text.is_valid_int() else randi() % 1_000_000
	start.emit(seed_value, size_option.selected, difficulty_option.selected)
