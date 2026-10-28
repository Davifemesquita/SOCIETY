extends GdUnitTestSuite
## A ferrovia na tela (Fase 70): o cartão do trilho na aba da infraestrutura, o arrasto que põe trilho (sempre em L),
## a prévia recusando trilho sobre estrada, e o desenho do trilho na vista; o poço e a usina a petróleo no menu, com
## ícone e foto.

const GAME := "res://ui/screens/game_screen.tscn"

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _sim: Simulation


func before_test() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await _runner.simulate_frames(2)


func after_test() -> void:
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false


func test_the_rail_tool_lays_rail() -> void:
	_sim.free_build = true
	var tool := _game.tool
	tool.start_rail()
	assert_int(tool.mode).is_equal(BuildTool.Mode.ROAD)
	assert_bool(tool.road_rail).is_true()
	tool.road_diagonal = true
	tool.press(Vector2i(40, 60))
	tool.hover(Vector2i(46, 63))
	# sempre em L: cada célula vizinha de lado da anterior
	var cells := tool.road_cells()
	for index: int in range(1, cells.size()):
		assert_int(absi(cells[index].x - cells[index - 1].x) + absi(cells[index].y - cells[index - 1].y)).is_equal(1)
	tool.release(Vector2i(46, 63))
	await _runner.simulate_frames(2)
	var grid := _sim.world.island(0)
	assert_bool(grid.has_rail(Vector2i(40, 60))).is_true()
	assert_object(_game.rail_view.rail_mesh(0)).is_not_null()
	# a estrada não passa por cima do trilho, e o trilho não passa por cima da estrada
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(50, 50), Vector2i(55, 50))))
	tool.start_rail()
	tool.hover(Vector2i(52, 50))
	assert_str(String(tool.preview_reason())).is_equal(String(PlacementRules.ON_ROAD))
	tool.start_road()
	tool.hover(Vector2i(40, 60))
	assert_str(String(tool.preview_reason())).is_equal(String(PlacementRules.ON_RAIL))


func test_the_menu_has_the_rail_card_and_the_oil_buildings() -> void:
	var groups: Array[Array] = _game.hud._categories()
	var all: Array = []
	for group: Array in groups:
		all.append_array(group)
	for id: StringName in [&"oil_well", &"oil_power_station"]:
		assert_bool(all.any(func(def: BuildingDef) -> bool: return def.id == id)).override_failure_message(String(id)).is_true()
		assert_object(Icons.building(id)).is_not_null()
		assert_object(Icons.photo(id)).override_failure_message("foto " + String(id)).is_not_null()
	assert_object(Icons.good(&"oil")).is_not_null()
	assert_object(Icons.action("rail")).is_not_null()
	assert_str(tr("HUD_RAIL_TIP")).is_not_equal("HUD_RAIL_TIP")
