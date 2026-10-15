class_name GameShortcuts
extends Node
## Atalhos da partida: velocidade do tempo, salvar e carregar, estatísticas, rotas, o menu (Esc,
## quando não há o que cancelar), camadas de depuração e centralizar no prédio selecionado. Os da
## câmera e da construção ficam nos nós deles. Com uma janela de menu aberta, nada aqui responde.

var _game: GameScreen


func setup(game: GameScreen) -> void:
	_game = game


func _unhandled_input(event: InputEvent) -> void:
	if _game.modal_open():
		return
	if event.is_action_pressed(&"game_menu"):
		# Esc: fecha a janela de cima; sem janela, cancela a ferramenta (BuildTool) ou abre o menu
		if _game.hud.close_top_window():
			get_viewport().set_input_as_handled()
		elif _game.tool.mode == BuildTool.Mode.NONE and _game.tool.selected_id == 0 and _game.tool.selected_ship == 0 \
				and not _game.tool.dragging:
			_game.open_menu()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"time_pause"):
		GameClock.toggle_pause()
	elif event.is_action_pressed(&"time_speed_1"):
		GameClock.set_speed(0)
	elif event.is_action_pressed(&"time_speed_2"):
		GameClock.set_speed(1)
	elif event.is_action_pressed(&"time_speed_3"):
		GameClock.set_speed(2)
	elif event.is_action_pressed(&"game_quicksave"):
		_game.quicksave()
	elif event.is_action_pressed(&"game_quickload"):
		_game.quickload()
	elif event.is_action_pressed(&"debug_grid") and OS.is_debug_build():
		_game.overlay.toggle(DebugOverlay.Layer.OCCUPANCY)
	elif event.is_action_pressed(&"debug_roads") and OS.is_debug_build():
		_game.overlay.toggle(DebugOverlay.Layer.ROADS)
	elif event.is_action_pressed(&"game_routes"):
		_game.hud.toggle_routes()
	elif event.is_action_pressed(&"game_missions"):
		_game.hud.toggle_missions()
	elif event.is_action_pressed(&"game_rivals"):
		_game.hud.toggle_rivals()
	elif event.is_action_pressed(&"camera_center_selected"):
		_game.center_on_selected()
	elif event.is_action_pressed(&"game_statistics"):
		_game.hud.toggle_statistics()
	elif event.is_action_pressed(&"debug_advance_hours"):
		_game.advance_day_hours()
	elif event.is_action_pressed(&"debug_cheat_resources"):
		_game.cheat_resources()
	else:
		return
	get_viewport().set_input_as_handled()
