extends Node
## Roteiro de verificação visual da Fase 254 (canoas na margem do rio): na semente 1840, as canoas puxadas para a margem baixa dos
## rios, de perto, de lado e de meia distância. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase254.tscn -- <pasta>

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
	var shot := 0
	print("canoas: ", game.canoe_view.canoe_count())
	for place: Transform3D in game.canoe_view.places:
		var side := atan2(place.basis.x.x, place.basis.x.z)
		await _shot(game, "canoa_%d.png" % shot, place.origin, 6.0, side + 0.4)
		await _shot(game, "canoa_%d_de_lado.png" % shot, place.origin, 5.0, side + PI - 0.3)
		await _shot(game, "canoa_%d_longe.png" % shot, place.origin, 18.0, side + 0.8)
		shot += 1
		if shot >= 3:
			break
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
