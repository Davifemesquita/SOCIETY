extends Node
## Roteiro de verificação visual da Fase 136 (vagoneta e rejeito): na semente 1840, uma mina sobre cada uma das primeiras
## manchas de jazida com lugar para o monte (as árvores em volta derrubadas), produzindo, às 11h: de longe, com a vagoneta
## saindo, e de perto, virando o rejeito na ponta. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase136.tscn -- <pasta>

const SEED := 1840
const SHOTS := 2
const MINES: Dictionary[StringName, StringName] = {&"coal": &"coal_mine", &"iron_ore": &"iron_mine", &"gold": &"gold_mine"}

var _out_dir: String
var _clock := 0.0


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
	var sim := game.simulation
	sim.free_build = true
	sim.ignore_terrain = true
	var world := sim.world
	var shot := 0
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for patch: Array in DepositView.patches(grid):
			if shot >= SHOTS:
				break
			var good: StringName = patch[0]
			var cells: Array = patch[1]
			var low := Vector2i(1 << 20, 1 << 20)
			for cell: Vector2i in cells:
				low = low.min(cell)
			# as árvores em volta da mancha caem para a mina, o monte e a câmera
			var clearing := Rect2i(low, Vector2i(6, 6)).grow(8)
			var felled: Array[Vector2i] = []
			for y: int in range(clearing.position.y, clearing.end.y):
				for x: int in range(clearing.position.x, clearing.end.x):
					if grid.in_bounds(Vector2i(x, y)):
						felled.append(Vector2i(x, y))
			if grid.clear_trees(felled):
				EventBus.trees_changed.emit(island_id, clearing)
			var mine: StringName = MINES.get(good, &"coal_mine")
			var result := sim.execute(PlaceBuildingCommand.new(island_id, mine, low + Vector2i(1, 1), 0))
			if not result.ok():
				continue
			var mine_id: int = result.placed[0]
			sim.world.building(mine_id).state = BuildingRecord.State.PRODUCING
			await get_tree().process_frame
			await get_tree().process_frame
			var found := SpoilTipView.sites(world, sim.data, island_id)
			print("mina ", mine_id, " ", good, " monte ", found.has(mine_id))
			if not found.has(mine_id):
				continue
			var site: Array = found[mine_id]
			var first: Vector2i = site[0]
			var at := grid.cell_world(first)
			# a vagoneta a meio caminho e depois virando, pelo adianto da volta dessa mina
			_clock = _move(game, _clock, 2.5 - SpoilTipView.phase_of(mine_id))
			await _shot(game, "mina_%s.png" % good, at, 18.0, 0.7, 0.0)
			_clock = _move(game, _clock, SpoilTipView.OUT_S + SpoilTipView.TIP_S * 0.5 - SpoilTipView.phase_of(mine_id))
			await _shot(game, "mina_%s_virando.png" % good, at, 8.0, 1.3, 18.0)
			shot += 1
	print("montes ", game.spoil_tip_view.tip_count())
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := game.camera.rig
	rig.pitch_offset_deg = pitch
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


## Anda o relógio da vista até o instante da volta target (mod CYCLE_S) e devolve o relógio novo.
func _move(game: GameScreen, clock: float, target: float) -> float:
	var step := fposmod(target - clock, SpoilTipView.CYCLE_S)
	game.spoil_tip_view.advance(step)
	return clock + step


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
