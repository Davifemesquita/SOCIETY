extends GdUnitTestSuite
## Desfazer e planta na interface (Fase 49): o modo planta desenha sem custo e o arrasto de demolir apaga plantas,
## construir as plantas e desfazer tudo de uma vez, o arrasto com Ctrl substitui em área, Ctrl+Z e Ctrl+Shift+Z fixos, os
## botões da HUD e os fantasmas das plantas.

const GAME := "res://ui/screens/game_screen.tscn"
const NEW_KEYS: Array[String] = ["HUD_PLAN_TIP", "HUD_BUILD_PLANS_TIP", "HUD_UNDO_TIP", "HUD_REDO_TIP", "HUD_HINT_PLAN",
		"HUD_HINT_REPLACE", "ACTION_BUILD_PLAN", "REASON_NOTHING_TO_UNDO", "REASON_UNDO_EXPIRED", "REASON_UNDO_CHANGED",
		"REASON_OVER_PLAN", "REASON_NO_PLAN_HERE", "REASON_NOTHING_TO_REPLACE", "ROUTES_NAME", "ROUTES_NAME_TIP",
		"ROUTES_GROUP", "ROUTES_GROUP_TIP"]

var _sim: Simulation
var _tool: BuildTool


func after_test() -> void:
	TranslationServer.set_locale("pt_BR")
	GameScreen.use_sky3d = true
	GameClock.set_speed(TickClock.PAUSED)


func _tool_on_small_island() -> void:
	var config := GameConfig.new()
	config.main_island_size_cells = Vector2i(60, 60)
	config.instant_logistics = true
	_sim = Simulation.new(config, GameData.get_default())
	_sim.free_build = true
	_tool = auto_free(BuildTool.new())
	_tool.setup(_sim, null, config.cell_size_m)


func test_plan_mode_draws_without_cost_and_builds_later() -> void:
	_tool_on_small_island()
	_sim.free_build = false
	_sim.world.money = 5000.0
	_sim.world.economy(0).stock[&"planks"] = 20.0
	_tool.start_building(_sim.data.building(&"house"))
	_tool.toggle_plan_mode()
	_tool.hover(Vector2i(10, 10))
	assert_str(_tool.preview_reason()).is_equal(PlacementRules.OK)
	_tool.press(Vector2i(10, 10))
	_tool.press(Vector2i(20, 10))
	assert_int(_sim.world.plans.size()).is_equal(2)
	assert_float(_sim.world.money).is_equal(5000.0)
	assert_int(_sim.world.island(0).building_at(Vector2i(10, 10))).is_equal(0)
	assert_bool(_tool.build_plans()).is_true()
	assert_int(_sim.world.plans.size()).is_equal(0)
	assert_int(_sim.world.island(0).building_at(Vector2i(10, 10))).is_not_equal(0)
	# desfazer tira as duas casas de uma vez e as plantas voltam; refazer constrói de novo
	assert_bool(_tool.undo()).is_true()
	assert_int(_sim.world.plans.size()).is_equal(2)
	assert_float(_sim.world.money).is_equal(5000.0)
	assert_bool(_tool.redo()).is_true()
	assert_int(_sim.world.plans.size()).is_equal(0)
	# no modo planta, o arrasto de demolir apaga plantas (e não prédios)
	_tool.start_building(_sim.data.building(&"house"))
	_tool.press(Vector2i(40, 40))
	_tool.start_demolish()
	_tool.press(Vector2i(38, 38))
	_tool.release(Vector2i(44, 44))
	assert_int(_sim.world.plans.size()).is_equal(0)
	assert_int(_sim.world.island(0).building_at(Vector2i(10, 10))).is_not_equal(0)


func test_ctrl_drag_replaces_in_an_area() -> void:
	_tool_on_small_island()
	var bakery := _sim.data.building(&"bakery")
	var other: BuildingDef = null
	for def: BuildingDef in _sim.data.buildings:
		if def.id != bakery.id and def.size == bakery.size and def.is_production() and def.terrain == BuildingDef.Terrain.NONE \
				and def.modules_required == 0:
			other = def
			break
	for x: int in [10, 20]:
		_sim.execute(PlaceBuildingCommand.new(0, &"bakery", Vector2i(x, 10), 0))
	_tool.start_building(other)
	_tool.replace_drag = true
	_tool.press(Vector2i(8, 8))
	assert_bool(_tool.dragging).is_true()
	_tool.release(Vector2i(30, 16))
	assert_str(_sim.world.building(_sim.world.island(0).building_at(Vector2i(10, 10))).def_id).is_equal(other.id)
	assert_str(_sim.world.building(_sim.world.island(0).building_at(Vector2i(20, 10))).def_id).is_equal(other.id)
	assert_bool(_tool.undo()).is_true()
	assert_str(_sim.world.building(_sim.world.island(0).building_at(Vector2i(10, 10))).def_id).is_equal("bakery")


func test_undo_and_redo_keys_are_fixed_with_ctrl() -> void:
	for action: StringName in [&"game_undo", &"game_redo"]:
		assert_bool(InputMap.has_action(action)).is_true()
		assert_bool(InputActions.remappable().has(action)).is_false()
	assert_bool(InputActions.remappable().has(&"build_plan")).is_true()
	var undo := InputEventKey.new()
	undo.physical_keycode = KEY_Z
	undo.ctrl_pressed = true
	undo.pressed = true
	assert_bool(InputMap.event_is_action(undo, &"game_undo", true)).is_true()
	assert_bool(InputMap.event_is_action(undo, &"game_redo", true)).is_false()
	var redo := InputEventKey.new()
	redo.physical_keycode = KEY_Z
	redo.ctrl_pressed = true
	redo.shift_pressed = true
	redo.pressed = true
	assert_bool(InputMap.event_is_action(redo, &"game_redo", true)).is_true()
	assert_bool(InputMap.event_is_action(redo, &"game_undo", true)).is_false()


func test_the_hud_buttons_and_the_plan_ghosts() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(6)
	var sim := game.simulation
	sim.free_build = true
	var hud := game.hud
	var undo := hud.find_child("Undo", true, false) as Button
	assert_bool(undo.disabled).is_true()
	game.tool.start_building(sim.data.building(&"house"))
	game.tool.press(Vector2i(20, 20))
	hud._refresh()
	assert_bool(undo.disabled).is_false()
	(hud.find_child("PlanToggle", true, false) as Button).pressed.emit()
	assert_bool(game.tool.plan_mode).is_true()
	game.tool.press(Vector2i(30, 20))
	assert_int(game.plan_view.ghost_count()).is_equal(1)
	var plan_id: int = sim.world.plans.keys()[0]
	assert_bool(game.plan_view.is_blocked(plan_id)).is_false()
	# um prédio de verdade por cima: o fantasma fica listrado
	sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(30, 20), 0))
	assert_bool(game.plan_view.is_blocked(plan_id)).is_true()
	undo.pressed.emit()
	assert_int(sim.world.island(0).building_at(Vector2i(30, 20))).is_not_equal(0)


func test_the_new_texts_exist_in_both_languages() -> void:
	for locale: String in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in NEW_KEYS:
			assert_str(tr(key)).override_failure_message("%s em %s" % [key, locale]).is_not_equal(key)


func test_route_names_and_groups_order_the_list() -> void:
	_tool_on_small_island()
	var world := _sim.world
	var ids: Array[int] = []
	for i: int in 3:
		ids.append(_sim.execute(CreateRouteCommand.new()).created_id)
	_sim.execute(RenameRouteCommand.new(ids[0], "", ""))
	_sim.execute(RenameRouteCommand.new(ids[1], "Lã", "Sul"))
	_sim.execute(RenameRouteCommand.new(ids[2], "", "Norte"))
	assert_array(RouteWindow.ordered(world)).is_equal([ids[2], ids[1], ids[0]])
	TranslationServer.set_locale("pt_BR")
	assert_str(RouteWindow.display_name(world.routes[ids[1]])).is_equal("[Sul] Lã")
	assert_str(RouteWindow.display_name(world.routes[ids[0]])).is_equal(tr("ROUTE_NAME") % ids[0])
