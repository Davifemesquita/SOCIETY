extends Node
## Roteiro de verificação visual da Fase 5 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 9000 res://tools/capture_phase5.tscn -- <pasta>
## Arquipélago da semente 1840: visto de cima, a ilha principal, o litoral com a água, a floresta,
## o rio, a mina sobre a jazida (com o destaque de terreno), uma vila assentada no relevo com a
## água turva perto da fundição, e a noite.

const SEED := 1840

var _out_dir: String
var _game: GameScreen
var _sim: Simulation


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
	var grid := _sim.world.island(0)
	var rig := _game.camera.rig
	_set_hour(11.0)
	# de cima: o arquipélago inteiro (fora do limite de zoom do jogador, só para a captura)
	var bounds := _game.world_bounds()
	await _shot("01_arquipelago.png", Vector3(bounds.get_center().x, 0.0, bounds.get_center().y), 1500.0, 0.0)
	await _shot("02_ilha_principal.png", grid.cell_world(grid.size / 2), 420.0, 0.0)
	var post := SiteFinder.find(_sim, &"trading_post", 0, Vector2i(grid.size.x / 2, 0))
	var post_origin: Vector2i = post[0]
	var post_rotation: int = post[1]
	await _shot("03_litoral.png", grid.cell_world(post_origin), 70.0, 0.6)
	await _shot("04_floresta.png", grid.cell_world(_first_cell(grid, func(i: int) -> bool: return grid.trees[i] >= 3)), 45.0, 0.3)
	await _shot("05_rio.png", grid.cell_world(grid.cell_at(grid.ground.find(IslandGrid.Ground.RIVER))), 50.0, 0.0)
	var mine := SiteFinder.find(_sim, &"coal_mine", 0, grid.size / 2)
	var mine_origin: Vector2i = mine[0]
	_game.tool.island_id = 0
	_game.tool.start_building(_sim.data.building(&"coal_mine"))
	_game.tool.hover(mine_origin + Vector2i(2, 2))
	await _shot("06_mina_na_jazida.png", grid.cell_world(mine_origin), 55.0, 0.0)
	_game.tool.cancel()
	# a água em frente de onde vai a fundição, antes e depois dela
	var side := Vector2i(Footprint.front_direction(post_rotation).y, -Footprint.front_direction(post_rotation).x)
	var furnace := SiteFinder.find(_sim, &"furnace", 0, post_origin + side * 14)
	var furnace_origin: Vector2i = furnace[0]
	var furnace_rotation: int = furnace[1]
	var furnace_center := grid.rect_world(Footprint.rect(furnace_origin, _sim.data.building(&"furnace").size, furnace_rotation))
	# o mar fica atrás do entreposto (a frente dele dá para a terra)
	var seaward := -Footprint.front_direction(post_rotation)
	var water_spot := Vector3(furnace_center.x, 0.0, furnace_center.z) + Vector3(seaward.x, 0.0, seaward.y) * 25.0
	await _shot("08a_agua_antes_da_fundicao.png", water_spot, 70.0, PI)
	_build_village(post_origin, post_rotation)
	_sim.run_ticks(roundi(240.0 / _sim.config.tick_interval()))
	await _shot("07_vila_no_relevo.png", grid.cell_world(post_origin), 110.0, 0.6)
	await _shot("08b_agua_depois_da_fundicao.png", water_spot, 70.0, PI)
	_set_hour(22.0)
	await _shot("09_noite.png", grid.cell_world(post_origin), 110.0, 0.6)
	get_tree().quit()


## Entreposto no litoral, uma rua para dentro da ilha com casas e uma fundição perto da água.
func _build_village(post_origin: Vector2i, post_rotation: int) -> void:
	_sim.free_build = true
	var grid := _sim.world.island(0)
	var def := _sim.data.building(&"trading_post")
	_sim.execute(PlaceBuildingCommand.new(0, &"trading_post", post_origin, post_rotation))
	var front := Footprint.front_direction(post_rotation)
	var start := Footprint.entrance_cell(post_origin, def.size, post_rotation)
	var street: Array[Vector2i] = []
	for step: int in 40:
		var cell := start + front * step
		if PlacementRules.check_road_cell(grid, cell, _sim.config) != PlacementRules.OK:
			break
		street.append(cell)
	if not street.is_empty():
		_sim.execute(BuildRoadCommand.new(0, street))
	print("rua: %d células; entreposto com estrada: %s" % [street.size(), _sim.has_road_access(_sim.world.building_ids()[0])])
	var side := Vector2i(front.y, -front.x)
	for k: int in range(2, street.size() - 3, 3):
		for direction: int in [1, -1]:
			var house_origin := Footprint.origin_centered_on(street[k] + side * direction * 2, Vector2i(3, 3), 0)
			for rotation: int in 4:
				if _sim.placement_reason(_sim.data.building(&"house"), house_origin, rotation) == PlacementRules.OK:
					var placed := _sim.execute(PlaceBuildingCommand.new(0, &"house", house_origin, rotation))
					if placed.ok():
						_sim.world.building(placed.placed[0]).residents = 10.0
					break
	var furnace := SiteFinder.find(_sim, &"furnace", 0, post_origin + side * 14)
	if not furnace.is_empty():
		var furnace_origin: Vector2i = furnace[0]
		var furnace_rotation: int = furnace[1]
		_sim.execute(PlaceBuildingCommand.new(0, &"furnace", furnace_origin, furnace_rotation))
		var center := grid.rect_world(Footprint.rect(furnace_origin, _sim.data.building(&"furnace").size, furnace_rotation))
		print("fundição em %s; poluição da água ali: %.2f" % [furnace_origin, _game.water_view.pollution_at(center.x, center.z)])


func _first_cell(grid: IslandGrid, accepts: Callable) -> Vector2i:
	var center := grid.size / 2
	for radius: int in grid.size.x:
		for cell: Vector2i in [center + Vector2i(radius, 0), center + Vector2i(-radius, 0), center + Vector2i(0, radius), center + Vector2i(0, -radius)]:
			if grid.in_bounds(cell) and accepts.call(grid.index(cell)):
				return cell
	return center


func _shot(file_name: String, focus: Vector3, distance: float, yaw: float) -> void:
	var rig := _game.camera.rig
	rig.focus = Vector3(focus.x, 0.0, focus.z)
	rig.distance = distance
	rig.yaw = yaw
	rig.target_yaw = yaw
	rig.ground_height = _sim.world.surface_height(focus.x, focus.z)
	_game.camera.camera.far = maxf(4000.0, distance * 3.0)
	_game.camera.apply()
	for frame: int in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
