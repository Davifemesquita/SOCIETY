extends GdUnitTestSuite
## O turismo na tela (Fase 68): o painel do entreposto mostra a atratividade da ilha e o que os turistas pagam, com os
## eventos ligados (sem eles, a linha some); a parcela dos turistas no detalhamento do dinheiro tem nome traduzido.

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


func _line(panel: Control, prefix: String) -> Label:
	for node: Node in panel.find_children("*", "Label", true, false):
		var label: Label = node
		if label.is_visible_in_tree() and label.text.begins_with(prefix):
			return label
	return null


func test_the_trading_post_shows_the_attractiveness() -> void:
	_sim.free_build = true
	var post := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(60, 0), 2))
	assert_bool(post.ok()).is_true()
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(40, 6), Vector2i(100, 6))))
	_sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(70, 3), 2))
	_sim.execute(PlaceBuildingCommand.new(0, &"fountain_square", Vector2i(80, 7), 0))
	_sim.world.events_state.enabled = true
	_game.tool.select(post.placed[0])
	await _runner.simulate_frames(3)
	var panel := _game.hud.selection_panel
	var prefix := tr("PANEL_ATTRACTIVENESS").get_slice("%", 0)
	var line := _line(panel, prefix)
	assert_object(line).override_failure_message("sem a linha da atratividade").is_not_null()
	assert_str(line.text).not_contains("%")
	# sem os eventos, sem turismo: a linha some
	_sim.world.events_state.enabled = false
	panel._refresh()
	await _runner.simulate_frames(2)
	assert_object(_line(panel, prefix)).is_null()
	var source := Breakdown.Source.new(Breakdown.Kind.TOURISM, &"")
	assert_str(BreakdownLabel.name_of(source, _sim.data)).is_equal(tr("BREAKDOWN_TOURISM"))
