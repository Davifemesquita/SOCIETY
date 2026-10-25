extends Node
## Roteiro de verificação visual da Fase 31 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 12000 res://tools/capture_phase31.tscn -- <pasta>
## A casa subindo no meio do squash & stretch, a casa demolida afundando na poeira e a salva de uma fragata: as balas
## no ar e os respingos em volta do navio atingido, adernado.

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "0")
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = true
	Settings.edge_pan = false
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	var grid := _sim.world.island(Simulation.MAIN_ISLAND)
	_sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", Vector2i(10, 0), 2))
	_place(&"house", Vector2i(22, 12))
	var spot := grid.rect_world(Rect2i(Vector2i(20, 12), Vector2i(6, 3)))
	_aim(spot, 38.0)
	for frame: int in 30:
		await get_tree().process_frame
	# a casa nova no meio do salto: passou do ponto em altura e afinou
	_place(&"house", Vector2i(18, 12))
	await _wait(BuildingView.BUILD_POP_S * 0.5)
	await _save("01_casa_subindo.png")
	await _wait(1.0)
	# a casa demolida afundando na poeira
	_sim.execute(DemolishCommand.new(Simulation.MAIN_ISLAND, Rect2i(Vector2i(22, 12), Vector2i(3, 3))))
	await _wait(BuildingView.DEMOLISH_S * 0.45)
	await _save("02_casa_afundando.png")
	await _wait(1.5)
	# a salva: duas fragatas no mar ao norte da ilha
	var sea := grid.rect_world(Rect2i(Vector2i(10, 0), Vector2i(4, 4))) + Vector3(0.0, 0.0, -70.0)
	var attacker := _ship(Vector2(sea.x - 30.0, sea.z))
	var target := _ship(Vector2(sea.x + 30.0, sea.z))
	_aim(Vector3(sea.x, 0.0, sea.z), 85.0)
	for frame: int in 10:
		await get_tree().process_frame
	EventBus.ship_fired.emit(attacker.id, target.id)
	await _wait(ShipView.BALL_FLIGHT_S * 0.5)
	await _save("03_balas_no_ar.png")
	await _wait(ShipView.BALL_FLIGHT_S * 0.5 + 0.25)
	await _save("04_respingo_e_adernado.png")
	get_tree().quit()


func _place(def_id: StringName, origin: Vector2i) -> int:
	var result := _sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, def_id, origin, 0))
	return result.placed[0] if result.ok() else 0


func _ship(at: Vector2) -> Ship:
	var ship := Ship.new(_sim.world.next_ship_id, _sim.data.ship(&"frigate"))
	_sim.world.next_ship_id += 1
	ship.position = at
	ship.previous_position = at
	ship.heading = PI * 0.5
	ship.previous_heading = ship.heading
	_sim.world.ships[ship.id] = ship
	return ship


func _aim(focus: Vector3, distance: float) -> void:
	var rig := _game.camera.rig
	rig.focus = focus
	rig.distance = distance
	rig.ground_height = focus.y
	_game.camera.apply()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
