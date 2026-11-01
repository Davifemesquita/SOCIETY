extends Node
## Roteiro de verificação visual da Fase 176 (cegonha na chaminé): na ilha plana, uma rua de casas de camponeses e uma de
## operários às 10h, com os ninhos nas chaminés; fotos de longe, da rua e de perto. Precisa de GPU; no PC do dono roda na área
## de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase176.tscn -- <pasta>

const TIERS: Array[StringName] = [&"peasants", &"workers"]
const HOUSES_PER_STREET := 12
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
	for row: int in TIERS.size():
		var street_y := ORIGIN.y + row * 9 + 3
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(ORIGIN.x, street_y),
				Vector2i(ORIGIN.x + HOUSES_PER_STREET * 3 + 1, street_y))))
		for i: int in HOUSES_PER_STREET:
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(ORIGIN.x + 1 + i * 3, street_y - 3), 2))
			if result.ok():
				_sim.world.building(result.placed[0]).tier = TIERS[row]
				_sim.world.building(result.placed[0]).residents = 5.0
	_game.building_view.rebuild()
	_game.stork_view.rebuild()
	_game.chimney_smoke_view.rebuild()
	print("cegonhas: ", _game.stork_view.stork_count())
	_set_hour(9.0)
	var middle := grid.cell_world(Vector2i(ORIGIN.x + HOUSES_PER_STREET * 3 / 2, ORIGIN.y + 6))
	await _shot("cegonhas_de_longe.png", middle, 60.0, 0.4)
	var shot := 0
	for spot: Vector3 in _game.stork_view.spots:
		await _aimed("cegonha_%d.png" % shot, spot, 14.0, 0.5 + shot * 1.7)
		await _aimed("cegonha_%d_de_perto.png" % shot, spot, 5.0, 0.8 + shot * 1.7)
		shot += 1
		if shot >= 2:
			break
	get_tree().quit()


## A câmera da partida fica presa ao chão: para o alto da chaminé, põe a Camera3D à mão, um pouco acima do ninho.
func _aimed(file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	_game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.55, cos(yaw)).normalized() * distance
	_game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
	_game.camera.set_process(true)


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(focus.y, maxf(_sim.world.surface_height(focus.x, focus.z), 0.0))
	_game.camera.apply()
	for frame: int in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
