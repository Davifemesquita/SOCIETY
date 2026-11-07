extends Node
## Roteiro de verificação visual da Fase 128 (jazidas à vista): na semente 1840, cada mancha de jazida livre da ilha
## principal (carvão e ferro) e a da maior ilha tropical (ouro), de longe e de perto, às 11h. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase128.tscn -- <pasta>

const SEED := 1840
const SHOTS := 3

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
	print("afloramentos ", game.deposit_view.count(DepositView.Kind.OUTCROP), " pedras ", game.deposit_view.count(DepositView.Kind.ORE))
	var shot := 0
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for patch: Array in DepositView.patches(grid):
			if shot >= SHOTS:
				break
			var good: StringName = patch[0]
			var cells: Array = patch[1]
			var first: Vector2i = cells[cells.size() / 2]
			# as árvores em volta da mancha caem para a câmera ver
			var clearing := Rect2i(first, Vector2i.ONE).grow(8)
			var felled: Array[Vector2i] = []
			for y: int in range(clearing.position.y, clearing.end.y):
				for x: int in range(clearing.position.x, clearing.end.x):
					if grid.in_bounds(Vector2i(x, y)):
						felled.append(Vector2i(x, y))
			if grid.clear_trees(felled):
				EventBus.trees_changed.emit(island_id, clearing)
			await get_tree().process_frame
			var at := grid.cell_world(first)
			await _shot(game, "jazida_%s.png" % good, at, 26.0, 0.6)
			await _shot(game, "jazida_%s_de_perto.png" % good, at, 11.0, 1.4)
			shot += 1
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
