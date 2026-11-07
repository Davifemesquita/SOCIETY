extends Node
## Roteiro de verificação visual da Fase 234 (fogareiro de castanhas): na ilha plana, uma rua calçada com várias ruas de través,
## às 10h e às 21h30, e os fogareiros nos cantos das esquinas; de perto, de dia e de noite, e de longe. Precisa de GPU;
## no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase234.tscn -- <pasta>

const STREET := 20

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(2, STREET), Vector2i(60, STREET)), true))
	for x: int in range(8, 58, 5):
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(x, STREET - 8), Vector2i(x, STREET + 8)), true))
	for x: int in range(9, 57, 5):
		for y: int in [STREET - 4, STREET + 1]:
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(x + 1, y), 0 if y > STREET else 2))
			if result.ok():
				_sim.world.building(result.placed[0]).tier = &"artisans"
				_sim.world.building(result.placed[0]).residents = 5.0
	_game.building_view.rebuild()
	_game.chestnut_roaster_view.rebuild()
	print("fogareiros: ", _game.chestnut_roaster_view.roaster_count())
	if _game.chestnut_roaster_view.places.is_empty():
		get_tree().quit()
		return
	var cart := _game.chestnut_roaster_view.places[0]
	var at := cart.origin + Vector3(0.0, 0.7, 0.0)
	var front := -cart.basis.z
	_set_hour(10.0)
	await _aimed("fogareiro_de_perto.png", at + front * 3.0 + cart.basis.x * 1.5 + Vector3(0.0, 1.6, 0.0), at)
	await _aimed("fogareiro_na_esquina.png", at + front * 9.0 + cart.basis.x * 5.0 + Vector3(0.0, 7.0, 0.0), at)
	_set_hour(21.5)
	await _aimed("fogareiro_de_noite.png", at + front * 3.0 + cart.basis.x * 1.5 + Vector3(0.0, 1.6, 0.0), at)
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
