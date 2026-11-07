extends Node
## Roteiro de verificação visual da Fase 224 (relógio de sol no largo): na semente 1840, num descampado da ilha principal, a
## igreja, o teatro, a prefeitura e a escola de frente para uma rua, com o relógio de sol num canto do largo de cada um. Precisa
## de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase224.tscn -- <pasta>

const SEED := 1840
const HOUSES := 6

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
	var base := _open_ground(grid)
	print("rua em ", base)
	sim.free_build = true
	sim.ignore_terrain = true
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(base + Vector2i(-2, 4), base + Vector2i(HOUSES * 4 + 1, 4))))
	var x := 0
	for def_id: StringName in [&"church", &"theater", &"town_hall", &"school"]:
		var size := Footprint.rotated_size(sim.data.building(def_id).size, 2)
		sim.execute(PlaceBuildingCommand.new(0, def_id, base + Vector2i(x, 4 - size.y), 2))
		x += size.x + 2
	game.building_view.rebuild()
	for frame: int in 10:
		await get_tree().process_frame
	game.sundial_view.rebuild()
	print("relógios ", game.sundial_view.dial_count())
	var shot := 0
	var dials := SundialView.cells(sim.world, sim.data, Simulation.MAIN_ISLAND)
	for cell: Vector2i in dials:
		# do lado de fora do canto, olhando de volta para o relógio e o prédio
		var record := sim.world.building(dials[cell])
		var area := Footprint.rect(record.origin, sim.def_of(record).size, record.rotation)
		var dial := grid.cell_world(cell)
		dial.y = maxf(sim.world.surface_height(dial.x, dial.z), 0.0) + 0.9
		var away := dial - grid.rect_world(area)
		await _aimed(game, "relogio_de_sol_%d.png" % shot, dial, 6.0, atan2(away.x, away.z) + 0.3)
		shot += 1
		if shot >= 2:
			break
	var street := grid.cell_world(base + Vector2i(x / 2, 2))
	await _shot(game, "relogios_na_rua.png", street, 30.0, 0.4)
	get_tree().quit()


## Um descampado para a rua (terra sem árvore nem água, o mais perto do meio da ilha): HOUSES × 4 + 4 por 8 células.
func _open_ground(grid: IslandGrid) -> Vector2i:
	var size := Vector2i(HOUSES * 4 + 4, 8)
	var best := grid.size / 2
	var best_distance := INF
	for y: int in range(2, grid.size.y - size.y - 2, 2):
		for x: int in range(2, grid.size.x - size.x - 2, 2):
			var open := true
			for dy: int in size.y:
				for dx: int in size.x:
					var index := grid.index(Vector2i(x + dx, y + dy))
					if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0:
						open = false
						break
				if not open:
					break
			var distance := Vector2(x, y).distance_to(Vector2(grid.size / 2))
			if open and distance < best_distance:
				best_distance = distance
				best = Vector2i(x + 2, y + 1)
	return best


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


## O relógio fica entre os prédios: a câmera posta à mão, do lado de fora, olhando para baixo (a da partida fica presa ao chão).
func _aimed(game: GameScreen, file_name: String, at: Vector3, distance: float, yaw: float) -> void:
	game.camera.set_process(false)
	var eye := at + Vector3(sin(yaw), 0.75, cos(yaw)).normalized() * distance
	game.camera.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	for frame: int in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
	game.camera.set_process(true)
