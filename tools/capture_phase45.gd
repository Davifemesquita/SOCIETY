extends Node
## Roteiro de verificação visual da Fase 45: o arquipélago da semente 1840 no gerador v1 e no v2, lado a lado — a
## 1.500 m, a ilha principal a 420 m e a 110 m — e a carta gravada de cada um (o "mapa de cima"). Precisa de GPU; no PC
## do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 40000 res://tools/capture_phase45.tscn -- <pasta>

const SEED := 1840

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	for version: int in [1, 2]:
		var preview := ArchipelagoPreview.new(SEED, 1, GameConfig.get_default(), GameData.get_default(),
				ArchipelagoMap.ENGRAVE_SCALE, version)
		preview.start(false)
		preview.image().save_png(_out_dir.path_join("v%d_carta.png" % version))
		GameScreen.load_slot_on_start = ""
		GameScreen.flat_world = false
		GameScreen.world_seed = SEED
		GameScreen.terrain_version = version
		var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
		add_child(game)
		GameClock.set_speed(TickClock.PAUSED)
		_set_hour(11.0)
		var grid := game.simulation.world.island(0)
		var bounds := game.world_bounds()
		await _shot(game, "v%d_01_arquipelago.png" % version, Vector3(bounds.get_center().x, 0.0, bounds.get_center().y), 1500.0)
		await _shot(game, "v%d_02_ilha_principal.png" % version, grid.cell_world(grid.size / 2), 420.0)
		await _shot(game, "v%d_07_relevo.png" % version, grid.cell_world(grid.size / 2), 110.0)
		remove_child(game)
		game.queue_free()
		await get_tree().process_frame
	GameScreen.terrain_version = -1
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = 0.3
	rig.target_yaw = 0.3
	rig.ground_height = game.simulation.world.surface_height(focus.x, focus.z)
	game.camera.camera.far = maxf(4000.0, distance * 3.0)
	game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
