extends "res://tools/capture_phase255.gd"
## Roteiro de verificação visual da Fase 274 (girassóis): a vila do ciclo da cor (semente 1840, 10h30); os girassóis encostados
## nas casas, de perto e de meia distância. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase274.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var flowers: Array[Vector3] = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(sim.world, sim.data, sim.config, Simulation.MAIN_ISLAND, Vector2i(cx, cy))
			for item: Array in items[ScatterView.Kind.SUNFLOWER]:
				var place: Transform3D = item[0]
				flowers.append(place.origin)
	print("girassóis: ", flowers.size())
	flowers.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(points[0]) < b.distance_to(points[0]))
	for k: int in mini(2, flowers.size()):
		await _shot(game, "girassol_%d.png" % k, flowers[k], 7.0, 0.6 + 2.0 * k)
	await _shot(game, "girassois_vila.png", points[0], 42.0, 0.6)
	get_tree().quit()
