extends Node
## Roteiro de verificação visual da Fase 46 (calçamento e esquinas), no arquipélago da semente 1840: ruas de
## paralelepípedo num bloco plano sem mata — um L, um cruzamento, um T, uma diagonal e uma rua de terra encostando no
## calçamento (na tomada l_40m_a) —,
## de perto (40 m) e a meia distância (70 m), às 10h. Só usa a simulação e o EventBus: roda igual numa cópia anterior
## à fase (o antes e depois). Precisa de GPU; no PC do dono roda na área de trabalho escondida
## (F:\ferramentas\desktop_oculto.ps1):
##   godot --path . --resolution 1920x1080 --quit-after 30000 res://tools/capture_phase46.tscn -- <pasta>

const SEED := 1840
const BLOCK := Vector2i(30, 24)

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
	var block := _find_block(grid, BLOCK)
	# o bloco sem mata (as copas tapavam as ruas de perto)
	var clearing: Array[Vector2i] = []
	for y: int in BLOCK.y:
		for x: int in BLOCK.x:
			clearing.append(block + Vector2i(x, y))
	if grid.clear_trees(clearing):
		EventBus.trees_changed.emit(0, Rect2i(block, BLOCK))
	var paved: Array[Vector2i] = []
	# o L: 10 para leste e 8 para o sul
	paved.append_array(RoadPath.l_path(block + Vector2i(2, 2), block + Vector2i(12, 2)))
	paved.append_array(RoadPath.l_path(block + Vector2i(12, 2), block + Vector2i(12, 10)))
	# o cruzamento: uma rua de leste a oeste corta a do sul
	paved.append_array(RoadPath.l_path(block + Vector2i(6, 7), block + Vector2i(18, 7)))
	# o T: a rua sobe do cruzamento para o norte, parando na rua de cima
	paved.append_array(RoadPath.l_path(block + Vector2i(18, 2), block + Vector2i(18, 7)))
	paved.append_array(RoadPath.l_path(block + Vector2i(14, 2), block + Vector2i(22, 2)))
	# a diagonal: do canto do L para sudeste
	paved.append_array(RoadPath.diagonal_path(block + Vector2i(12, 10), block + Vector2i(22, 20)))
	for cell: Vector2i in paved:
		grid.set_road(cell, IslandGrid.Road.PAVED)
	# a terra encostando no calçamento
	for cell: Vector2i in RoadPath.l_path(block + Vector2i(2, 3), block + Vector2i(2, 14)):
		grid.set_road(cell, IslandGrid.Road.DIRT)
	EventBus.roads_changed.emit(0)
	_set_hour(10.0)
	var corner := grid.cell_world(block + Vector2i(12, 2))
	await _shot("l_40m_a.png", corner, 40.0, 0.6)
	await _shot("l_40m_b.png", corner, 40.0, PI + 0.6)
	var crossing := grid.cell_world(block + Vector2i(12, 7))
	await _shot("cruzamento_40m.png", crossing, 40.0, 0.3)
	await _shot("cruzamento_70m.png", crossing, 70.0, 0.3)
	await _shot("t_40m.png", grid.cell_world(block + Vector2i(18, 2)), 40.0, PI * 0.5)
	var diagonal := grid.cell_world(block + Vector2i(16, 14))
	await _shot("diagonal_40m.png", diagonal, 40.0, 0.0)
	await _shot("diagonal_70m.png", diagonal, 70.0, PI * 0.25)
	await _shot("bloco_120m.png", grid.cell_world(block + BLOCK / 2), 120.0, 0.0)
	get_tree().quit()


## O canto de um bloco de células todo em terra e quase plano, perto do meio da ilha.
func _find_block(grid: IslandGrid, size: Vector2i) -> Vector2i:
	var center := grid.size / 2
	var best := Vector2i(4, 4)
	var best_gap := INF
	for y: int in range(4, grid.size.y - size.y - 4, 3):
		for x: int in range(4, grid.size.x - size.x - 4, 3):
			var area := Rect2i(Vector2i(x, y), size)
			if not grid.area_is_land(area) or grid.area_relief(area) > _sim.config.max_build_height_delta_m * 2.0:
				continue
			var gap := Vector2(Vector2i(x, y) + size / 2 - center).length()
			if gap < best_gap:
				best = Vector2i(x, y)
				best_gap = gap
	return best


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
