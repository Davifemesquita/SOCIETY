extends GdUnitTestSuite
## Interface da Fase 8: a ferramenta calça com paralelepípedo e muda prédio de lugar (com a prévia
## e o motivo da recusa), e a partida nova abre com o conselheiro apresentando a primeira meta,
## com as falas vindas do Dialogue Manager e traduzidas.

const GAME := "res://ui/screens/game_screen.tscn"

var _sim: Simulation
var _tool: BuildTool


func _tool_on_small_island() -> void:
	var config := GameConfig.new()
	config.main_island_size_cells = Vector2i(60, 60)
	config.instant_logistics = true
	_sim = Simulation.new(config, GameData.get_default())
	_sim.free_build = true
	_tool = auto_free(BuildTool.new())
	_tool.setup(_sim, null, config.cell_size_m)


func test_paved_road_tool_lays_cobblestone_and_reports_the_lock() -> void:
	_tool_on_small_island()
	_tool.start_paved_road()
	assert_int(_tool.mode).is_equal(BuildTool.Mode.ROAD)
	assert_bool(_tool.road_paved).is_true()
	_tool.press(Vector2i(5, 20))
	_tool.hover(Vector2i(14, 20))
	assert_dict(_tool.road_materials()).is_equal({&"bricks": 5})
	_tool.release(Vector2i(14, 20))
	assert_bool(_sim.world.island(0).is_paved(Vector2i(10, 20))).is_true()
	# sem os operários que o liberam, a prévia diz por quê
	_sim.free_build = false
	_tool.hover(Vector2i(5, 30))
	assert_str(_tool.preview_reason()).is_equal(PlacementRules.LOCKED)
	# e a estrada de terra continua de terra
	_tool.start_road()
	assert_bool(_tool.road_paved).is_false()


func test_move_tool_carries_the_selected_building() -> void:
	_tool_on_small_island()
	_tool.start_building(_sim.data.building(&"house"))
	_tool.press(Vector2i(10, 10))
	var house := _sim.world.island(0).building_at(Vector2i(10, 10))
	_tool.cancel()
	_tool.start_move(house)
	assert_int(_tool.mode).is_equal(BuildTool.Mode.MOVE)
	_tool.hover(Vector2i(10, 10))
	assert_str(_tool.preview_reason()).is_equal(MoveBuildingCommand.SAME_PLACE)
	_tool.hover(Vector2i(30, 30))
	assert_str(_tool.preview_reason()).is_equal(PlacementRules.OK)
	_tool.press(Vector2i(30, 30))
	assert_int(_sim.world.island(0).building_at(Vector2i(30, 30))).is_equal(house)
	assert_int(_sim.world.island(0).building_at(Vector2i(10, 10))).is_equal(0)
	assert_int(_tool.mode).is_equal(BuildTool.Mode.NONE)
	assert_int(_tool.selected_id).is_equal(house)


func test_a_new_game_opens_with_the_advisor_and_the_first_goal() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(10)
	var panel := game.hud.goal_panel
	var first := game.simulation.data.goals[0]
	assert_str(panel._goal_title.text).is_equal(GoalPanel.title_of(first))
	assert_str(panel._goal_title.text).is_not_equal(first.title_key())
	var speech := panel.speech_text()
	assert_str(speech).is_not_empty()
	assert_str(speech).is_equal(tr("ADVISOR_TRADING_POST_1"))
	assert_bool(speech.begins_with("ADVISOR_")).is_false()
	panel.advance()
	assert_str(panel.speech_text()).is_equal(tr("ADVISOR_TRADING_POST_2"))
	panel.advance()
	assert_str(panel.speech_text()).is_empty()
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false


func test_every_goal_has_its_lines_and_title() -> void:
	var data := GameData.get_default()
	for goal: GoalDef in data.goals:
		assert_str(tr(goal.title_key())).override_failure_message(goal.title_key()).is_not_equal(goal.title_key())
		for title: String in [String(goal.id), String(goal.id) + "_done"]:
			var lines := await AdvisorDialogue.lines(Engine.get_main_loop() as SceneTree, title)
			assert_bool(lines.is_empty()).override_failure_message("sem falas: " + title).is_false()
			# o Dialogue Manager já devolve a fala traduzida pela chave
			for line: String in lines:
				assert_bool(line.begins_with("ADVISOR_")).override_failure_message("sem tradução: " + line).is_false()
