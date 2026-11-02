extends "res://tools/capture_phase255.gd"
## Roteiro de verificação visual do ciclo do telhado gasto e do chão de vila (Fases 300 a 304): na semente 1840, às 10h30, a vila
## de teste de cima, de perto e os telhados de perto. As mesmas vistas antes e depois de cada fase. Precisa de GPU:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase300.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	await _shot(game, "01_vila_de_cima.png", points[0], 110.0, 0.6)
	await _shot(game, "02_vila_de_perto.png", points[0], 50.0, 0.6)
	await _shot(game, "03_telhados.png", points[0], 28.0, 2.2)
	await _shot(game, "04_quintais.png", points[0], 35.0, PI + 0.6)
	get_tree().quit()
