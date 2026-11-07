extends Node
## Roteiro de verificação visual da Fase 157 (caixas da colheita): na semente 1840, uma fazenda de trigo e uma de batata na
## ilha principal (achadas pelo SiteFinder) com os campos em volta, no fim do ciclo (caixotes e sacos entre as fileiras) e
## logo depois da colheita (sem nada). Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase157.tscn -- <pasta>

const SEED := 1840

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	GameScreen.load_slot_on_start = ""
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	var game := (load("res://ui/screens/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	add_child(game)
	GameClock.set_speed(TickClock.PAUSED)
	_set_hour(10.0)
	game.hud.visible = false
	var sim := game.simulation
	var grid := sim.world.island(Simulation.MAIN_ISLAND)
	sim.free_build = true
	var farms: Array[int] = []
	var fields: Array[int] = []
	var near := grid.size / 2
	for def_id: StringName in [&"wheat_farm", &"potato_farm"]:
		var found := SiteFinder.find(sim, def_id, Simulation.MAIN_ISLAND, near)
		if found.is_empty():
			continue
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		var def := sim.data.building(def_id)
		var area := Footprint.rect(origin, def.size, rotation)
		# as fazendas caem às vezes numa mata: derruba as árvores em volta antes dos campos
		var clearing := area.grow(def.module_radius_cells + 2)
		var felled: Array[Vector2i] = []
		for y: int in range(clearing.position.y, clearing.end.y):
			for x: int in range(clearing.position.x, clearing.end.x):
				if grid.in_bounds(Vector2i(x, y)):
					felled.append(Vector2i(x, y))
		if grid.clear_trees(felled):
			EventBus.trees_changed.emit(Simulation.MAIN_ISLAND, clearing)
		var result := sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
		if not result.ok():
			continue
		var farm_id: int = result.placed[0]
		farms.append(farm_id)
		var reach := area.grow(def.module_radius_cells)
		var placed := 0
		for y: int in range(reach.position.y, reach.end.y - 2):
			for x: int in range(reach.position.x, reach.end.x - 2):
				if placed >= def.modules_required:
					break
				var field := sim.execute(PlaceBuildingCommand.new(0, def.module_id, Vector2i(x, y), 0))
				if field.ok():
					placed += 1
					fields.append(field.placed[0])
		print(def_id, ": ", placed, " campos")
		near = origin + Vector2i(14, 0)
	await get_tree().process_frame
	for farm_id: int in farms:
		sim.world.building(farm_id).progress = 0.97
	game.crop_view.rebuild()
	var shown := 0
	for field_id: int in fields:
		shown += game.crop_view.harvest_count(field_id)
	print("caixas e sacos à vista: ", shown)
	for i: int in farms.size():
		var farm := sim.world.building(farms[i])
		var center := grid.rect_world(Footprint.rect(farm.origin, sim.def_of(farm).size, farm.rotation))
		await _shot(game, "colheita_%d.png" % i, center, 45.0, 0.6)
		await _shot(game, "colheita_%d_b.png" % i, center, 45.0, 3.75)
	if not fields.is_empty():
		var field := sim.world.building(fields[0])
		var middle := grid.rect_world(Footprint.rect(field.origin, Vector2i(3, 3), field.rotation))
		await _shot(game, "colheita_de_perto.png", middle, 11.0, 0.9)
		var last_id: int = fields.back()
		var last := sim.world.building(last_id)
		var potatoes := grid.rect_world(Footprint.rect(last.origin, Vector2i(3, 3), last.rotation))
		await _shot(game, "batatas_de_perto.png", potatoes, 11.0, 0.9)
		for farm_id: int in farms:
			sim.world.building(farm_id).progress = 0.0
		game.crop_view.refresh()
		await _shot(game, "depois_da_colheita.png", middle, 11.0, 0.9)
	get_tree().quit()


func _shot(game: GameScreen, file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = maxf(game.simulation.world.surface_height(focus.x, focus.z), 0.0)
	game.camera.apply()
	for frame: int in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
