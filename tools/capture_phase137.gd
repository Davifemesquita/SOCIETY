extends Node
## Roteiro de verificação visual da Fase 137 (boca do forno acesa): na ilha plana, a fundição e a padaria produzindo e a
## vidraria parada, de perto às 10h e às 21h e as três de longe à noite. Precisa de GPU; no PC do dono roda na área de
## trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase137.tscn -- <pasta>

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
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(ORIGIN + Vector2i(-2, -1), ORIGIN + Vector2i(30, -1))))
	var furnace: int = _sim.execute(PlaceBuildingCommand.new(0, &"furnace", ORIGIN, 0)).placed[0]
	var glass: int = _sim.execute(PlaceBuildingCommand.new(0, &"glassworks", ORIGIN + Vector2i(10, 0), 0)).placed[0]
	var bakery: int = _sim.execute(PlaceBuildingCommand.new(0, &"bakery", ORIGIN + Vector2i(19, 0), 0)).placed[0]
	for id: int in [furnace, bakery]:
		_sim.world.building(id).state = BuildingRecord.State.PRODUCING
	_sim.world.building(glass).state = BuildingRecord.State.NO_INPUT
	_game.building_view.rebuild()
	for frame: int in 5:
		await get_tree().process_frame
	_game.furnace_glow_view.refresh_state()
	print("bocas ", _game.furnace_glow_view.mouth_count(), " acesas ", _game.furnace_glow_view.lit_count())
	_set_hour(10.0)
	await _mouth_shot("forno_de_dia.png", furnace, 7.0)
	await _mouth_shot("vidraria_parada.png", glass, 7.0)
	_set_hour(21.0)
	await _mouth_shot("forno_de_noite.png", furnace, 7.0)
	await _mouth_shot("padaria_de_noite.png", bakery, 6.0)
	var grid := _sim.world.island(0)
	await _shot("fabricas_de_noite.png", grid.cell_world(ORIGIN + Vector2i(12, 3)), 34.0, 1.2, 0.0)
	get_tree().quit()


## De frente para a boca do forno do prédio, um pouco de lado.
func _mouth_shot(file_name: String, building_id: int, distance: float) -> void:
	var mouth: Transform3D = FurnaceGlowView.mouth(_sim, _sim.world.building(building_id))
	var out := mouth.basis.z.normalized()
	await _shot(file_name, mouth.origin + out * 0.5, distance, atan2(out.x, out.z) + 0.4, 6.0)


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float, pitch: float) -> void:
	var rig := _game.camera.rig
	rig.pitch_offset_deg = pitch
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = 0.0
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
