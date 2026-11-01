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
		&"weavery", &"distillery", &"bakery", &"museum", &"mill"]

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
	# Fase 171: uma rua de casas de camponeses e operários com uma célula livre entre elas (a lenha na parede do lado)
	var spaced_y := big_y + 12
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(ORIGIN.x, spaced_y), Vector2i(ORIGIN.x + 40, spaced_y))))
	for i: int in 8:
		var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(ORIGIN.x + 1 + i * 5, spaced_y - 3), 2))
		if result.ok():
			_sim.world.building(result.placed[0]).tier = &"peasants" if i % 2 == 0 else &"workers"
			_sim.world.building(result.placed[0]).residents = 5.0
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
	# Fase 114: o gradil das casas dos engenheiros, de perto
	await _shot("gradil_de_perto.png", grid.cell_world(streets[3] + Vector2i(0, -1)), 12.0, 0.3)
	# Fase 153: as floreiras das sacadas dos engenheiros e investidores, de perto
	await _shot("sacadas_floridas.png", grid.cell_world(streets[3] + Vector2i(0, -1)), 14.0, 0.25)
	await _shot("sacadas_floridas_b.png", grid.cell_world(streets[4] + Vector2i(0, -1)), 16.0, 0.25)
	# Fase 154: o velocípede encostado numa casa dos artesãos, de perto
	for id: int in _sim.world.building_ids():
		var bike: Variant = VelocipedeView.spot(_sim, _sim.world.building(id))
		if bike is Transform3D:
			var bike_at: Transform3D = bike
			await _shot("velocipede.png", bike_at.origin, 7.0, 0.35)
			break
	# Fase 143: a cerca de estacas dos operários, de perto
	await _shot("cerca_de_estacas.png", grid.cell_world(streets[1] + Vector2i(0, -1)), 12.0, 0.3)
	# Fase 163: as hortas atrás das casas dos camponeses e dos operários, vistas dos fundos
	await _shot("hortas_camponeses.png", grid.cell_world(Vector2i(ORIGIN.x + 9, ORIGIN.y - 1)), 15.0, PI + 0.4)
	await _shot("hortas_operarios.png", grid.cell_world(Vector2i(ORIGIN.x + 9, ORIGIN.y + STREET_STEP - 1)), 13.0, PI - 0.4)
	# Fase 171: a lenha na parede do lado, na rua de casas espaçadas
	var spaced := grid.cell_world(Vector2i(ORIGIN.x + 20, ORIGIN.y + TIERS.size() * STREET_STEP + 3 + 12))
	await _shot("lenha_na_parede.png", spaced, 18.0, -0.6)
	for pile: Transform3D in _game.log_pile_view.places:
		if pile.origin.distance_to(spaced) < 24.0:
			await _shot("lenha_de_perto.png", pile.origin, 6.0, -0.9)
			break
	# Fase 173: a tina de lavar ao lado do varal, de perto
	for line: int in _game.yard_view.tub_count():
		var tub := _game.yard_view.tub_transform(line)
		if tub.origin != Vector3.ZERO:
			await _shot("tina_de_lavar.png", tub.origin, 6.0, PI + 0.6)
			break
	# Fase 174: o banco na porta das casas dos camponeses, de perto
	if not _game.door_bench_view.places.is_empty():
		await _shot("banco_na_porta.png", _game.door_bench_view.places[0].origin, 7.0, 0.4)
	# Fase 197: a casinha do cão ao lado das casas com cão, de perto
	if not _game.kennel_view.places.is_empty():
		await _shot("casinha_do_cao.png", _game.kennel_view.places[0].origin, 7.0, 0.5)
		await _shot("casinha_do_cao_rua.png", _game.kennel_view.places[0].origin, 16.0, -0.4)
	# Fase 200: o gato sentado ao lado da porta, de perto e da rua
	if not _game.cat_view.places.is_empty():
		var cat := _game.cat_view.places[0]
		await _shot("gato_na_porta.png", cat.origin, 5.0, atan2(-cat.basis.z.x, -cat.basis.z.z) + 0.4)
		await _shot("gato_da_rua.png", cat.origin, 14.0, atan2(-cat.basis.z.x, -cat.basis.z.z) - 0.3)
	# Fase 205: os estandartes na fachada dos serviços, de perto e da rua
	if not _game.banner_view.places.is_empty():
		var banner := _game.banner_view.places[0]
		var out := -banner.basis.z.normalized()
		await _shot("estandartes.png", banner.origin - Vector3(0.0, 2.0, 0.0), 12.0, atan2(out.x, out.z) + 0.3)
		await _shot("estandartes_da_rua.png", banner.origin, 26.0, atan2(out.x, out.z) - 0.4)
	# Fase 208: as ramas de tecido atrás da tecelagem, de perto e de longe
	if not _game.tenter_view.places.is_empty():
		var tenter := _game.tenter_view.places[0]
		var out := tenter.basis.z.normalized()
		await _shot("ramas_de_tecido.png", tenter.origin, 9.0, atan2(out.x, out.z) + 0.5)
		await _shot("ramas_de_longe.png", tenter.origin, 22.0, atan2(out.x, out.z) - 0.4)
	# Fase 210: os pombos na cumeeira, de perto e da rua
	if not _game.roof_pigeon_view.places.is_empty():
		var pigeon := _game.roof_pigeon_view.places[0]
		await _aimed("pombos_na_cumeeira.png", pigeon.origin, 5.0, 0.6)
		await _aimed("pombos_da_rua.png", pigeon.origin, 14.0, -0.3)
	# Fase 211: as mós e os sacos no lado do moinho, de perto
	if not _game.millstone_view.places.is_empty():
		var mill := _game.millstone_view.places[0]
		var out := mill.basis.z.normalized()
		await _shot("mos_no_moinho.png", mill.origin, 7.0, atan2(out.x, out.z) + 0.5)
		await _shot("mos_de_longe.png", mill.origin, 18.0, atan2(out.x, out.z) - 0.4)
	# Fase 169: os barris de chuva na quina de trás das casas, de perto
	await _shot("barris_de_chuva.png", grid.cell_world(Vector2i(ORIGIN.x + 4, ORIGIN.y + STREET_STEP - 1)), 8.0, PI + 0.7)
	# Fase 160: os cunhais nas quinas das casas dos artesãos, de quina
	await _shot("cunhais.png", grid.cell_world(streets[2] + Vector2i(1, -1)), 13.0, 0.75)
	# Fase 102: o andar saliente com enxaimel, de perto
	await _shot("enxaimel_de_perto.png", grid.cell_world(streets[1] + Vector2i(0, -1)), 16.0, 0.35)
	# Fase 103: as claraboias das fábricas, de dia e à noite
	await _shot("claraboias.png", grid.cell_world(Vector2i(ORIGIN.x + 50, big_y - 2)), 34.0, 0.9)
	_set_hour(21.0)
	await _shot("claraboias_noite.png", grid.cell_world(Vector2i(ORIGIN.x + 50, big_y - 2)), 34.0, 0.9)
	_set_hour(10.0)
	# Fase 104: a chaminé de tijolo, o lampião e a grade do museu
	await _shot("chamine_de_perto.png", grid.cell_world(streets[2] + Vector2i(0, -2)), 12.0, 0.6)
	await _shot("museu_grade.png", grid.cell_world(Vector2i(ORIGIN.x + 60, big_y - 2)), 24.0, 0.3)
	# Fase 101: o toldo da padaria
	await _shot("loja_toldo.png", grid.cell_world(Vector2i(ORIGIN.x + 55, big_y - 2)), 20.0, 0.3)
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


## Fase 210: a câmera da partida fica presa ao chão; para o alto do telhado, põe a Camera3D à mão, um pouco acima do ponto.
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
