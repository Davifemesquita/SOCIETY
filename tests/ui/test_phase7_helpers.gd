extends GdUnitTestSuite
## Peças da interface da Fase 7 sem tela: calculadora de proporção, notificações (o que vira aviso
## e quando), camadas de mapa e os créditos lidos do CREDITS.md.


func test_ratio_calculator_follows_the_cycles() -> void:
	var data := GameData.get_default()
	var mill := RatioCalculator.consumers(data.building(&"mill"), data)
	assert_int(mill.size()).is_equal(1)
	var bakery: BuildingDef = mill[0][0]
	var count: float = mill[0][1]
	assert_str(bakery.id).is_equal("bakery")
	assert_float(count).is_equal(2.0)
	var lumberjack := RatioCalculator.consumers(data.building(&"lumberjack"), data)
	var sawmill_count: float = lumberjack[0][1]
	assert_float(sawmill_count).is_equal(1.0)
	assert_float(RatioCalculator.residents_served(data.building(&"fishery"), data)).is_equal_approx(400.0, 0.01)
	assert_float(RatioCalculator.residents_served(data.building(&"sawmill"), data)).is_equal(0.0)
	assert_array(Array(RatioCalculator.lines(data.building(&"mill"), data))).has_size(1)


func test_a_building_stopped_for_long_enough_becomes_a_notice_once() -> void:
	var sim := SimFixture.simulation()
	SimFixture.road(sim, Vector2i(2, 10), Vector2i(60, 10))
	var sawmill := SimFixture.place(sim, &"sawmill", Vector2i(10, 6), 0)
	var watcher := NoticeWatcher.new(sim)
	sim.run_ticks(sim.config.ticks_per_second * 30)
	assert_array(watcher.check()).is_empty()
	sim.run_ticks(roundi(sim.config.stopped_notice_after_s * sim.config.ticks_per_second))
	var notices := watcher.check()
	assert_int(notices.size()).is_equal(1)
	assert_int(notices[0].building_id).is_equal(sawmill)
	assert_str(notices[0].icon).is_equal("notice_stopped")
	assert_str(notices[0].text()).contains(tr("BUILDING_SAWMILL"))
	assert_array(watcher.check()).is_empty()


func test_paused_buildings_do_not_notify() -> void:
	var sim := SimFixture.simulation()
	SimFixture.road(sim, Vector2i(2, 10), Vector2i(60, 10))
	var sawmill := SimFixture.place(sim, &"sawmill", Vector2i(10, 6), 0)
	sim.execute(SetPausedCommand.new(sawmill, true))
	var watcher := NoticeWatcher.new(sim)
	sim.run_ticks(roundi(sim.config.stopped_notice_after_s * sim.config.ticks_per_second) * 2)
	assert_array(watcher.check()).is_empty()


func test_full_storage_notifies_once_until_it_drops() -> void:
	var sim := SimFixture.simulation(Vector2i(120, 40), 50, true)
	SimFixture.port(sim)
	var watcher := NoticeWatcher.new(sim)
	var capacity := sim.storage_capacity(0)
	sim.world.economy(0).stock[&"fish"] = capacity
	var notices := watcher.check()
	assert_int(notices.size()).is_equal(1)
	assert_str(notices[0].icon).is_equal("notice_storage_full")
	assert_int(notices[0].building_id).is_not_equal(0)
	assert_array(watcher.check()).is_empty()
	sim.world.economy(0).stock[&"fish"] = capacity * 0.5
	watcher.check()
	sim.world.economy(0).stock[&"fish"] = capacity
	assert_int(watcher.check().size()).is_equal(1)


func test_a_ship_arriving_is_a_notice_pointing_to_the_ship() -> void:
	var sim := SimFixture.two_islands()
	var ship_id := SimFixture.ship(sim)
	var watcher := NoticeWatcher.new(sim)
	sim.execute(MoveShipCommand.new(ship_id, 1))
	sim.run_ticks(5)
	assert_array(watcher.check()).is_empty()
	var arrived := false
	for step: int in 400:
		sim.run_ticks(5)
		for notice: NoticeWatcher.Notice in watcher.check():
			arrived = arrived or (notice.ship_id == ship_id and notice.icon == "notice_ship_arrived")
		if arrived:
			break
	assert_bool(arrived).is_true()


func test_overlays_paint_what_they_show() -> void:
	var sim := SimFixture.simulation(Vector2i(120, 40), 50, true)
	SimFixture.port(sim)
	SimFixture.road(sim, Vector2i(2, 10), Vector2i(100, 10))
	var market := SimFixture.place(sim, &"market", Vector2i(40, 11), 0)
	SimFixture.house(sim, 50, 10, &"peasants", 5.0)
	var brickworks := SimFixture.place(sim, &"brickworks", Vector2i(80, 11), 0)
	for layer: MapOverlays.Layer in MapOverlays.ICONS:
		var image := MapOverlays.image(layer, sim, 0)
		assert_object(image).override_failure_message("camada %d" % layer).is_not_null()
		assert_vector(Vector2(image.get_size())).is_equal(Vector2(sim.world.island(0).size))
	var service := MapOverlays.service(sim, 0)
	var reach: PackedInt32Array = sim.derived_state().service_reach[market]
	assert_float(service.get_pixelv(sim.world.island(0).cell_at(reach[0])).a).is_greater(0.0)
	var pollution := MapOverlays.pollution(sim, 0)
	var record := sim.world.building(brickworks)
	assert_float(pollution.get_pixelv(record.origin + Vector2i(1, 1)).a).is_greater(0.0)
	assert_float(pollution.get_pixelv(Vector2i(2, 30)).a).is_equal(0.0)
	assert_float(MapOverlays.roads(sim.world.island(0)).get_pixelv(Vector2i(20, 10)).a).is_greater(0.0)
	assert_float(MapOverlays.fertility(sim, 0).get_pixelv(Vector2i(5, 30)).a).is_greater(0.0)


func test_credits_come_from_the_credits_file_with_icons_and_fonts() -> void:
	var entries := CreditsDialog.entries(FileAccess.get_file_as_string(CreditsDialog.CREDITS_PATH))
	assert_int(entries.size()).is_greater(10)
	var names := entries.map(func(entry: PackedStringArray) -> String: return entry[0])
	assert_bool(names.any(func(name: String) -> bool: return name.contains("game-icons"))).is_true()
	assert_bool(names.any(func(name: String) -> bool: return name.contains("Old Standard"))).is_true()
	assert_bool(names.any(func(name: String) -> bool: return name.contains("Playfair"))).is_true()
	assert_str(CreditsDialog.bbcode(entries)).contains("[b]")
