extends Node
## Cidade de teste: o jogador-robô (AutoPlayer) joga PLAY_MINUTES de jogo de verdade (custo, material, carroças,
## armazéns, desbloqueios), e a cidade evoluída vai para o slot SLOT, que o jogo abre pelo "Carregar". Por cima do que o
## robô ergue, o que ele não constrói: praças com chafariz, coreto, estátua, canteiros, zoológico e museu com todas as
## peças e a prefeitura (de graça, perto das casas e de frente para a rua), os eventos ligados com uma festa em andamento
## e o relógio no fim da tarde (os fogos começam com a noite). Sem tela:
##   godot --headless --path . res://tools/build_test_city.tscn [-- <minutos>]
## O andamento vai para user://cidade_de_teste.txt.

const SLOT := "cidade_de_teste"
const PLAY_MINUTES := 240.0
const STEP_S := 900.0
## Hora em que a partida carregada começa (a festa fica de pé por FESTIVAL_DAYS dias de jogo).
const START_HOUR := 18.0
const FESTIVAL_DAYS := 2.0
## Saldo mínimo ao gravar (para testar sem esperar o caixa).
const MIN_MONEY := 60000.0
## O que vai em volta das casas, em ordem.
const EXTRAS: Array[StringName] = [&"town_hall", &"zoo", &"museum", &"fountain_square", &"bandstand", &"statue",
		&"fountain_square", &"flower_bed", &"flower_bed", &"park_bench", &"park_bench", &"planted_tree", &"planted_tree"]
## Até onde procurar lugar em volta do meio das casas (células).
const SEARCH_RADIUS := 90

var _log: FileAccess


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_log = FileAccess.open("user://cidade_de_teste.txt", FileAccess.WRITE)
	var args := OS.get_cmdline_user_args()
	var minutes := float(args[0]) if not args.is_empty() and args[0].is_valid_float() else PLAY_MINUTES
	var player := AutoPlayer.create()
	var sim := player.simulation
	var started := Time.get_ticks_msec()
	var played := 0.0
	while played < minutes * 60.0:
		player.play(STEP_S)
		played += STEP_S
		_say("%.0f min de jogo (%.0f s reais): %s" % [played / 60.0, (Time.get_ticks_msec() - started) / 1000.0,
				_population(sim)])
	_say(player.summary())
	var world := sim.world
	var center := _houses_center(sim)
	sim.free_build = true
	for def_id: StringName in EXTRAS:
		var placed := _place_near_road(sim, def_id, center)
		_say("%s: %s" % [def_id, "posto (id %d)" % placed if placed > 0 else "sem lugar"])
		if placed > 0 and sim.def_of(world.building(placed)).exhibit_slots > 0:
			_fill_exhibits(sim, placed)
	sim.free_build = false
	world.money = maxf(world.money, MIN_MONEY)
	# os eventos ligados, com uma festa na ilha (os fogos começam com a noite)
	world.events_state.enabled = true
	var festival := WorldEvent.new()
	festival.def = sim.data.event(&"festival")
	festival.def_id = &"festival"
	festival.island_id = AutoPlayer.ISLAND
	festival.ends_tick = world.tick + sim.config.ticks_of(FESTIVAL_DAYS * sim.config.day_length_game_seconds())
	world.events_state.events.append(festival)
	# o relógio no tick da partida e a hora no fim da tarde
	var clock := GameClock.clock
	clock.tick_count = world.tick
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(START_HOUR - clock.hour(), 24.0)
	var grid := world.island(AutoPlayer.ISLAND)
	var focus := grid.cell_world(center)
	var state := {"world": world.to_dict(), "clock": clock.to_dict(),
			"camera": {"focus": Vector3(focus.x, 0.0, focus.z), "yaw": 0.6, "distance": 90.0}}
	var population := 0
	for tier: TierDef in sim.data.tiers:
		population += world.population(tier.id)
	var info := {"name": "Cidade de teste", "day": clock.day_number(), "population": population, "money": world.money,
			"seed": world.seed}
	var error := SaveSystem.save_game(SLOT, state, null, info)
	_say("gravado em %s: %s (%d moradores, %.0f moedas, %d prédios), %.0f s reais" % [SaveSystem.slot_path(SLOT),
			error_string(error), population, world.money, world.buildings.size(), (Time.get_ticks_msec() - started) / 1000.0])
	get_tree().quit(0 if error == OK else 1)


func _say(line: String) -> void:
	print(line)
	if _log != null:
		_log.store_line(line)
		_log.flush()


func _population(sim: Simulation) -> String:
	var parts: PackedStringArray = []
	for tier: TierDef in sim.data.tiers:
		parts.append("%s %d" % [tier.id, sim.world.population(tier.id)])
	return ", ".join(parts) + ", %.0f moedas" % sim.world.money


## O meio das casas da ilha principal (em células).
func _houses_center(sim: Simulation) -> Vector2i:
	var sum := Vector2.ZERO
	var count := 0
	for record: BuildingRecord in sim.world.buildings.values():
		if record.island_id == AutoPlayer.ISLAND and record.is_house():
			sum += Vector2(record.origin)
			count += 1
	return Vector2i((sum / maxf(count, 1)).round())


## Põe o prédio no lugar livre mais perto do centro com a entrada numa estrada; devolve o id (0 sem lugar).
func _place_near_road(sim: Simulation, def_id: StringName, center: Vector2i) -> int:
	var def := sim.data.building(def_id)
	if def == null:
		return 0
	var grid := sim.world.island(AutoPlayer.ISLAND)
	for radius: int in SEARCH_RADIUS:
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var origin := center + Vector2i(dx, dy)
				for rotation: int in 4:
					var entrance := Footprint.entrance_cell(origin, def.size, rotation)
					if def.kind != BuildingDef.Kind.DECORATION and not grid.has_road(entrance):
						continue
					var result := sim.execute(PlaceBuildingCommand.new(AutoPlayer.ISLAND, def_id, origin, rotation))
					if result.ok():
						return result.placed[0]
	return 0


## Todas as peças do tipo do prédio (bichos no zoológico, objetos no museu), até as vagas dele.
func _fill_exhibits(sim: Simulation, building_id: int) -> void:
	for def: ExhibitDef in sim.data.exhibits:
		var result := sim.execute(PlaceExhibitCommand.new(def.id, building_id))
		if result.ok():
			_say("  peça %s" % def.id)
