extends "res://tools/capture_phase122.gd"
## Roteiro de verificação visual do ciclo da garganta do rio (Fases 317 a 319): na semente 1840, o trecho de garganta com mais blocos
## caídos (Fase 317) juntos, de cima e de perto, de dois lados, às 10h. As mesmas vistas servem à espuma nas pedras (318) e à
## correnteza (319). Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase317.tscn -- <pasta>

## Raio (m) em que se contam os blocos vizinhos para escolher o trecho.
const CLUSTER_M := 8.0


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(10.0)
	game.hud.visible = false
	var sim := game.simulation
	var blocks: Array[Vector3] = []
	for island_id: int in sim.world.islands.size():
		# só as temperadas: é nelas que está o rio do Anno (cascalho e capim)
		if sim.world.is_tropical(island_id, sim.data):
			continue
		for entry: Array in RiverStoneView.places(sim.world, island_id):
			if entry[2] == RiverStoneView.Kind.FALLEN:
				var place: Transform3D = entry[1]
				blocks.append(place.origin)
	print("blocos caídos ", blocks.size(), " pedras do rio ", game.river_stone_view.stone_count())
	if blocks.is_empty():
		get_tree().quit()
		return
	var best := blocks[0]
	var best_count := -1
	for at: Vector3 in blocks:
		var near := 0
		for other: Vector3 in blocks:
			if Vector2(at.x - other.x, at.z - other.z).length() < CLUSTER_M:
				near += 1
		if near > best_count:
			best_count = near
			best = at
	print("trecho ", best, " com ", best_count, " blocos; chão ", sim.world.surface_height(best.x, best.z))
	var island_id := _island_at(sim.world, best)
	var grid := sim.world.island(island_id)
	var clearing := Rect2i(grid.world_to_cell(best), Vector2i.ONE).grow(CLEARING_CELLS)
	var felled: Array[Vector2i] = []
	for y: int in range(clearing.position.y, clearing.end.y):
		for x: int in range(clearing.position.x, clearing.end.x):
			if grid.in_bounds(Vector2i(x, y)):
				felled.append(Vector2i(x, y))
	if grid.clear_trees(felled):
		EventBus.trees_changed.emit(island_id, clearing)
	for frame: int in 3:
		await get_tree().process_frame
	await _shot(game, "01_garganta.png", best, 30.0, 0.7)
	await _shot(game, "02_garganta_de_perto.png", best, 14.0, 0.7)
	await _shot(game, "03_garganta_do_outro_lado.png", best, 14.0, 0.7 + PI)
	get_tree().quit()
