extends "res://tools/capture_phase290.gd"
## Roteiro de verificação visual do ciclo da falésia de verdade (Fases 310 a 314): na semente 1840, às 10h30, a falésia sobre o mar
## de perto, de meia distância e de lado, e a costa baixa de pedra. As mesmas vistas antes e depois de cada fase. Precisa de GPU;
## no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase310.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	await _build_town(game)
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	var cliff := grid.cell_world(_find_cliff(grid))
	await _shot(game, "01_falesia_de_perto.png", cliff, 45.0, 0.3)
	await _shot(game, "02_falesia.png", cliff, 90.0, 0.3)
	await _shot(game, "03_falesia_de_lado.png", cliff, 45.0, 0.3 + PI * 0.5)
	var rocky := grid.cell_world(_find_rocky_shore(grid))
	await _shot(game, "04_costa_de_pedra.png", rocky, 40.0, 0.3)
	get_tree().quit()
