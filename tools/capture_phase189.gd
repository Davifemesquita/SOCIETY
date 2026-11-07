extends Node
## Roteiro de verificação visual da Fase 189 (focas nas pedras): na semente 1840, os grupos de focas da costa das ilhas
## temperadas, de perto e de meia distância, da terra para o mar, uma com as cabeças erguidas. Precisa de GPU; no
## PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase189.tscn -- <pasta>

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
	var shot := 0
	print("focas: ", game.seal_view.seal_count())
	for island_id: int in sim.world.islands.size():
		var grid := sim.world.island(island_id)
		var found := SealView.colonies(sim.world, sim.data, island_id)
		for cell: Vector2i in found:
			var sea := found[cell]
			var at := grid.cell_world(cell)
			# a câmera do lado de terra, olhando para o mar
			var yaw := atan2(-float(sea.x), -float(sea.y))
			await _shot(game, "focas_%d.png" % shot, at, 8.0, yaw + 0.5)
			game.seal_view.advance(7.0)
			await _shot(game, "focas_%d_cabecas.png" % shot, at, 8.0, yaw + 0.5)
			await _shot(game, "focas_%d_longe.png" % shot, at, 22.0, yaw + 0.3)
			shot += 1
			if shot >= 3:
				break
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
