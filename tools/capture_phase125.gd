extends Node
## Roteiro de verificação visual da Fase 125 (recife de coral): na semente 1840, a costa da maior ilha tropical vista de
## longe e de perto às 11h, e a de uma ilha temperada para comparar (sem recife). Precisa de GPU; no PC do dono roda na
## área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase125.tscn -- <pasta>

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
	_set_hour(11.0)
	game.hud.visible = false
	var world := game.simulation.world
	var data := game.simulation.data
	var tropical := -1
	for index: int in world.islands.size():
		if world.is_tropical(index, data) and (tropical < 0 or world.island(index).size.x > world.island(tropical).size.x):
			tropical = index
	if tropical < 0:
		get_tree().quit()
		return
	for shot: Array in [[tropical, "recife"], [Simulation.MAIN_ISLAND, "sem_recife"]]:
		var island: int = shot[0]
		var grid := world.island(island)
		var shore := _shore(grid)
		await _shot(game, "%s.png" % shot[1], shore, 90.0, 0.4)
		await _shot(game, "%s_de_perto.png" % shot[1], shore, 40.0, 0.4)
	get_tree().quit()


## Um ponto do mar raso junto da costa, ao sul do meio da ilha (a primeira célula de mar descendo do meio).
func _shore(grid: IslandGrid) -> Vector3:
	var x := grid.size.x / 2
	for y: int in range(grid.size.y / 2, grid.size.y):
		if grid.ground_at(Vector2i(x, y)) == IslandGrid.Ground.SEA:
			return grid.cell_world(Vector2i(x, mini(y + 8, grid.size.y - 1)))
	return grid.cell_world(Vector2i(x, grid.size.y - 1))


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
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
