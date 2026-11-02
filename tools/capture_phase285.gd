extends "res://tools/capture_phase280.gd"
## Roteiro de verificação visual do ciclo do prado (Fases 285 a 289): na semente 1840, às 10h30, o prado aberto (a célula de
## capim livre mais longe de mata, prédio e água perto do meio da ilha principal) de perto, de meia distância e de cima, um
## canteiro de papoulas e a borda de cima de um barranco. As mesmas vistas antes e depois de cada fase. Precisa de GPU; no PC
## do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase285.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var world := game.simulation.world
	var grid := world.island(Simulation.MAIN_ISLAND)
	var meadow := grid.cell_world(_find_meadow(grid, points[0]))
	await _shot(game, "01_prado_de_perto.png", meadow, 28.0, 0.6)
	await _shot(game, "02_prado.png", meadow, 70.0, 0.6)
	await _shot(game, "03_prado_de_cima.png", meadow, 160.0, 0.6)
	var poppies := _find_poppies(game, meadow)
	await _shot(game, "04_papoulas.png", poppies, 30.0, 0.6)
	await _shot(game, "05_barranco.png", grid.cell_world(_find_bank(grid, meadow)), 40.0, 0.6)
	get_tree().quit()


## A célula de capim aberto (terra sem árvore, prédio nem estrada a três células, desnível pequeno) mais perto do ponto, mas a
## 50 m dele no mínimo (fora da vila).
func _find_meadow(grid: IslandGrid, near: Vector3) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(4, grid.size.y - 4, 2):
		for x: int in range(4, grid.size.x - 4, 2):
			var cell := Vector2i(x, y)
			var score := grid.cell_world(cell).distance_to(near)
			if score < 50.0 or score >= best_score:
				continue
			if grid.area_relief(Rect2i(cell - Vector2i(3, 3), Vector2i(7, 7))) > 1.0:
				continue
			var open := true
			for dy: int in range(-3, 4):
				for dx: int in range(-3, 4):
					var index := grid.index(cell + Vector2i(dx, dy))
					if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
							or grid.roads[index] != 0:
						open = false
			if open:
				best_score = score
				best = cell
	return best


## O canteiro de papoulas do recheio mais perto do ponto (o próprio ponto se não houver).
func _find_poppies(game: GameScreen, near: Vector3) -> Vector3:
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var best := near
	var best_score := INF
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(sim.world, sim.data, sim.config, Simulation.MAIN_ISLAND, Vector2i(cx, cy))
			for item: Array in items[ScatterView.Kind.POPPIES]:
				var place: Transform3D = item[0]
				var score := place.origin.distance_to(near)
				if score < best_score:
					best_score = score
					best = place.origin
	return best


## A célula de terra na borda de cima de um barranco (a vizinha a duas células, para algum lado, 2 m ou mais abaixo) mais perto
## do ponto.
func _find_bank(grid: IslandGrid, near: Vector3) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(3, grid.size.y - 3):
		for x: int in range(3, grid.size.x - 3):
			var cell := Vector2i(x, y)
			if not grid.is_land(cell) or grid.trees[grid.index(cell)] > 0:
				continue
			var score := grid.cell_world(cell).distance_to(near)
			if score >= best_score:
				continue
			var top := grid.cell_height(cell)
			for step: Vector2i in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				if grid.is_land(cell + step) and top - grid.cell_height(cell + step) >= 2.0:
					best_score = score
					best = cell
					break
	return best
