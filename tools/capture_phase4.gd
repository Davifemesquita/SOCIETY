extends Node
## Roteiro de verificação visual da Fase 4 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 6000 res://tools/capture_phase4.tscn -- <pasta>
## Vila de demonstração com a economia andando: o céu e as janelas em seis horas do dia, a
## multidão de perto, de longe e à noite, e as janelas com as luzes de área de perto.

const MINUTES := 10
## Horas capturadas, com o nome do arquivo.
const HOURS: Dictionary[String, float] = {"01_amanhecer": 5.8, "02_meio_dia": 12.0, "03_fim_de_tarde": 17.6,
		"04_por_do_sol": 18.6, "05_noite": 22.5, "06_madrugada": 2.0}

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	# a vila de demonstração é montada na ilha plana de antes
	GameScreen.flat_world = true
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	DemoVillage.build(_sim)
	_sim.run_ticks(roundi(MINUTES * 60.0 / _sim.config.tick_interval()))
	GameClock.clock.tick_count = _sim.world.tick
	var rig := _game.camera.rig
	rig.focus = Vector3(200, 0, 40)
	rig.distance = 120.0
	_game.camera.apply()
	for file_name: String in HOURS:
		_set_hour(HOURS[file_name])
		await _capture(file_name + ".png")
	_set_hour(10.0)
	# a multidão anda no tempo visual: deixa a rotina correr um pouco antes do close
	for second: int in 90:
		_game.pedestrian_view.crowd.update(1.0, GameClock.clock.hour())
	print("pedestres: %d na multidão, %d à vista" % [_game.pedestrian_view.crowd.agent_count(), _game.pedestrian_view.crowd.visible_count()])
	# rua da produção vista do sul: os campos na frente são baixos e não tapam a calçada
	rig.yaw = 0.0
	rig.target_yaw = 0.0
	rig.focus = Vector3(112, 0, 52)
	rig.distance = 20.0
	_game.camera.apply()
	await _capture("07_multidao_perto.png")
	rig.focus = Vector3(130, 0, 40)
	rig.distance = 75.0
	_game.camera.apply()
	await _capture("08_multidao_media.png")
	_set_hour(21.5)
	await _capture("09_multidao_noite.png")
	rig.focus = Vector3(112, 0, 50)
	rig.distance = 38.0
	_game.camera.apply()
	await _capture("10_janelas_e_luzes_perto.png")
	get_tree().quit()


## Põe o relógio do dia na hora pedida sem mexer na economia.
func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)


func _capture(file_name: String) -> void:
	for frame: int in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


## Onde está o primeiro pedestre andando (o close da multidão).
func _walking_spot() -> Vector3:
	var crowd := _game.pedestrian_view.crowd
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.state == Crowd.State.WALKING:
			return crowd.position_of(agent)
	return Vector3(200, 0, 40)
