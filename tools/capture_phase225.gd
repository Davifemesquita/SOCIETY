extends Node
## Roteiro de verificação visual da Fase 225 (lanterna na popa): na ilha plana, um navio de cada tipo parado no mar ao norte (rumo
## leste, a popa para oeste), a popa de perto de dia e os navios com as lanternas acesas à noite. Precisa de GPU; no PC do dono
## roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase225.tscn -- <pasta>

const SHIPS: Array[StringName] = [&"merchant_ship", &"trader_ship", &"frigate", &"clipper"]

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
	_game.hud.visible = false
	var x := 40.0
	for def_id: StringName in SHIPS:
		var ship := Ship.new(_sim.world.next_ship_id, _sim.data.ship(def_id))
		_sim.world.next_ship_id += 1
		ship.position = Vector2(x, -40.0)
		ship.previous_position = ship.position
		ship.heading = 0.0
		ship.previous_heading = 0.0
		_sim.world.ships[ship.id] = ship
		x += 40.0
	for frame: int in 5:
		await get_tree().process_frame
	_set_hour(10.0)
	var merchant := _sim.data.ship(&"merchant_ship")
	var stern := Vector3(40.0 - merchant.length_m * 0.5, 4.0, -40.0)
	await _aimed("popa_de_dia.png", stern + Vector3(-9.0, 4.0, 6.0), stern)
	_set_hour(21.5)
	await _aimed("popa_de_noite.png", stern + Vector3(-9.0, 4.0, 6.0), stern)
	await _aimed("navios_de_noite.png", Vector3(10.0, 22.0, 10.0), Vector3(100.0, 2.0, -40.0))
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
