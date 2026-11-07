extends "res://tools/capture_phase285.gd"
## Roteiro de verificação visual do ciclo da rocha e da costa (Fases 290 a 294): na semente 1840, às 10h30, a falésia sobre o mar
## de perto e de meia distância, o barranco aberto do ciclo do prado, a costa baixa de pedra e a encosta íngreme mais perto da
## vila. As mesmas vistas antes e depois de cada fase. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase290.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	var cliff := grid.cell_world(_find_cliff(grid))
	await _shot(game, "01_falesia_de_perto.png", cliff, 45.0, 0.3)
	await _shot(game, "02_falesia.png", cliff, 90.0, 0.3)
	var meadow := grid.cell_world(_find_meadow(grid, points[0]))
	await _shot(game, "03_barranco.png", grid.cell_world(_find_bank(grid, meadow)), 35.0, 0.6)
	var rocky := grid.cell_world(_find_rocky_shore(grid))
	await _shot(game, "04_costa_de_pedra.png", rocky, 40.0, 0.3)
	await _shot(game, "05_costa_de_pedra_de_lado.png", rocky, 40.0, 0.3 + PI * 0.5)
	await _shot(game, "06_encosta.png", grid.cell_world(_find_steep(grid, points[0])), 60.0, 0.6)
	get_tree().quit()


## A célula de terra baixa (até 2 m) encostada no mar, com o desnível de rocha (1,2 m ou mais) e sem árvore, mais perto do meio
## da ilha: a costa de pedra.
func _find_rocky_shore(grid: IslandGrid) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(2, grid.size.y - 2):
		for x: int in range(2, grid.size.x - 2):
			var cell := Vector2i(x, y)
			if not grid.is_land(cell) or grid.cell_height(cell) > 2.0 or grid.trees[grid.index(cell)] > 0:
				continue
			if grid.area_relief(Rect2i(cell, Vector2i.ONE)) < 1.2:
				continue
			if not grid.area_touches(Rect2i(cell, Vector2i.ONE), IslandGrid.Ground.SEA):
				continue
			var score := Vector2(cell - grid.size / 2).length()
			if score < best_score:
				best_score = score
				best = cell
	return best


## A célula de encosta íngreme (desnível de 2,5 m ou mais na célula, sem árvore) mais perto do ponto, a 40 m dele no mínimo.
func _find_steep(grid: IslandGrid, near: Vector3) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(2, grid.size.y - 2):
		for x: int in range(2, grid.size.x - 2):
			var cell := Vector2i(x, y)
			if not grid.is_land(cell) or grid.trees[grid.index(cell)] > 0:
				continue
			var score := grid.cell_world(cell).distance_to(near)
			if score < 40.0 or score >= best_score:
				continue
			if grid.area_relief(Rect2i(cell, Vector2i.ONE)) >= 2.5:
				best_score = score
				best = cell
	return best
