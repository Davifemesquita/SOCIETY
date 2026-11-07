extends Node
## Roteiro de verificação visual da Fase 56 (rocha nos rochedos e nas falésias): na semente 1840, de perto, dois
## rochedos e dois trechos de falésia da ilha principal, onde a RockView pôs rocha. Precisa de GPU; no PC do dono roda
## na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase56.tscn -- <pasta>

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
	GameScreen.terrain_version = ArchipelagoGenerator.VERSION_V3
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(11.0)
	game.hud.visible = false
	var config := GameConfig.get_default()
	var stacks: Array[Vector3] = []
	var cliffs: Array[Vector3] = []
	var world := game.simulation.world
	for index: int in world.islands.size():
		var region := game.terrain_view.region_heights(index)
		if region.is_empty():
			continue
		var heights: PackedFloat32Array = region["heights"]
		var side: int = region["side"]
		var origin: Vector2 = region["origin"]
		for entry: Array in RockView.places(heights, side, origin, config.cell_size_m, world.island(index),
				config.max_road_relief_m, index):
			var place: Transform3D = entry[1]
			if entry[2] == RockView.Kind.STACK and place.basis.x.length() > 3.0:
				stacks.append(place.origin)
			elif entry[2] == RockView.Kind.CLIFF and index == 0:
				cliffs.append(place.origin)
	print("rochedos ", stacks.size(), " falesias ", cliffs.size())
	for k: int in mini(stacks.size(), 2):
		await _shot(game, "rochedo_%d.png" % k, stacks[k * (stacks.size() - 1)], 70.0, 0.3 + k * 2.0)
	for k: int in mini(cliffs.size(), 2):
		await _shot(game, "falesia_%d.png" % k, cliffs[k * (cliffs.size() / 2)], 55.0, 0.3 + k * 2.0)
	GameScreen.terrain_version = -1
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
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
