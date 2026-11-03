extends "res://tools/capture_phase275.gd"
## Roteiro de verificação visual do ciclo da mata funda (Fases 305 a 309): na semente 1840, às 10h30, a vila de cima, a mata alta
## de perto e de meia distância, a mata baixa de perto e o chão dela bem de perto. As mesmas vistas antes e depois de cada fase.
## Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase305.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	await _shot(game, "01_vila_de_cima.png", points[0], 110.0, 0.6)
	var high := grid.cell_world(_forest(grid, points[0], true))
	await _shot(game, "02_mata_alta_de_perto.png", high, 70.0, 0.6)
	await _shot(game, "03_mata_alta.png", high, 160.0, 0.6)
	var low := grid.cell_world(_forest(grid, points[0], false))
	await _shot(game, "04_mata_baixa_de_perto.png", low, 70.0, 0.6)
	await _shot(game, "05_chao_da_mata.png", low, 48.0, 2.0)
	get_tree().quit()
