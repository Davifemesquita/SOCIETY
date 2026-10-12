extends Node
## Cena de benchmark (seção 15). Desde a Fase 2: 10 mil moradores (500 casas de operário
## cheias) e 500 prédios de produção ligados por estrada, com 20 mercados, rodando todos os
## sistemas. Mede o tick (orçamento de 4 ms), construir um prédio com a ilha cheia (sem
## travamento acima de 50 ms), salvar, carregar e o quadro. Carroças e pedestres entram nas
## fases deles.
##   tools/godot.sh godot --path . res://tools/benchmark.tscn -- [arquivo.md]
## No executável: Society.exe -- --benchmark (mostra o resultado na tela e grava em
## user://benchmark.md). Sem GPU (esta VM), o tempo de quadro não vale como meta.

const HOUSES := 500
const PRODUCTION := 500
const MARKETS := 20
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
	var houses := TownLayout.build(sim, HOUSES, &"house", Vector2i(2, 2))
	var lumberjacks := TownLayout.build(sim, PRODUCTION / 2, &"lumberjack", Vector2i(2, 40))
	var sawmills := TownLayout.build(sim, PRODUCTION / 2, &"sawmill", Vector2i(2, 70))
	var markets := TownLayout.build(sim, MARKETS, &"market", Vector2i(2, 110))
	var build_ms := (Time.get_ticks_usec() - started) / 1000.0
	for house_id: int in houses:
		var house := sim.world.building(house_id)
		house.tier = &"workers"
		house.residents = 20.0
	var people := 0
	for house_id: int in houses:
		people += floori(sim.world.building(house_id).residents)
	var buildings := lumberjacks.size() + sawmills.size() + markets.size()
	_report("carga", "%d moradores em %d casas; %d prédios de produção e serviço" % [people, houses.size(), buildings])
	_report("montar tudo (comandos + eventos + vistas)", "%.0f ms" % build_ms)
	sim.derived_state()
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


## Média de cada sistema em ms por tick, na ordem do tick.
func _per_system(sim: Simulation) -> String:
	var dt := sim.config.tick_interval()
	var derived := sim.derived_state()
	var steps: Dictionary[String, Callable] = {
		"força de trabalho": func() -> void: WorkforceSystem.run(sim.world, derived),
		"produção": func() -> void: ProductionSystem.run(sim.config, derived, dt),
		"estoque": func() -> void: DirectTransferSystem.run(sim.world, sim.config, derived),
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
