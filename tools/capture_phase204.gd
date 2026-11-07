extends Node
## Roteiro de verificação visual da Fase 204 (guarda-sol de palha): na semente 1840, o entreposto da maior ilha tropical (achado
## pelo SiteFinder) com os guarda-sóis na areia em volta, às 10h, de perto e de meia distância. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase204.tscn -- <pasta>

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
	var island := -1
	for index: int in sim.world.islands.size():
		if sim.world.is_tropical(index, sim.data) and (island < 0 or sim.world.island(index).size.x > sim.world.island(island).size.x):
			island = index
	if island < 0:
		get_tree().quit()
		return
	var grid := sim.world.island(island)
	sim.free_build = true
	var found := SiteFinder.find(sim, &"trading_post", island, grid.size / 2)
	if found.is_empty():
		get_tree().quit()
		return
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := sim.execute(PlaceBuildingCommand.new(island, &"trading_post", origin, rotation))
	var record := sim.world.building(result.placed[0])
	for frame: int in 5:
		await get_tree().process_frame
	print("guarda-sóis ", game.palapa_view.palapa_count())
	var center := grid.rect_world(Footprint.rect(record.origin, sim.def_of(record).size, record.rotation))
	var shot := 0
	for place: Transform3D in game.palapa_view.places:
		var from_post := (place.origin - center) * Vector3(1.0, 0.0, 1.0)
		await _shot(game, "palapa_%d.png" % shot, place.origin, 8.0, atan2(from_post.x, from_post.z) + 0.6)
		shot += 1
		if shot >= 2:
			break
	if not game.palapa_view.places.is_empty():
		await _shot(game, "palapas_e_entreposto.png", (game.palapa_view.places[0].origin + center) * 0.5, 30.0, 0.8)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
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
