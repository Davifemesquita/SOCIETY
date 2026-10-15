extends GdUnitTestSuite
## Interface da Fase 5 com a partida de verdade no arquipélago: o jogo novo gera as 5 ilhas da
## semente, a câmera começa no litoral do entreposto e alcança todas, a ferramenta acha a ilha
## sob o ponto, e escolher a mina mostra as jazidas.

const GAME := "res://ui/screens/game_screen.tscn"
const SEED := 1840

var _runner: GdUnitSceneRunner
var _game: GameScreen
var _sim: Simulation


func before_test() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = false
	GameScreen.world_seed = SEED
	GameScreen.load_slot_on_start = ""
	# o mouse do xvfb fica no canto: com quadros lentos o pan pela borda tirava a câmera do litoral
	Settings.edge_pan = false
	_runner = scene_runner(GAME)
	_game = _runner.scene()
	_sim = _game.simulation
	GameClock.set_speed(TickClock.PAUSED)
	await _runner.simulate_frames(2)


func after_test() -> void:
	Settings.edge_pan = true
	GameScreen.use_sky3d = true
	GameScreen.world_seed = -1


func test_new_game_is_the_seed_archipelago_seen_from_the_trading_post_coast() -> void:
	assert_int(_sim.world.seed).is_equal(SEED)
	assert_int(_sim.world.islands.size()).is_equal(8)
	assert_object(_game.terrain_view).is_not_null()
	assert_object(_game.water_view).is_not_null()
	assert_int(_game.tree_view.instance_count()).is_greater(10000)
	var focus := _game.camera.rig.focus
	var cell := _sim.world.island(0).world_to_cell(focus)
	var site := SiteFinder.find(_sim, &"trading_post", 0, cell, 6)
	assert_array(site).is_not_empty()
	for grid: IslandGrid in _sim.world.islands:
		assert_bool(_game.world_bounds().encloses(grid.world_rect())).is_true()


func test_the_tool_follows_the_island_under_the_cursor() -> void:
	var other := _sim.world.island(3)
	var middle := other.cell_world(other.size / 2)
	assert_int(_game.tool.island_at(middle)).is_equal(3)
	assert_int(_game.tool.island_at(Vector3(-5000.0, 0.0, -5000.0))).is_equal(-1)


func test_choosing_the_mine_highlights_the_deposits() -> void:
	_game.tool.start_building(_sim.data.building(&"coal_mine"))
	await _runner.simulate_frames(2)
	assert_bool(_game.overlay.has_custom()).is_true()
	var site := SiteFinder.find(_sim, &"coal_mine", 0, _sim.world.island(0).size / 2)
	var origin: Vector2i = site[0]
	_game.tool.hover(origin + Vector2i(2, 2))
	assert_str(_game.tool.preview_reason()).is_equal(PlacementRules.NEEDS_TRADING_POST)
	_sim.free_build = true
	assert_str(_game.tool.preview_reason()).is_equal(PlacementRules.OK)
