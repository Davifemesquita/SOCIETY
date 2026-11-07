extends "res://tools/capture_phase260.gd"
## Roteiro de verificação visual do ciclo da mata (Fases 275 a 279): a vila do ciclo da cor (semente 1840, 10h30) de cima e os
## campos de perto, mais a mata alta (a célula de mata densa acima de `TreeView.CONIFER_HEIGHT_M` mais perto da vila, onde as
## coníferas são maioria) de perto e de meia distância, e a mata baixa (a das folhosas) de perto. As mesmas vistas antes e depois
## de cada fase. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 90000 res://tools/capture_phase275.tscn -- <pasta>

## As vistas da mata ficam pelo menos a esta distância da vila.
const FAR_M := 60.0


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	await _shot(game, "01_vila_de_cima.png", points[0], 110.0, 0.6)
	await _shot(game, "02_campos_de_perto.png", points[1], 55.0, PI + 0.6)
	var high := grid.cell_world(_forest(grid, points[0], true))
	await _shot(game, "03_mata_alta_de_perto.png", high, 70.0, 0.6)
	await _shot(game, "04_mata_alta.png", high, 160.0, 0.6)
	var low := grid.cell_world(_forest(grid, points[0], false))
	await _shot(game, "05_mata_baixa_de_perto.png", low, 70.0, 0.6)
	get_tree().quit()


## A célula de mata densa (duas árvores ou mais, com as células a até duas de distância também de mata) mais perto do ponto,
## mas a FAR_M dele no mínimo (fora da vila), acima (high) ou abaixo da altura das coníferas.
func _forest(grid: IslandGrid, near: Vector3, high: bool) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(2, grid.size.y - 2, 2):
		for x: int in range(2, grid.size.x - 2, 2):
			var cell := Vector2i(x, y)
			if grid.trees[grid.index(cell)] < 2 or (grid.cell_height(cell) >= TreeView.CONIFER_HEIGHT_M) != high:
				continue
			var score := grid.cell_world(cell).distance_to(near)
			if score < FAR_M or score >= best_score:
				continue
			var dense := true
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					var other := cell + Vector2i(dx, dy)
					if not grid.in_bounds(other) or grid.trees[grid.index(other)] == 0:
						dense = false
			if dense:
				best_score = score
				best = cell
	return best
