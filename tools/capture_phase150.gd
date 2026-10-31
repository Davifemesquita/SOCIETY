extends Node
## Roteiro de verificação visual da Fase 150 (coluna de anúncios): na ilha plana, duas ruas calçadas que se cruzam com casas
## em volta, às 10h e sem a interface, de longe e de perto da coluna. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase150.tscn -- <pasta>

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
	for y: int in [14, 20, 26]:
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(4, y), Vector2i(44, y)), true))
	for x: int in [12, 24, 36]:
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(x, 6), Vector2i(x, 36)), true))
	for x: int in [15, 27]:
		_sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(x, 17), 0))
		_sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(x, 21), 0))
	_game.building_view.rebuild()
	_set_hour(10.0)
	for frame: int in 5:
		await get_tree().process_frame
	var found := AdColumnView.cells(_sim.world, _sim.data, 0)
	print("colunas ", _game.ad_column_view.column_count(), " ", found)
	var grid := _sim.world.island(0)
	if not found.is_empty():
		var cell: Vector2i = found.keys()[0]
		await _shot("esquina.png", grid.cell_world(cell), 24.0, 0.5, 6.0)
		# de perto, com a câmera posta à mão do lado da esquina (a da partida fica presa ao chão e caía nas copas da alameda)
		var corner: Vector2i = found[cell]
		var foot := grid.cell_world(cell) + Vector3(corner.x, 0.0, corner.y) * AdColumnView.CORNER_M
		var eye := foot + Vector3(corner.x * 3.0 + corner.y * 1.5, 1.9, corner.y * 3.0 - corner.x * 1.5)
		var look := foot + Vector3(0.0, 1.5, 0.0)
		# as árvores da alameda tapam a esquina de perto: ficam escondidas só nesta foto
		_game.avenue_view.visible = false
		_game.camera.set_process(false)
		_game.camera.camera.global_transform = Transform3D(Basis.looking_at(look - eye, Vector3.UP), eye)
		for frame: int in 30:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_out_dir.path_join("coluna_de_perto.png"))
		print("capturado coluna_de_perto.png")
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := _game.camera.rig
	rig.pitch_offset_deg = pitch
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 1.2
	_game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
