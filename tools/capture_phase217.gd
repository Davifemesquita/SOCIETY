extends Node
## Roteiro de verificação visual da Fase 217 (cortinas nas janelas): na ilha plana, uma rua de casas por classe, às 10h, e as
## cortinas nas janelas; de perto (a câmera posta à mão na rua, olhando as fachadas) e de longe. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase217.tscn -- <pasta>

const TIERS: Array[StringName] = [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]
const HOUSES := 5
const STREET_STEP := 9
const ORIGIN := Vector2i(20, 20)

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	_sim.ignore_terrain = true
	_game.hud.visible = false
	var grid := _sim.world.island(0)
	var streets: Array[Vector3] = []
	for row: int in TIERS.size():
		var street_y := ORIGIN.y + row * STREET_STEP + 3
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(ORIGIN.x, street_y),
				Vector2i(ORIGIN.x + HOUSES * 3 + 1, street_y))))
		for i: int in HOUSES:
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(ORIGIN.x + 1 + i * 3, street_y - 3), 2))
			if result.ok():
				_sim.world.building(result.placed[0]).tier = TIERS[row]
				_sim.world.building(result.placed[0]).residents = 5.0
		streets.append(grid.cell_world(Vector2i(ORIGIN.x + HOUSES * 3 / 2, street_y)))
	_game.building_view.rebuild()
	_set_hour(10.0)
	for row: int in TIERS.size():
		var street := streets[row]
		# na rua, olhando as fachadas da frente (as casas ficam em −z da rua)
		await _aimed("cortinas_%s.png" % TIERS[row], street + Vector3(-3.0, 3.0, 4.5), street + Vector3(0.5, 3.2, -3.5))
	await _aimed("cortinas_de_longe.png", streets[2] + Vector3(-10.0, 12.0, 16.0), streets[2] + Vector3(0.0, 3.0, -3.0))
	get_tree().quit()


func _aimed(file_name: String, eye: Vector3, at: Vector3) -> void:
	_game.camera.set_process(false)
	_game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
