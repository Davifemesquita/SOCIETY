extends Node
## Cena de benchmark (seção 15). Desde a Fase 3: 10 mil moradores (200 casas de camponeses e
## 400 de operários, cheias), 200 prédios de produção com 200 carroças rodando entre eles, o entreposto e os
## armazéns, e 20 mercados, com todos os sistemas. Mede o tick (orçamento de 4 ms), construir
## um prédio com a ilha cheia (sem travamento acima de 50 ms), salvar, carregar e o quadro.
## Fase 4: 2.000 pedestres na rua e um dia inteiro em 60 s (céu, janelas, luzes de área), com a
## partida rodando a 1x, em três distâncias de câmera: FPS médio, 1% pior e pior quadro.
## Fase 5: tudo isso no arquipélago da semente 1840 (relevo, água, ~50 mil árvores); a cidade de
## teste é montada sem olhar o terreno (chave só do benchmark), derrubando as árvores debaixo.
##   tools/godot.sh godot --path . res://tools/benchmark.tscn -- [arquivo.md]
## No executável: Society.exe -- --benchmark (mostra o resultado na tela e grava em
## user://benchmark.md). Sem GPU (esta VM), o tempo de quadro não vale como meta.

const HOUSES := 600
## 200 casas de camponeses (2.000) trabalham em lenhadores e serrarias; 400 de operários (8.000).
const PEASANT_HOUSES := 200
const PRODUCTION := 200
const MARKETS := 20
## Trecho de rua servido por um armazém: ele na ponta e os prédios até 36 células adiante.
const SEGMENT := 36
const WARM_UP_TICKS := 600
const TICKS := 300
const FRAMES := 120
## O dia inteiro passa em DAY_SECONDS segundos reais, um terço em cada distância da câmera.
const DAY_SECONDS := 60.0
const DAY_DISTANCES: Array[float] = [40.0, 120.0, 300.0]
const SLOT := "benchmark"
const RESULT_PATH := "user://benchmark.md"
const SEED := 1840

var _lines: PackedStringArray = []
## Aberto pelo executável (-- --benchmark): mostra o resultado em vez de fechar.
var _from_game: bool = false


func _ready() -> void:
	_from_game = "--benchmark" in OS.get_cmdline_user_args()
	_run.call_deferred()


func _show_results() -> void:
	for child: Node in get_children():
		child.queue_free()
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	panel.position = Vector2(40, 40)
	layer.add_child(panel)
	var text := Label.new()
	text.text = "Benchmark — %s\n\n%s\n\nGravado em %s\nEsc fecha." % [OS.get_processor_name(),
			"\n".join(_lines), ProjectSettings.globalize_path(RESULT_PATH)]
	panel.add_child(text)


func _unhandled_input(event: InputEvent) -> void:
	if _from_game and event.is_action_pressed(&"ui_cancel"):
		get_tree().quit()


func _run() -> void:
	var config := GameConfig.get_default()
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	var started := Time.get_ticks_usec()
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	_report("jogo novo: arquipélago, terreno, água e árvores", "%.0f ms (semente %d, %d árvores desenhadas)" % [
			(Time.get_ticks_usec() - started) / 1000.0, SEED, game.tree_view.instance_count()])
	GameClock.set_speed(TickClock.PAUSED)
	var sim := game.simulation
	started = Time.get_ticks_usec()
	sim.free_build = true
	sim.ignore_terrain = true
	sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"trading_post", Vector2i(10, 0), 2))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(Vector2i(2, 6), Vector2i(247, 6))))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(Vector2i(2, 6), Vector2i(2, 9))))
	var houses := TownLayout.build(sim, HOUSES, &"house", Vector2i(2, 9))
	var production := _production_streets(sim, 60)
	var markets := TownLayout.build(sim, MARKETS, &"market", Vector2i(2, 110))
	sim.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, RoadPath.l_path(Vector2i(2, 37), Vector2i(2, 110))))
	var build_ms := (Time.get_ticks_usec() - started) / 1000.0
	for index: int in houses.size():
		var house := sim.world.building(houses[index])
		house.tier = &"peasants" if index < PEASANT_HOUSES else &"workers"
		house.residents = 10.0 if index < PEASANT_HOUSES else 20.0
	var people := 0
	for house_id: int in houses:
		people += floori(sim.world.building(house_id).residents)
	sim.world.economy(Simulation.MAIN_ISLAND).stock[&"wood"] = 40.0
	var warehouses: Array = sim.derived_state().warehouses.get(0, [])
	_report("carga", "%d moradores em %d casas; %d prédios de produção (%d carroças), %d armazéns, %d mercados" % [people,
			houses.size(), production.size(), sim.world.carts.size(), warehouses.size(), markets.size()])
	_report("montar tudo (comandos + eventos + vistas)", "%.0f ms" % build_ms)
	sim.derived_state()
	sim.run_ticks(WARM_UP_TICKS)
	var away := sim.world.carts.values().filter(func(cart: Cart) -> bool: return cart.is_away()).size()
	_report("carroças na rua depois de 2 min", "%d de %d" % [away, sim.world.carts.size()])
	var times := PackedFloat64Array()
	started = Time.get_ticks_usec()
	for tick: int in TICKS:
		var one := Time.get_ticks_usec()
		sim.tick(tick)
		times.append((Time.get_ticks_usec() - one) / 1000.0)
	var tick_ms := (Time.get_ticks_usec() - started) / 1000.0 / TICKS
	times.sort()
	_report("tick de simulação (média / 95% / pior)", "%.2f / %.2f / %.2f ms (orçamento %.1f ms)" % [tick_ms,
			times[int(times.size() * 0.95)], times[times.size() - 1], config.tick_budget_ms])
	_report("tick por sistema", _per_system(sim))
	started = Time.get_ticks_usec()
	sim.free_build = true
	sim.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, &"market", Vector2i(200, 200), 0))
	var executed := Time.get_ticks_usec()
	sim.derived_state()
	_report("construir um prédio com a ilha cheia", "%.1f ms (limite 50 ms): comando e vistas %.1f · recálculo %.1f" % [
			(Time.get_ticks_usec() - started) / 1000.0, (executed - started) / 1000.0, (Time.get_ticks_usec() - executed) / 1000.0])
	var steps: PackedStringArray = []
	for step: String in sim.derived_state().last_rebuild_ms:
		steps.append("%s %.1f" % [step, sim.derived_state().last_rebuild_ms[step]])
	_report("recálculo por etapa (ms)", " · ".join(steps))
	started = Time.get_ticks_usec()
	SaveSystem.save_game(SLOT, game.game_state())
	_report("salvar", "%.0f ms (%.0f KB)" % [(Time.get_ticks_usec() - started) / 1000.0, FileAccess.get_file_as_bytes(SaveSystem.slot_path(SLOT)).size() / 1024.0])
	started = Time.get_ticks_usec()
	game.load_game(SLOT)
	_report("carregar (inclui refazer as vistas)", "%.0f ms" % [(Time.get_ticks_usec() - started) / 1000.0])
	DirAccess.remove_absolute(SaveSystem.slot_path(SLOT))
	DirAccess.remove_absolute(SaveSystem.thumbnail_path(SLOT))
	game.camera.rig.distance = config.camera_max_distance_m * 0.6
	for frame: int in 20:
		await get_tree().process_frame
	started = Time.get_ticks_usec()
	for frame: int in FRAMES:
		await get_tree().process_frame
	var frame_ms := (Time.get_ticks_usec() - started) / 1000.0 / FRAMES
	_report("quadro com tudo visível", "%.0f ms (%.0f FPS) — %s" % [frame_ms, 1000.0 / frame_ms, RenderingServer.get_video_adapter_name()])
	await _day_cycle(game, config)
	_write()
	if _from_game:
		_show_results()
	else:
		get_tree().quit()


## Fase 4: todos os pedestres na rua (o teto de 2.000), o custo da multidão na CPU e um dia inteiro
## renderizado com a partida rodando a 1x.
func _day_cycle(game: GameScreen, config: GameConfig) -> void:
	var view := game.pedestrian_view
	var crowd := view.crowd
	# a população do benchmark cai sem comida durante os minutos de simulação: volta aos 10 mil
	for house_id: int in game.simulation.derived_state().houses:
		var house := game.simulation.world.building(house_id)
		house.residents = 10.0 if house.tier == &"peasants" else 20.0
	crowd.activity_override = 1.0
	config.pedestrian_door_seconds = Vector2.ZERO
	var started := Time.get_ticks_usec()
	var warm_frames := 0
	crowd.update(1.0 / 60.0, 12.0)
	while crowd.visible_count() < crowd.agent_count() * 0.95 and warm_frames < 5000:
		crowd.update(1.0 / 60.0, 12.0)
		view.apply()
		warm_frames += 1
	_report("pedestres", "%d na multidão, %d na rua (teto %d); %d janelas" % [crowd.agent_count(),
			crowd.visible_count(), config.max_visible_pedestrians, game.window_view.window_count()])
	_report("multidão saindo de casa (rotas novas)", "%d quadros, %.0f ms; %d rotas, %.2f ms cada" % [warm_frames,
			(Time.get_ticks_usec() - started) / 1000.0, crowd.routes_computed, crowd.routes_usec / 1000.0 / maxi(1, crowd.routes_computed)])
	started = Time.get_ticks_usec()
	for i: int in 300:
		crowd.update(1.0 / 60.0, 12.0)
		view.apply()
	_report("multidão na CPU depois de sair (rotina + instâncias)", "%.2f ms por quadro" % [(Time.get_ticks_usec() - started) / 1000.0 / 300])
	GameClock.set_speed(0)
	var frames := PackedFloat64Array()
	var start := Time.get_ticks_usec()
	var last := start
	var start_hour := GameClock.clock.hour()
	var progress := 0.0
	while progress < 1.0:
		game.camera.rig.distance = DAY_DISTANCES[mini(floori(progress * DAY_DISTANCES.size()), DAY_DISTANCES.size() - 1)]
		game.camera.apply()
		GameClock.clock.extra_hours = 24.0 * progress
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		progress = (now - start) / 1000000.0 / DAY_SECONDS
	GameClock.set_speed(TickClock.PAUSED)
	GameClock.clock.extra_hours = 0.0
	var total := 0.0
	for ms: float in frames:
		total += ms
	frames.sort()
	var average := total / frames.size()
	var worst_percent := frames[int(frames.size() * 0.99)]
	_report("dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro)",
			"%.1f / %.1f FPS / %.0f ms em %d quadros (meta 60 FPS), a partir das %s" % [1000.0 / average,
			1000.0 / worst_percent, frames[frames.size() - 1], frames.size(), DayClock.clock_text(start_hour)])


## Duas ruas de produção a partir de y: em cada trecho de 36 células, um armazém na ponta e
## lenhadores e serrarias dos dois lados da rua, todos no alcance dele. A avenida em x = 2
## liga tudo ao entreposto.
func _production_streets(sim: Simulation, y: int) -> Array[int]:
	var ids: Array[int] = []
	var island := Simulation.MAIN_ISLAND
	var street := y
	while ids.size() < PRODUCTION:
		sim.execute(BuildRoadCommand.new(island, RoadPath.l_path(Vector2i(2, street), Vector2i(247, street))))
		sim.execute(BuildRoadCommand.new(island, RoadPath.l_path(Vector2i(2, street - 9), Vector2i(2, street))))
		var x := 3
		while x + SEGMENT <= 247 and ids.size() < PRODUCTION:
			sim.execute(PlaceBuildingCommand.new(island, &"warehouse", Vector2i(x, street + 1), 0))
			for slot: int in range(x + 4, x + SEGMENT - 3, 4):
				for side: int in 2:
					if ids.size() >= PRODUCTION:
						break
					var def_id := &"lumberjack" if ids.size() % 2 == 0 else &"sawmill"
					var origin := Vector2i(slot, street + 1) if side == 0 else Vector2i(slot, street - 4)
					var result := sim.execute(PlaceBuildingCommand.new(island, def_id, origin, 0 if side == 0 else 2))
					if result.ok():
						ids.append(result.placed[0])
			x += SEGMENT
		street += 10
	return ids


## Média de cada sistema em ms por tick, na ordem do tick.
func _per_system(sim: Simulation) -> String:
	var dt := sim.config.tick_interval()
	var derived := sim.derived_state()
	var steps: Dictionary[String, Callable] = {
		"força de trabalho": func() -> void: WorkforceSystem.run(sim.world, derived),
		"produção": func() -> void: ProductionSystem.run(sim.config, derived, dt),
		"logística": func() -> void: LogisticsSystem.run(sim.world, sim.config, derived, dt),
		"necessidades": func() -> void: NeedsSystem.run(sim.world, sim.data, sim.config, derived, dt),
		"população": func() -> void: PopulationSystem.run(sim.world, sim.data, sim.config, derived, dt),
		"economia": func() -> void: EconomySystem.run(sim.world, derived, dt),
	}
	var parts: PackedStringArray = []
	for name: String in steps:
		var started := Time.get_ticks_usec()
		for i: int in 50:
			steps[name].call()
		parts.append("%s %.2f" % [name, (Time.get_ticks_usec() - started) / 1000.0 / 50])
	return " · ".join(parts)


func _report(what: String, value: String) -> void:
	print("%s: %s" % [what, value])
	_lines.append("| %s | %s |" % [what, value])


func _max(values: PackedInt32Array) -> int:
	var highest := 0
	for value: int in values:
		highest = maxi(highest, value)
	return highest


func _write() -> void:
	var args := OS.get_cmdline_user_args()
	var path := RESULT_PATH if _from_game or args.is_empty() else args[0]
	var text := "\n### %s — %s\n\n| Medida | Resultado |\n|---|---|\n%s\n" % [Time.get_datetime_string_from_system(false, true),
			OS.get_processor_name(), "\n".join(_lines)]
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	file.seek_end()
	file.store_string(text)
	file.close()
