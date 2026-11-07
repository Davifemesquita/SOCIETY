extends Node
## Roteiro de verificação visual da Fase 249 (montes de pedra nos campos): na ilha plana, uma fazenda de trigo com os campos
## dela, às 10h, e o monte de pedras no canto de um campo; de perto e de longe. Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase249.tscn -- <pasta>

const STREET_Y := 30

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(10, STREET_Y), Vector2i(50, STREET_Y))))
	# a fazenda de trigo abaixo da rua, com os campos que couberem no raio dela
	var farm := Vector2i(26, STREET_Y + 1)
	_sim.execute(PlaceBuildingCommand.new(0, &"wheat_farm", farm, 0))
	var def := _sim.data.building(&"wheat_farm")
	var module := _sim.data.building(def.module_id)
	var reach := Footprint.rect(farm, def.size, 0).grow(def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - module.size.y + 1):
		for x: int in range(reach.position.x, reach.end.x - module.size.x + 1):
			if placed < def.modules_required and _sim.execute(PlaceBuildingCommand.new(0, def.module_id, Vector2i(x, y),
					0)).ok():
				placed += 1
	await get_tree().process_frame
	_game.building_view.rebuild()
	_game.field_stone_view.rebuild()
	print("montes: ", _game.field_stone_view.heap_count())
	_set_hour(10.0)
	if _game.field_stone_view.places.is_empty():
		get_tree().quit()
		return
	var heap := _game.field_stone_view.places[0]
	await _aimed("pedras_de_perto.png", heap.origin + Vector3(0.0, 0.3, 0.0), 5.0, 0.6 + PI)
	await _aimed("pedras_e_campo.png", heap.origin + Vector3(0.0, 0.5, 0.0), 12.0, 1.4)
	await _aimed("pedras_de_longe.png", heap.origin + Vector3(0.0, 0.5, 0.0), 26.0, -0.5)
	get_tree().quit()


func _aimed(file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	_game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.55, cos(yaw)).normalized() * distance
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
