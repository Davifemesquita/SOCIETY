extends Node
## Roteiro de verificação visual das Fases 95 a 99 (formas mais redondas): na ilha plana (o terreno não importa aqui),
## uma rua de casas por classe e uma rua de serviços e fábricas, às 10h; fotos de perto de cada rua, dos dois lados, e
## uma de cima. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase95.tscn -- <pasta>

const TIERS: Array[StringName] = [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]
const HOUSES_PER_STREET := 6
const STREET_STEP := 9
const ORIGIN := Vector2i(20, 20)
## A rua dos prédios grandes: serviços (telhado de quatro águas, campanário) e fábricas (lanternim, fumaça).
const BIG: Array[StringName] = [&"church", &"market", &"theater", &"university", &"brewery", &"furnace", &"warehouse",
		&"weavery", &"distillery"]

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
	var grid := _sim.world.island(0)
	var streets: Array[Vector2i] = []
	for row: int in TIERS.size():
		var street_y := ORIGIN.y + row * STREET_STEP + 3
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(ORIGIN.x, street_y),
				Vector2i(ORIGIN.x + HOUSES_PER_STREET * 3 + 1, street_y))))
		for i: int in HOUSES_PER_STREET:
			var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(ORIGIN.x + 1 + i * 3, street_y - 3), 2))
			if result.ok():
				_sim.world.building(result.placed[0]).tier = TIERS[row]
				# Fase 100: com morador (a chaminé só fumega em casa habitada)
				_sim.world.building(result.placed[0]).residents = 5.0
		streets.append(Vector2i(ORIGIN.x + HOUSES_PER_STREET * 3 / 2, street_y))
	# a rua dos prédios grandes, abaixo das casas
	var big_y := ORIGIN.y + TIERS.size() * STREET_STEP + 3
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(ORIGIN.x, big_y), Vector2i(ORIGIN.x + 70, big_y))))
	var x := ORIGIN.x + 1
	for def_id: StringName in BIG:
		var def := _sim.data.building(def_id)
		if def == null:
			continue
		var size := Footprint.rotated_size(def.size, 2)
		_sim.execute(PlaceBuildingCommand.new(0, def_id, Vector2i(x, big_y - size.y), 2))
		x += size.x + 1
	_game.building_view.rebuild()
	_set_hour(10.0)
	for row: int in TIERS.size():
		var at := grid.cell_world(streets[row] + Vector2i(0, -2))
		await _shot("rua_%s_a.png" % TIERS[row], at, 40.0, 0.0)
		await _shot("rua_%s_b.png" % TIERS[row], at, 40.0, PI)
		# Fase 96: em diagonal, para ver os volumes (a ala mais baixa e o telhado cruzado)
		await _shot("rua_%s_c.png" % TIERS[row], at, 34.0, PI * 0.75)
	var big_at := grid.cell_world(Vector2i(ORIGIN.x + 20, big_y - 3))
	await _shot("grandes_a.png", big_at, 60.0, 0.0)
	await _shot("grandes_b.png", grid.cell_world(Vector2i(ORIGIN.x + 45, big_y - 3)), 60.0, 0.0)
	# Fase 98: o mercado de lado (o arco da abóbada) e a tecelagem e a destilaria de perto (a abóbada e os tonéis)
	await _shot("mercado_de_lado.png", grid.cell_world(Vector2i(ORIGIN.x + 9, big_y - 2)), 26.0, PI * 0.2)
	await _shot("fabricas_de_perto.png", grid.cell_world(Vector2i(ORIGIN.x + 47, big_y - 2)), 30.0, PI * 0.2)
	await _shot("telhado_de_perto.png", grid.cell_world(streets[2] + Vector2i(0, -2)), 18.0, 0.4)
	# Fase 100: a fumaça das chaminés na hora do fogão aceso
	_set_hour(7.5)
	await _shot("fumaca_manha.png", grid.cell_world(streets[1] + Vector2i(0, -2)), 34.0, 0.5)
	_set_hour(10.0)
	await _shot("de_cima.png", grid.cell_world(streets[2]), 140.0, 0.0)
	get_tree().quit()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.target_distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(_sim.world.surface_height(focus.x, focus.z), 0.0)
	_game.camera.apply()
	for frame: int in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
