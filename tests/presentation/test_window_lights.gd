extends GdUnitTestSuite
## Janelas acesas à noite (seções 9 e 11): vidros nas fachadas, acesos se o prédio está aceso, e
## as luzes de área só de noite e perto da câmera.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 30))
	SimFixture.road(_sim, Vector2i(2, 10), Vector2i(50, 10))


func _view() -> WindowLightsView:
	var view: WindowLightsView = auto_free(WindowLightsView.new())
	add_child(view)
	view.setup(_sim, _sim.config)
	return view


func test_house_gets_windows_on_every_facade_outside_the_walls() -> void:
	var house := _sim.world.building(SimFixture.house(_sim, 4, 10, &"peasants", 10.0))
	var def := _sim.def_of(house)
	var windows := WindowLightsView.windows_of(_sim.world.island(0), house, def, 4.0)
	assert_int(windows.size()).is_equal(8)
	var center := GridSpace.rect_center(Footprint.rect(house.origin, def.size, house.rotation), 2.0)
	for window: Transform3D in windows:
		var offset := window.origin - Vector3(center.x, window.origin.y, center.z)
		assert_float(maxf(absf(offset.x), absf(offset.z))).is_greater(2.85)
		assert_float(window.origin.y).is_between(1.0, 4.0)
		# o vidro olha para fora (+Z da janela = normal da fachada)
		assert_float(window.basis.z.dot(offset.normalized())).is_greater(0.5)


func test_taller_house_gets_a_second_floor_and_the_door_stays_clear() -> void:
	var house := _sim.world.building(SimFixture.house(_sim, 4, 10, &"workers", 20.0))
	var def := _sim.def_of(house)
	assert_int(WindowLightsView.windows_of(_sim.world.island(0), house, def, 6.5).size()).is_equal(16)
	# a geometria das janelas só depende do tamanho e da rotação: não precisa estar no litoral
	var wide := BuildingRecord.new(99, &"trading_post", 0, Vector2i(30, 11), 0)
	var wide_def := _sim.data.building(&"trading_post")
	var door := GridSpace.cell_center(Footprint.entrance_cell(wide.origin, wide_def.size, wide.rotation), 2.0)
	for window: Transform3D in WindowLightsView.windows_of(_sim.world.island(0), wide, wide_def, 4.0):
		var flat := Vector2(window.origin.x - door.x, window.origin.z - door.z)
		assert_bool(window.origin.y < 2.5 and flat.length() < 1.6).is_false()


func test_lit_means_people_at_home_work_going_on_or_service_open() -> void:
	var house := _sim.world.building(SimFixture.house(_sim, 4, 10, &"peasants", 10.0))
	var empty := _sim.world.building(SimFixture.house(_sim, 7, 10, &"peasants", 0.0))
	var work := _sim.world.building(SimFixture.place(_sim, &"lumberjack", Vector2i(14, 11), 0))
	var market := _sim.world.building(SimFixture.place(_sim, &"market", Vector2i(20, 11), 0))
	assert_bool(WindowLightsView.is_lit(_sim, house)).is_true()
	assert_bool(WindowLightsView.is_lit(_sim, empty)).is_false()
	work.productivity = 0.0
	assert_bool(WindowLightsView.is_lit(_sim, work)).is_false()
	work.productivity = 1.0
	assert_bool(WindowLightsView.is_lit(_sim, work)).is_true()
	work.paused = true
	assert_bool(WindowLightsView.is_lit(_sim, work)).is_false()
	assert_bool(WindowLightsView.is_lit(_sim, market)).is_true()


func test_demolishing_frees_the_windows() -> void:
	var view := _view()
	var house := SimFixture.house(_sim, 4, 10, &"peasants", 10.0)
	SimFixture.house(_sim, 7, 10, &"peasants", 10.0)
	var each := WindowLightsView.building_windows(_sim, _sim.world.building(house)).size()
	assert_int(each).is_greater(7)
	assert_int(view.window_count()).is_equal(each * 2)
	_sim.execute(DemolishCommand.new(0, Rect2i(_sim.world.building(house).origin, Vector2i(1, 1))))
	assert_int(view.window_count()).is_equal(each)


func test_model_windows_sit_on_the_facades_and_skip_the_door() -> void:
	var house := _sim.world.building(SimFixture.house(_sim, 4, 10, &"workers", 10.0))
	var def := _sim.def_of(house)
	var area := Footprint.rect(house.origin, def.size, house.rotation)
	var center := GridSpace.rect_center(area, 2.0)
	var door := GridSpace.cell_center(Footprint.entrance_cell(house.origin, def.size, house.rotation), 2.0)
	var windows := WindowLightsView.building_windows(_sim, house)
	var spec := BuildingKit.spec_for(_sim, house, 2.0)
	# uma janela por célula da borda e por andar, menos a porta
	assert_int(windows.size()).is_equal((def.size.x + def.size.y) * 2 * spec.floors() - 1)
	var half := spec.size_m().x * 0.5
	for window: Transform3D in windows:
		var offset := window.origin - Vector3(center.x, window.origin.y, center.z)
		assert_float(maxf(absf(offset.x), absf(offset.z))).is_between(half, half + 0.2)
		assert_float(window.basis.z.normalized().dot(offset.normalized())).is_greater(0.5)
		var flat := Vector2(window.origin.x - door.x, window.origin.z - door.z)
		assert_bool(window.origin.y < spec.floor_m() and flat.length() < 2.0).is_false()


func test_area_lights_only_at_night_and_with_the_camera_close() -> void:
	var view := _view()
	for i: int in 4:
		SimFixture.house(_sim, 4 + i * 3, 10, &"peasants", 10.0)
	# os moradores chegam depois de a casa ser construída
	view.refresh_lit()
	var above := Vector3(12.0, 40.0, 30.0)
	var down := (Vector3(12.0, 0.0, 18.0) - above).normalized()
	view.place_area_lights(above, down, 1.0)
	assert_int(view.lit_area_lights()).is_equal(4)
	view.place_area_lights(above, down, 0.0)
	assert_int(view.lit_area_lights()).is_equal(0)
	var far := Vector3(12.0, 300.0, 300.0)
	view.place_area_lights(far, (Vector3(12.0, 0.0, 18.0) - far).normalized(), 1.0)
	assert_int(view.lit_area_lights()).is_equal(0)


func test_piers_and_decorations_get_no_windows() -> void:
	# o trapiche (Fase 15) e a árvore plantada (Fase 16) não têm fachada: a árvore ganhava janela preta
	var view := _view()
	var before := view.window_count()
	SimFixture.place(_sim, &"planted_tree", Vector2i(20, 14), 0)
	SimFixture.place(_sim, &"pier", Vector2i(30, 0), 2)
	view.rebuild()
	assert_int(view.window_count()).is_equal(before)


func test_the_upgraded_warehouse_trades_ground_floor_windows_for_loading_doors() -> void:
	_sim.free_build = true
	var warehouse := SimFixture.place(_sim, &"warehouse", Vector2i(20, 11), 0)
	var view := _view()
	var before := view.window_count()
	assert_int(before).is_greater(0)
	# nível 1: portas de carga em células alternadas do térreo da frente (Fase 23)
	assert_bool(_sim.execute(UpgradeBuildingCommand.new(warehouse)).ok()).is_true()
	assert_int(view.window_count()).is_less(before)
	assert_int(view.window_count()).is_equal(WindowLightsView.building_windows(_sim, _sim.world.building(warehouse)).size())
