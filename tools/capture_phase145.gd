extends Node
## Roteiro de verificação visual da Fase 145 (relógio da igreja): na ilha plana, uma igreja com a rua na frente, de longe
## às 10h10 e de perto do mostrador às 10h10 e às 21h45 (aceso). Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase145.tscn -- <pasta>

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(ORIGIN + Vector2i(-4, -1), ORIGIN + Vector2i(10, -1)), true))
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"church", ORIGIN, 0))
	_game.building_view.rebuild()
	for frame: int in 5:
		await get_tree().process_frame
	print("mostradores ", _game.clock_view.dial_count())
	var dial: Transform3D = ClockView.dials(_sim, _sim.world.building(result.placed[0]))[0]
	var church := _sim.world.island(0).rect_world(Rect2i(ORIGIN, Vector2i(5, 5)))
	_set_hour(10.0 + 10.0 / 60.0)
	# a frente da igreja é −Z: a câmera fica desse lado (yaw PI), mirando a torre
	await _shot("igreja.png", church, 46.0, PI + 0.5, 0.0, 8.0)
	# de perto a câmera da partida fica presa ao chão: a Camera3D vai à mão, diante do mostrador
	var eye := dial.origin + dial.basis.z * 6.0 + dial.basis.x * 1.5 - Vector3(0.0, 1.0, 0.0)
	await _close("relogio_de_perto.png", eye, dial.origin)
	_set_hour(21.75)
	await _close("relogio_de_noite.png", eye, dial.origin)
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float, ground: float) -> void:
	var rig := _game.camera.rig
	rig.pitch_offset_deg = pitch
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = ground
	_game.camera.apply()
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _close(file_name: String, eye: Vector3, at: Vector3) -> void:
	_game.camera.set_process(false)
	_game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
	_game.camera.set_process(true)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
