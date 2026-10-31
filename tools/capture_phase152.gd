extends Node
## Roteiro de verificação visual da Fase 152 (balizas com corrente): na semente 1840, uma escola achada pelo SiteFinder
## na ilha principal, com a rua calçada em volta dela, às 10h: de longe e de perto das balizas.
## Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase152.tscn -- <pasta>

const SEED := 1840

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


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
	sim.free_build = true
	sim.ignore_terrain = true
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	var found := SiteFinder.find(sim, &"school", Simulation.MAIN_ISLAND, grid.size / 2)
	if found.is_empty():
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"school", origin, rotation))
	var record := sim.world.building(result.placed[0])
	# a rua calçada em volta da escola inteira, encostada no largo (o que o relevo deixar)
	var ring := Footprint.rect(record.origin, sim.def_of(record).size, rotation).grow(2)
	var corners: Array[Vector2i] = [ring.position, Vector2i(ring.end.x - 1, ring.position.y), ring.end - Vector2i.ONE,
			Vector2i(ring.position.x, ring.end.y - 1)]
	for k: int in 4:
		sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(corners[k], corners[(k + 1) % 4]), true))
	for frame: int in 3:
		await get_tree().process_frame
	var edges := BollardView.edges(sim.world, sim.data, Simulation.MAIN_ISLAND)
	print("balizas ", game.bollard_view.bollard_count(), " lados ", edges.size())
	var center := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	var out := Vector3(Footprint.front_direction(rotation).x, 0.0, Footprint.front_direction(rotation).y)
	await _shot(game, "largo.png", center + out * 4.0, 34.0, atan2(out.x, out.z) + 0.5, 40.0)
	if not edges.is_empty():
		var edge: Array = edges[0]
		var a: Vector3 = edge[0]
		var b: Vector3 = edge[1]
		var at := (a + b) * 0.5
		var eye := at + out * 3.0 + (a - b).normalized() * 1.5 + Vector3.UP * 1.4
		game.camera.set_process(false)
		game.camera.camera.global_transform = Transform3D(Basis.looking_at(at + Vector3.UP * 0.4 - eye, Vector3.UP), eye)
		for frame: int in 30:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_out_dir.path_join("balizas_de_perto.png"))
		print("capturado balizas_de_perto.png")
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := game.camera.rig
	rig.pitch_offset_deg = pitch
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
