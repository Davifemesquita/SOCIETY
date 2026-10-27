extends Node
## Roteiro de verificação visual da Fase 57 (pedras soltas com a rocha gerada): na semente 1840, de perto, três pedras
## soltas que a TreeView pôs em barranco ou no litoral rochoso. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase57.tscn -- <pasta>

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
	var first := TreeView.BROADLEAF.size() + TreeView.CONIFER.size()
	var rocks: Array[Vector3] = []
	for node: Node in game.tree_view.get_children():
		var layer := node as MultiMeshInstance3D
		if layer == null or not layer.name.begins_with("Trees"):
			continue
		var model := int(String(layer.name).trim_prefix("Trees"))
		if model < first or model >= first + TreeView.ROCKS:
			continue
		for i: int in layer.multimesh.instance_count:
			var origin := layer.multimesh.get_instance_transform(i).origin
			if _clear(game.simulation.world, origin):
				rocks.append(origin)
	print("pedras soltas ", rocks.size())
	for k: int in mini(rocks.size(), 3):
		await _shot(game, "pedra_%d.png" % k, rocks[k * (rocks.size() / 3)], 28.0,0.4 + k * 2.0)
	GameScreen.terrain_version = -1
	get_tree().quit()


## Sem árvore a até 6 células da pedra (a câmera não fica atrás da copa).
func _clear(world: WorldState, origin: Vector3) -> bool:
	for index: int in world.islands.size():
		var grid := world.island(index)
		var cell := grid.world_to_cell(origin)
		if not grid.in_bounds(cell):
			continue
		for y: int in range(cell.y - 6, cell.y + 7):
			for x: int in range(cell.x - 6, cell.x + 7):
				if grid.in_bounds(Vector2i(x, y)) and grid.trees[grid.index(Vector2i(x, y))] > 0:
					return false
		return true
	return false


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
