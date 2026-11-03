extends "res://tools/capture_phase255.gd"
## Roteiro de verificação visual do ciclo do telhado gasto e do chão de vila (Fases 300 a 304): na semente 1840, às 10h30, a vila
## de teste de cima, de perto e os telhados de perto; desde a Fase 304, também os quintais de trás da primeira fileira de casas,
## vistos do lado de fora da vila. As mesmas vistas antes e depois de cada fase. Precisa de GPU:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase300.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	print("divisas dos quintais: ", game.yard_wall_view.segment_count())
	await _shot(game, "01_vila_de_cima.png", points[0], 110.0, 0.6)
	await _shot(game, "02_vila_de_perto.png", points[0], 50.0, 0.6)
	await _shot(game, "03_telhados.png", points[0], 28.0, 2.2)
	await _shot(game, "04_quintais.png", points[0], 35.0, PI + 0.6)
	# os fundos da primeira fileira (a frente dela dá para a rua calçada; o fundo, para fora da vila)
	var cell := game.simulation.world.island(Simulation.MAIN_ISLAND).cell_size
	var back := points[0] - Vector3(cell * 6.0, 0.0, cell * 7.0)
	await _shot(game, "05_fundos_dos_quintais.png", back, 60.0, PI - 0.3)
	await _shot(game, "06_fundos_de_perto.png", back, 38.0, PI + 0.4)
	get_tree().quit()
