class_name GameMenu
extends PanelContainer
## Menu da partida (Esc ou o botão da barra): continuar, salvar, carregar, opções, voltar ao menu
## principal e sair do jogo. A partida fica pausada enquanto ele está aberto.

signal closed()
signal save_requested()
signal load_requested()
signal options_requested()
signal main_menu_requested()
signal quit_requested()


func _init() -> void:
	name = "GameMenu"
	theme_type_variation = &"MenuPanel"
	custom_minimum_size.x = 380
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	column.add_child(UiKit.header("MENU_TITLE", func() -> void: closed.emit()))
	for entry: Array in [["MENU_CONTINUE", "action_play", closed], ["MENU_SAVE", "action_save", save_requested],
			["MENU_LOAD", "action_load", load_requested], ["MENU_OPTIONS", "action_options", options_requested],
			["MENU_MAIN_MENU", "action_back", main_menu_requested], ["MENU_QUIT", "action_exit", quit_requested]]:
		var text_key: String = entry[0]
		var icon_name: String = entry[1]
		var target: Signal = entry[2]
		var button := UiKit.button(text_key, icon_name, func() -> void: target.emit(), text_key + "_TIP")
		button.name = text_key
		button.theme_type_variation = &"MenuButtonLarge"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		column.add_child(button)
