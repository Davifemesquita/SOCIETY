extends Node
## Roteiro de verificação visual da Fase 227 (lamaçal do chiqueiro): na ilha plana, uma fazenda de porcos com os pastos em volta,
## às 10h, e a poça de lama em cada pasto; de perto e de cima. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase227.tscn -- <pasta>

const FARM_AT := Vector2i(30, 30)

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
	_sim.execute(PlaceBuildingCommand.new(0, &"pig_farm", FARM_AT, 0))
	var def := _sim.data.building(&"pig_farm")
	var reach := Footprint.rect(FARM_AT, def.size, 0).grow(def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if placed < def.modules_required and _sim.execute(PlaceBuildingCommand.new(0, def.module_id, Vector2i(x, y),
					0)).ok():
				placed += 1
	_game.building_view.rebuild()
	for frame: int in 5:
		await get_tree().process_frame
	_game.mud_wallow_view.rebuild()
	print("lamaçais: ", _game.mud_wallow_view.wallow_count())
	_set_hour(10.0)
	if _game.mud_wallow_view.places.is_empty():
		get_tree().quit()
		return
	var mud := _game.mud_wallow_view.places[0].origin
	await _aimed("lama_de_perto.png", mud + Vector3(4.0, 3.5, 5.0), mud)
	await _aimed("lama_no_pasto.png", mud + Vector3(10.0, 12.0, 14.0), mud)
	var farm := _sim.world.island(0).cell_world(FARM_AT)
	await _aimed("lama_de_cima.png", farm + Vector3(6.0, 34.0, 22.0), farm)
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
