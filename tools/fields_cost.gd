extends Node
## Custo e verificação visual dos campos (Fase 40), no arquipélago da semente 1840: um bairro rural de fazendas com os
## campos e pastos delas, medido (montar a CropView, objetos, draw calls, quadro e GPU a 110 m e a 420 m) e fotografado.
## Precisa de GPU; no PC do dono roda na área de trabalho escondida (F:\ferramentas\desktop_oculto.ps1):
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/fields_cost.tscn -- <pasta>
## Grava medida.md e as capturas na pasta.

const SEED := 1840
const FARMS: Array[StringName] = [&"wheat_farm", &"potato_farm", &"sheep_farm", &"hop_farm", &"wheat_farm",
		&"pig_farm", &"potato_farm", &"wheat_farm"]
const FRAMES := 240

var _out_dir: String
var _game: GameScreen
var _sim: Simulation
var _lines: PackedStringArray = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	_game = (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(_game)
	GameClock.set_speed(TickClock.PAUSED)
	_run.call_deferred()


func _run() -> void:
	_sim = _game.simulation
	_sim.free_build = true
	var grid := _sim.world.island(0)
	var block := _find_block(grid, Vector2i(64, 40))
	var fields := 0
	var farms := 0
	for row: int in 2:
		# uma rua só: as fazendas de cima viradas para ela, as de baixo também
		var street := block.y + 19
		_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(block.x, street), Vector2i(block.x + 63, street))))
		for k: int in FARMS.size() / 2:
			var def_id := FARMS[row * FARMS.size() / 2 + k]
			var def := _sim.data.building(def_id)
			var origin := Vector2i(block.x + 2 + k * 16, street + 1 if row == 1 else street - def.size.y)
			var placed := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, 0 if row == 1 else 2))
			if not placed.ok():
				continue
			farms += 1
			var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
			var made := 0
			for y: int in range(reach.position.y, reach.end.y - 2, 3):
				for x: int in range(reach.position.x, reach.end.x - 2, 3):
					if made >= def.modules_required:
						break
					if _sim.execute(PlaceBuildingCommand.new(0, def.module_id, Vector2i(x, y), 0)).ok():
						made += 1
			fields += made
	var started := Time.get_ticks_usec()
	_game.crop_view.rebuild()
	_report("bairro rural", "%d fazendas, %d campos e pastos" % [farms, fields])
	_report("montar a CropView (rebuild)", "%.1f ms" % ((Time.get_ticks_usec() - started) / 1000.0))
	# a segunda vez é a de cada obra durante o jogo (o que dá para guardar já está guardado)
	started = Time.get_ticks_usec()
	_game.crop_view.rebuild()
	_report("refazer a CropView depois de uma obra", "%.1f ms" % ((Time.get_ticks_usec() - started) / 1000.0))
	_set_hour(10.0)
	var center := grid.cell_world(block + Vector2i(32, 20))
	for distance: float in [110.0, 420.0]:
		await _measure(center, distance)
	await _shot("campos_110m.png", center, 110.0, 0.4)
	await _shot("campos_420m.png", center, 420.0, 0.0)
	await _shot("campos_45m.png", center, 45.0, 0.9)
	var file := FileAccess.open(_out_dir.path_join("medida.md"), FileAccess.WRITE)
	file.store_string("| Medida | Resultado |\n|---|---|\n" + "\n".join(_lines) + "\n")
	file.close()
	get_tree().quit()


func _measure(center: Vector3, distance: float) -> void:
	_place_camera(center, distance, 0.4)
	var viewport := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	for frame: int in 30:
		await get_tree().process_frame
	var gpu := 0.0
	var started := Time.get_ticks_usec()
	for frame: int in FRAMES:
		await get_tree().process_frame
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
	var frame_ms := (Time.get_ticks_usec() - started) / 1000.0 / FRAMES
	_report("a %.0f m: quadro / GPU" % distance, "%.2f / %.2f ms" % [frame_ms, gpu / FRAMES])
	_report("a %.0f m: objetos · draw calls · primitivas" % distance, "%d · %d · %d" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])


func _report(label: String, value: String) -> void:
	_lines.append("| %s | %s |" % [label, value])
	print(label, ": ", value)


func _find_block(grid: IslandGrid, size: Vector2i) -> Vector2i:
	var center := grid.size / 2
	var best := Vector2i(4, 4)
	var best_gap := INF
	for y: int in range(4, grid.size.y - size.y - 4, 4):
		for x: int in range(4, grid.size.x - size.x - 4, 4):
			var area := Rect2i(Vector2i(x, y), size)
			if not grid.area_is_land(area) or grid.area_relief(area) > 3.0:
				continue
			var gap := Vector2(Vector2i(x, y) + size / 2 - center).length()
			if gap < best_gap:
				best = Vector2i(x, y)
				best_gap = gap
	return best


func _place_camera(focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = _sim.world.surface_height(focus.x, focus.z)
	_game.camera.camera.far = maxf(4000.0, distance * 3.0)
	_game.camera.apply()


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	_place_camera(focus, distance, yaw)
	for frame: int in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
