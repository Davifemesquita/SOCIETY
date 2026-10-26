extends GdUnitTestSuite
## QoL de interface (Fase 47): copiar prédio (tipo, rotação e configuração), busca no menu de construção em pt_BR e en,
## os atalhos novos sem tecla e remapeáveis, do prédio para a estatística e da estatística para os produtores, a dica
## que decompõe o número, as ações de rota (duplicar, vaga cheia, destaque no mapa, filtro guardado) e o modo foto.

const GAME := "res://ui/screens/game_screen.tscn"
const NEW_KEYS: Array[String] = ["BREAKDOWN_NOTHING", "BREAKDOWN_PER_MIN", "BREAKDOWN_BUILDINGS", "BREAKDOWN_SHIPS",
		"BREAKDOWN_SALARIES", "BREAKDOWN_TREATY", "BREAKDOWN_MONEY", "BREAKDOWN_GOOD", "STATS_PRODUCERS_TIP",
		"PANEL_NEXT_SAME", "PANEL_NEXT_SAME_TIP", "PANEL_STATISTICS", "PANEL_STATISTICS_TIP", "HUD_SEARCH",
		"HUD_SEARCH_TIP", "HUD_SEARCH_NONE", "TIP_EXISTING", "ACTION_BUILD_COPY", "ACTION_BUILD_SEARCH",
		"ACTION_PHOTO_MODE", "PHOTO_HOUR", "PHOTO_HOUR_TIP", "PHOTO_TILT", "PHOTO_TILT_TIP", "PHOTO_EXIT", "PHOTO_EXIT_TIP",
		"MENU_PHOTO", "MENU_PHOTO_TIP", "ROUTES_FILTER_TIP", "ROUTES_FILTER_ALL", "ROUTES_DUPLICATE", "ROUTES_DUPLICATE_TIP"]

var _sim: Simulation
var _tool: BuildTool


func after_test() -> void:
	TranslationServer.set_locale("pt_BR")
	Settings.route_filter = -1
	Settings.reset_keys()
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


func _game(runner_frames: int = 6) -> GameScreen:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(runner_frames)
	game.simulation.free_build = true
	return game


func test_copy_keeps_type_rotation_and_settings() -> void:
	_tool_on_small_island()
	_tool.rotation = 1
	_tool.start_building(_sim.data.building(&"bakery"))
	_tool.press(Vector2i(10, 10))
	var bakery := _sim.world.island(0).building_at(Vector2i(10, 10))
	_sim.execute(SetPausedCommand.new(bakery, true))
	_tool.cancel()
	_tool.rotation = 3
	assert_bool(_tool.copy_building(bakery)).is_true()
	assert_int(_tool.mode).is_equal(BuildTool.Mode.BUILDING)
	assert_str(_tool.building_def.id).is_equal("bakery")
	assert_int(_tool.rotation).is_equal(1)
	_tool.press(Vector2i(30, 30))
	var copy := _sim.world.building(_sim.world.island(0).building_at(Vector2i(30, 30)))
	assert_str(copy.def_id).is_equal("bakery")
	assert_int(copy.rotation).is_equal(1)
	assert_bool(copy.paused).is_true()
	# a casa leva o bloqueio da subida de classe; uma obra comum depois não copia mais nada
	_tool.start_building(_sim.data.building(&"house"))
	_tool.press(Vector2i(10, 40))
	var house := _sim.world.island(0).building_at(Vector2i(10, 40))
	_sim.execute(SetUpgradeBlockedCommand.new(house, true))
	_tool.copy_building(house)
	_tool.press(Vector2i(20, 40))
	assert_bool(_sim.world.building(_sim.world.island(0).building_at(Vector2i(20, 40))).upgrade_blocked).is_true()
	_tool.start_building(_sim.data.building(&"house"))
	assert_bool(_tool.copying).is_false()
	_tool.press(Vector2i(30, 40))
	assert_bool(_sim.world.building(_sim.world.island(0).building_at(Vector2i(30, 40))).upgrade_blocked).is_false()
	assert_bool(_tool.copy_building(0)).is_false()


func test_search_finds_buildings_by_name_in_both_languages() -> void:
	var game: GameScreen = await _game()
	var hud := game.hud
	assert_str(Hud.folded("  Ação Pão  ")).is_equal("acao pao")
	TranslationServer.set_locale("pt_BR")
	var found := hud.search_results("PADAR")
	assert_array(found.map(func(def: BuildingDef) -> StringName: return def.id)).contains([&"bakery"])
	TranslationServer.set_locale("en")
	found = hud.search_results("baker")
	assert_array(found.map(func(def: BuildingDef) -> StringName: return def.id)).contains([&"bakery"])
	# a busca troca os cartões da aba pelos achados de todas as abas; nada achado, o aviso
	hud.search("baker")
	var items := hud.find_child("BuildItems", true, false)
	assert_object(items.find_child("Item_bakery", true, false)).is_not_null()
	hud.search("zzzz")
	assert_object(items.find_child("SearchNone", true, false)).is_not_null()
	hud.search("")
	assert_object(items.find_child("SearchNone", true, false)).is_null()
	assert_array(hud.search_results("")).is_empty()


func test_new_shortcuts_start_unbound_and_can_be_remapped() -> void:
	for action: StringName in [&"build_copy", &"build_search", &"photo_mode"]:
		assert_bool(InputActions.remappable().has(action)).override_failure_message(str(action)).is_true()
		assert_array(InputActions.KEYS[action]).is_empty()
		assert_array(Settings.keys_of(action)).is_empty()
	Settings.bind_key(&"build_copy", KEY_C)
	assert_bool(Settings.keys_of(&"build_copy").has(KEY_C)).is_true()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_C
	press.pressed = true
	assert_bool(InputMap.event_is_action(press, &"build_copy")).is_true()


func test_from_the_building_to_its_statistics_and_its_producers() -> void:
	var game: GameScreen = await _game()
	var sim := game.simulation
	var first := SimFixture.place(sim, &"bakery", Vector2i(20, 20))
	var second := SimFixture.place(sim, &"bakery", Vector2i(30, 20))
	game.tool.select(first)
	var panel := game.hud.selection_panel
	(panel.find_child("Statistics", true, false) as Button).pressed.emit()
	var stats := game.hud.statistics_window
	assert_bool(stats.visible).is_true()
	assert_str(stats.chart_good()).is_equal("bread")
	assert_int(stats.selected_island()).is_equal(0)
	# da estatística: o próximo produtor, e volta ao primeiro
	stats.producer_requested.emit(&"bread", 0)
	assert_int(game.tool.selected_id).is_equal(second)
	stats.producer_requested.emit(&"bread", 0)
	assert_int(game.tool.selected_id).is_equal(first)
	# o "próximo igual" do painel passa pelos do mesmo tipo
	assert_int(SelectionPanel.next_same(sim.world, first)).is_equal(second)
	assert_int(SelectionPanel.next_same(sim.world, second)).is_equal(first)
	assert_array(SelectionPanel.same_kind(sim.world, &"bakery")).is_equal([first, second])


func test_the_breakdown_tip_lists_sources_and_the_total() -> void:
	var data := GameData.get_default()
	var made := Breakdown.Source.new(Breakdown.Kind.BUILDING, &"bakery")
	made.count = 2
	made.per_min = 2.0
	var eaten := Breakdown.Source.new(Breakdown.Kind.TIER, &"workers")
	eaten.per_min = -0.75
	var sources: Array[Breakdown.Source] = [made, eaten]
	TranslationServer.set_locale("pt_BR")
	var text := BreakdownLabel.text_of(sources, data, 2, "Pão")
	assert_str(text).contains("+2,00")
	assert_str(text).contains("−0,75")
	assert_str(text).contains(tr(data.building(&"bakery").name_key) + " ×2")
	assert_str(text).contains(tr(data.tier(&"workers").name_key))
	assert_str(text).contains("= +1,25")
	assert_str(BreakdownLabel.text_of([], data, 0, "")).contains(tr("BREAKDOWN_NOTHING"))


func test_route_actions() -> void:
	var game: GameScreen = await _game()
	var window := game.hud.route_window
	window.toggle()
	window.create_route()
	window.add_stop_to_route()
	window.add_stop_to_route()
	window.add_order(window.stops()[0], true)
	var merchant := game.simulation.data.ship(&"merchant_ship")
	assert_int(window.stops()[0].orders[0].tons).is_equal(merchant.slot_capacity_t)
	window.add_order(window.stops()[0], false)
	assert_int(window.stops()[0].orders[1].tons).is_equal(50)
	var original: int = game.simulation.world.route_ids()[0]
	window.duplicate_route()
	var routes := game.simulation.world.route_ids()
	assert_int(routes.size()).is_equal(2)
	var copy: TradeRoute = game.simulation.world.routes[routes[1]]
	var source: TradeRoute = game.simulation.world.routes[original]
	assert_int(copy.stops.size()).is_equal(source.stops.size())
	assert_int(copy.stops[0].orders.size()).is_equal(2)
	# a cópia é independente
	assert_bool(copy.stops[0] == source.stops[0]).is_false()
	window.hover_route(original)
	assert_int(window.map.hover_route_id).is_equal(original)
	window.hover_route(0)
	assert_int(window.map.hover_route_id).is_equal(0)
	# o filtro por ilha
	assert_bool(RouteWindow.passes_filter(copy, -1)).is_true()
	assert_bool(RouteWindow.passes_filter(copy, copy.stops[0].target)).is_true()
	assert_bool(RouteWindow.passes_filter(copy, 7)).is_false()


func test_the_route_filter_is_kept_in_the_settings() -> void:
	var path := "user://test_settings_phase47.cfg"
	Settings.route_filter = 2
	Settings.save_to(path)
	Settings.route_filter = -1
	Settings.load_from(path)
	assert_int(Settings.route_filter).is_equal(2)
	DirAccess.remove_absolute(path)


func test_photo_mode_hides_the_interface_and_gives_everything_back() -> void:
	var game: GameScreen = await _game()
	GameClock.set_speed(0)
	var extra := GameClock.clock.extra_hours
	var photo := game.photo_mode
	photo.toggle()
	assert_bool(photo.active).is_true()
	assert_bool(photo.visible).is_true()
	assert_bool(game.hud.visible).is_false()
	assert_int(GameClock.clock.speed_index).is_equal(TickClock.PAUSED)
	assert_bool(game.tool.is_processing_unhandled_input()).is_false()
	assert_bool(game.building_view.hide_icons).is_true()
	photo.set_hour(18.0)
	assert_float((photo.find_child("PhotoHour", true, false) as HSlider).value).is_equal(18.0)
	assert_float(GameClock.clock.hour()).is_equal_approx(18.0, 0.01)
	var pitch := game.camera.rig.pitch()
	(photo.find_child("PhotoTilt", true, false) as HSlider).value = PhotoMode.PITCH_RANGE_DEG.y
	assert_float(game.camera.rig.pitch()).is_greater(pitch)
	photo.toggle()
	assert_bool(photo.active).is_false()
	assert_bool(game.hud.visible).is_true()
	assert_int(GameClock.clock.speed_index).is_equal(0)
	assert_float(GameClock.clock.extra_hours).is_equal(extra)
	assert_float(game.camera.rig.pitch_offset_deg).is_equal(0.0)
	assert_bool(game.tool.is_processing_unhandled_input()).is_true()
	assert_bool(game.building_view.hide_icons).is_false()
	# a entrada no menu da partida
	var menu: GameMenu = auto_free(GameMenu.new())
	assert_object(menu.find_child("MENU_PHOTO", true, false)).is_not_null()


func test_the_new_texts_exist_in_both_languages() -> void:
	for locale: String in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		for key: String in NEW_KEYS:
			assert_str(tr(key)).override_failure_message("%s em %s" % [key, locale]).is_not_equal(key)
