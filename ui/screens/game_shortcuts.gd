class_name GameShortcuts
extends Node
## Atalhos da partida: velocidade do tempo, salvar e carregar, camadas de depuração e
## centralizar no prédio selecionado. Os da câmera e da construção ficam nos nós deles.

var _game: GameScreen


func setup(game: GameScreen) -> void:
	_game = game


func _unhandled_input(event: InputEvent) -> void:
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
	elif event.is_action_pressed(&"debug_grid"):
		_game.overlay.toggle(DebugOverlay.Layer.OCCUPANCY)
	elif event.is_action_pressed(&"debug_roads"):
		_game.overlay.toggle(DebugOverlay.Layer.ROADS)
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
