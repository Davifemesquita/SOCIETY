extends GdUnitTestSuite
## Galo do cata-vento (Fase 182): só nas fazendas de FARMS, no alto da cumeeira, dentro da planta; nenhum em casa nem em fábrica;
## o galo vira a cabeça para o lado de onde vem o vento, devagar; a haste e o galo têm o tamanho certo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))


func _view() -> WeathercockView:
	var view: WeathercockView = auto_free(WeathercockView.new())
	add_child(view)
	view.setup(_sim)
	return view


func test_only_farms_get_a_weathercock_on_the_ridge() -> void:
	var wheat := SimFixture.place(_sim, &"wheat_farm", Vector2i(10, 21), 0)
	var sheep := SimFixture.place(_sim, &"sheep_farm", Vector2i(30, 21), 0)
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(50, 21), 0)
	var house := SimFixture.house(_sim, 60, 20, &"workers", 5.0)
	var view := _view()
	assert_int(view.cock_count()).is_equal(2)
	assert_object(WeathercockView.spot(_sim, _sim.world.building(lumberjack))).is_null()
	assert_object(WeathercockView.spot(_sim, _sim.world.building(house))).is_null()
	for id: int in [wheat, sheep]:
		var record := _sim.world.building(id)
		var top: Vector3 = WeathercockView.spot(_sim, record)
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		var grid := _sim.world.island(record.island_id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var model := BuildingView.model_place(grid, record, area)
		# na altura da cumeeira, acima das paredes, e dentro da planta do prédio
		assert_float(top.y - model.origin.y).is_equal_approx(spec.hall().height_m + spec.hall().roof_m, 0.01)
		var middle := grid.rect_world(area)
		assert_float(absf(top.x - middle.x)).is_less(area.size.x * grid.cell_size * 0.5)
		assert_float(absf(top.z - middle.z)).is_less(area.size.y * grid.cell_size * 0.5)


func test_the_cock_turns_its_head_into_the_wind_slowly() -> void:
	SimFixture.place(_sim, &"wheat_farm", Vector2i(10, 21), 0)
	var view := _view()
	var wind := Vector2(0.0, 1.0)
	view.turn(wind, 0.5, 0.1)
	# um instante não basta para virar tudo
	assert_float(absf(angle_difference(view.heading, WindFlag.yaw_of(wind)))).is_greater(0.1)
	for step: int in 40:
		view.turn(wind, 0.5, 1.0)
	assert_float(absf(angle_difference(view.heading, WindFlag.yaw_of(wind)))).is_less(0.01)
	# o rabo (+x do galo) vai a favor do vento, a cabeça (−x) para o lado de onde ele vem
	var tail := Basis(Vector3.UP, view.heading) * Vector3.RIGHT
	assert_float(Vector2(tail.x, tail.z).dot(wind)).is_greater(0.99)


func test_mast_and_cock_sizes() -> void:
	var mast := WeathercockView.mast_mesh().get_aabb()
	assert_float(mast.end.y).is_equal_approx(WeathercockView.MAST_M, 0.01)
	var cock := WeathercockView.cock_mesh().get_aabb()
	assert_float(cock.size.x).is_between(0.6, 1.0)
	assert_float(cock.end.y).is_less(WeathercockView.MAST_M + 0.4)
	assert_float(cock.size.z).is_less(0.05)
