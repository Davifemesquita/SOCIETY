extends "res://tools/capture_phase255.gd"
## Roteiro de verificação visual do segundo ciclo da cor viva (Fases 260 a 264): a vila do primeiro ciclo (semente 1840, às
## 10h30) e mais as vistas que ele não cobria: os campos de perto, a falésia de pedra, a primeira ilha tropical e a vila no fim
## da tarde (18h), no começo da manhã (6h15) e à noite (22h). Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 90000 res://tools/capture_phase260.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var world := game.simulation.world
	var grid := world.island(Simulation.MAIN_ISLAND)
	await _shot(game, "01_vila_de_cima.png", points[0], 110.0, 0.6)
	await _shot(game, "02_campos_de_perto.png", points[1], 55.0, PI + 0.6)
	await _shot(game, "03_falesia.png", grid.cell_world(_find_cliff(grid)), 90.0, 0.3)
	for island_id: int in world.islands.size():
		if world.is_tropical(island_id, game.simulation.data):
			var tropical := world.island(island_id)
			await _shot(game, "04_ilha_tropical.png", tropical.cell_world(tropical.size / 2), 260.0, 0.3)
			await _shot(game, "05_tropical_de_perto.png", tropical.cell_world(_find_beach(tropical)), 90.0, 0.3)
			break
	_set_hour(18.0)
	await _shot(game, "06_fim_da_tarde.png", points[0], 110.0, 0.6)
	_set_hour(6.25)
	await _shot(game, "07_manha.png", points[0], 110.0, 0.6)
	_set_hour(22.0)
	# o Sky3D passa a luz ambiente do dia para a da noite em 3 s (contribution_tween_time)
	await get_tree().create_timer(3.5).timeout
	await _shot(game, "08_noite.png", points[0], 110.0, 0.6)
	get_tree().quit()


## Uma célula de terra alta (falésia) encostada no mar, a mais perto do meio da ilha.
func _find_cliff(grid: IslandGrid) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(2, grid.size.y - 2, 2):
		for x: int in range(2, grid.size.x - 2, 2):
			var cell := Vector2i(x, y)
			if not grid.is_land(cell) or grid.cell_height(cell) < 3.0:
				continue
			var coastal := false
			for step: Vector2i in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
				if grid.ground_at(cell + step) == IslandGrid.Ground.SEA:
					coastal = true
			var score := Vector2(cell - grid.size / 2).length()
			if coastal and score < best_score:
				best_score = score
				best = cell
	return best
