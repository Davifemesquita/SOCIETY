extends Node
## Roteiro de verificação visual da Fase 58 (coqueiro gerado no código): na semente 1840, os coqueiros de uma ilha
## tropical de perto, de meia distância e de longe (a malha de longe). Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase58.tscn -- <pasta>

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
	var palms: Array[Vector3] = []
	for node: Node in game.tree_view.get_children():
		var layer := node as MultiMeshInstance3D
		if layer != null and layer.name.begins_with("Palm") and not layer.name.ends_with("Far"):
			for i: int in layer.multimesh.instance_count:
				palms.append(layer.multimesh.get_instance_transform(i).origin)
	print("coqueiros ", palms.size())
	if not palms.is_empty():
		var spot := palms[palms.size() / 2]
		await _shot(game, "coqueiro_perto.png", spot, 18.0, 0.4)
		await _shot(game, "coqueiro_meio.png", spot, 60.0, 2.2)
		await _shot(game, "coqueiro_longe.png", spot, 260.0, 4.0)
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
