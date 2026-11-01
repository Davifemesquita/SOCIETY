extends Node
## Roteiro de verificação visual da Fase 232 (tapete na janela): na ilha plana, uma rua de casas por classe, às 10h, e os
## tapetes nos peitoris das casas dos operários e artesãos; de perto (a câmera posta à mão) e de longe. Precisa de GPU; no PC do
## dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase232.tscn -- <pasta>

const TIERS: Array[StringName] = [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]
const HOUSES := 12
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
	_game.window_rug_view.rebuild()
	print("tapetes: ", _game.window_rug_view.rug_count())
	var shot := 0
	for place: Transform3D in _game.window_rug_view.places:
		var out := place.basis.z
		await _aimed("tapete_%d.png" % shot, place.origin + out * 4.5 - place.basis.x * 2.0 + Vector3(0.0, 0.3, 0.0),
				place.origin - Vector3(0.0, 0.4, 0.0))
		shot += 1
		if shot >= 3:
			break
	await _aimed("tapetes_na_rua.png", streets[1] + Vector3(-6.0, 9.0, 14.0), streets[1] + Vector3(0.0, 3.0, -3.0))
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
