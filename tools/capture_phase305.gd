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
	# Fase 309: o vale com mata mais perto da vila, às 6h30
	var valley := grid.cell_world(_valley(grid, points[0]))
	_set_hour(6.5)
	await _shot(game, "06_vale_de_manha.png", valley, 90.0, 0.6)
	await _shot(game, "07_vale_de_manha_longe.png", valley, 170.0, 2.4)
	get_tree().quit()


## O ponto da rede de 5 células mais perto da vila (a FAR_M dela no mínimo) que fica 0,7 m abaixo da média de oito pontos a 7
## células, com seis células de mata a até 4 (a regra da névoa dos vales da Fase 309, escrita aqui para a captura rodar também
## antes dela).
func _valley(grid: IslandGrid, near: Vector3) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(7, grid.size.y - 7, 5):
		for x: int in range(7, grid.size.x - 7, 5):
			var cell := Vector2i(x, y)
			if grid.ground[grid.index(cell)] != IslandGrid.Ground.LAND:
				continue
			var score := grid.cell_world(cell).distance_to(near)
			if score < FAR_M or score >= best_score:
				continue
			var forest := 0
			for dy: int in range(-4, 5):
				for dx: int in range(-4, 5):
					if grid.trees[grid.index(cell + Vector2i(dx, dy))] > 0:
						forest += 1
			if forest < 6:
				continue
			var around := 0.0
			for k: int in 8:
				var step := Vector2(7.0, 0.0).rotated(TAU * k / 8.0)
				around += grid.cell_height(cell + Vector2i(roundi(step.x), roundi(step.y)))
			if grid.cell_height(cell) <= around / 8.0 - 0.7:
				best_score = score
				best = cell
	return best
