extends Node
## Roteiro de verificação visual da Fase 52 (ilhas v3: alongadas, enseadas com praia, falésias e rochedos): a carta de
## algumas sementes e, na semente 1840, o arquipélago a 1.500 m, a ilha principal a 520 m, uma enseada e um cabo de
## perto. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase52.tscn -- <pasta>

const SEED := 1840
const CHART_SEEDS: Array[int] = [1840, 5, 777, 42, 2026, 31337]

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	for seed_value: int in CHART_SEEDS:
		var preview := ArchipelagoPreview.new(seed_value, 1, GameConfig.get_default(), GameData.get_default(),
				ArchipelagoMap.ENGRAVE_SCALE, ArchipelagoGenerator.VERSION_V3)
		preview.start(false)
		preview.image().save_png(_out_dir.path_join("carta_%d.png" % seed_value))
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	GameScreen.terrain_version = ArchipelagoGenerator.VERSION_V3
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(11.0)
	game.hud.visible = false
	var grid := game.simulation.world.island(0)
	var bounds := game.world_bounds()
	await _shot(game, "01_arquipelago.png", Vector3(bounds.get_center().x, 0.0, bounds.get_center().y), 1500.0, 0.3)
	await _shot(game, "02_ilha_principal.png", grid.cell_world(grid.size / 2), 520.0, 0.3)
	var beach := _find_coast(grid, true)
	var cliff := _find_coast(grid, false)
	await _shot(game, "03_enseada.png", grid.cell_world(beach), 140.0, 0.3)
	await _shot(game, "04_falesia.png", grid.cell_world(cliff), 110.0, 0.3)
	GameScreen.terrain_version = -1
	get_tree().quit()


## Uma célula de terra encostada no mar: baixa (praia) ou alta (falésia), a mais perto do meio entre as que servem.
func _find_coast(grid: IslandGrid, low: bool) -> Vector2i:
	var best := grid.size / 2
	var best_score := INF
	for y: int in range(2, grid.size.y - 2, 2):
		for x: int in range(2, grid.size.x - 2, 2):
			var cell := Vector2i(x, y)
			if not grid.is_land(cell):
				continue
			var coastal := false
			for step: Vector2i in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
				if grid.ground_at(cell + step) == IslandGrid.Ground.SEA:
					coastal = true
			if not coastal:
				continue
			var height := grid.cell_height(cell)
			if (low and height > 1.5) or (not low and height < 3.0):
				continue
			var score := Vector2(cell - grid.size / 2).length()
			if score < best_score:
				best_score = score
				best = cell
	return best


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = game.simulation.world.surface_height(focus.x, focus.z)
	game.camera.camera.far = maxf(4000.0, distance * 3.0)
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
