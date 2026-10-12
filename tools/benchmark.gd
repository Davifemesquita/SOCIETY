extends Node
## Cena de benchmark (seção 15). Na Fase 1 mede o que já existe: 500 prédios ligados por
## estrada, o custo dos comandos, do tick, de salvar e carregar, da rede de estradas e do
## quadro com tudo desenhado. Moradores, carroças e pedestres entram nas fases deles.
##   tools/godot.sh godot --path . res://tools/benchmark.tscn -- [arquivo.md]
## Sem GPU (esta VM), o tempo de quadro é de renderização por software e não vale como meta.

const BUILDINGS := 500
const TICKS := 1000
const FRAMES := 300
const SLOT := "benchmark"

var _lines: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var config := GameConfig.get_default()
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	var sim := game.simulation
	var started := Time.get_ticks_usec()
	var ids := TownLayout.build(sim, BUILDINGS, &"placeholder_house")
	var build_ms := (Time.get_ticks_usec() - started) / 1000.0
	var roads := sim.world.island(Simulation.MAIN_ISLAND).road_cells().size()
	_report("prédios", "%d (estrada: %d células)" % [ids.size(), roads])
	_report("construir tudo (comandos + eventos + vistas)", "%.1f ms (%.3f ms por prédio)" % [build_ms, build_ms / ids.size()])
	started = Time.get_ticks_usec()
	for tick: int in TICKS:
		sim.tick(tick)
	_report("tick de simulação", "%.4f ms (orçamento %.1f ms; ainda sem sistemas)" % [(Time.get_ticks_usec() - started) / 1000.0 / TICKS, config.tick_budget_ms])
	started = Time.get_ticks_usec()
	var labels := RoadNetwork.components(sim.world.island(Simulation.MAIN_ISLAND))
	_report("componentes da rede de estradas", "%.2f ms (%d trecho)" % [(Time.get_ticks_usec() - started) / 1000.0, _max(labels)])
	started = Time.get_ticks_usec()
	SaveSystem.save_game(SLOT, game.game_state())
	_report("salvar", "%.1f ms (%.1f KB)" % [(Time.get_ticks_usec() - started) / 1000.0, FileAccess.get_file_as_bytes(SaveSystem.slot_path(SLOT)).size() / 1024.0])
	started = Time.get_ticks_usec()
	game.load_game(SLOT)
	_report("carregar (inclui refazer as vistas)", "%.1f ms" % [(Time.get_ticks_usec() - started) / 1000.0])
	DirAccess.remove_absolute(SaveSystem.slot_path(SLOT))
	game.camera.rig.distance = config.camera_max_distance_m * 0.6
	for frame: int in 30:
		await get_tree().process_frame
	started = Time.get_ticks_usec()
	for frame: int in FRAMES:
		await get_tree().process_frame
	var frame_ms := (Time.get_ticks_usec() - started) / 1000.0 / FRAMES
	_report("quadro com tudo visível", "%.1f ms (%.0f FPS) — %s" % [frame_ms, 1000.0 / frame_ms, RenderingServer.get_video_adapter_name()])
	_write()
	get_tree().quit()


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
	if args.is_empty():
		return
	var text := "\n### %s\n\n| Medida | Resultado |\n|---|---|\n%s\n" % [Time.get_datetime_string_from_system(false, true), "\n".join(_lines)]
	var file := FileAccess.open(args[0], FileAccess.READ_WRITE if FileAccess.file_exists(args[0]) else FileAccess.WRITE)
	file.seek_end()
	file.store_string(text)
	file.close()
