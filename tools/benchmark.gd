extends Node
## Cena de benchmark (seção 15). Desde a Fase 3: 10 mil moradores (200 casas de camponeses e
## 400 de operários, cheias), 200 prédios de produção com 200 carroças rodando entre eles, o entreposto e os
## armazéns, e 20 mercados, com todos os sistemas. Mede o tick (orçamento de 4 ms), construir
## um prédio com a ilha cheia (sem travamento acima de 50 ms), salvar, carregar e o quadro.
## Pedestres entram na Fase 4.
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
const SLOT := "benchmark"
const RESULT_PATH := "user://benchmark.md"

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
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	var sim := game.simulation
	var started := Time.get_ticks_usec()
	sim.free_build = true
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
	sim.derived_state()
	_report("construir um prédio com a ilha cheia", "%.1f ms (limite 50 ms)" % [(Time.get_ticks_usec() - started) / 1000.0])
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
	_write()
	if _from_game:
		_show_results()
	else:
		get_tree().quit()


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
