extends GdUnitTestSuite
## Fumaça das chaminés das casas (Fase 100): a boca da chaminé sai da mesma conta que a desenha; só casa com chaminé
## entra, só a com morador fumega; mais fumaça de manhã e à noite; a vista acompanha obra e demolição.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true
	SimFixture.road(_sim, Vector2i(2, 10), Vector2i(70, 10))


func _view() -> ChimneySmokeView:
	var view: ChimneySmokeView = auto_free(ChimneySmokeView.new())
	add_child(view)
	view.setup(_sim)
	return view


## Uma casa com chaminé (o sorteio do telhado decide; procura pelo id).
func _house_with_chimney(residents: float, from_x := 4) -> int:
	for x: int in range(from_x, from_x + 27, 3):
		var id := SimFixture.house(_sim, x, 10, &"workers", residents)
		var spec := BuildingKit.spec_for(_sim, _sim.world.building(id), 2.0)
		if spec.chimney:
			return id
		_sim.execute(DemolishCommand.new(0, Rect2i(_sim.world.building(id).origin, Vector2i(1, 1))))
	return -1


func test_the_chimney_top_sits_on_the_chimney_above_the_roof() -> void:
	var id := _house_with_chimney(10.0)
	assert_int(id).is_greater(0)
	var spec := BuildingKit.spec_for(_sim, _sim.world.building(id), 2.0)
	var top: Vector3 = BuildingKit.chimney_top(spec)
	# acima do beiral, dentro da planta da casa
	assert_float(top.y).is_greater(spec.height_m)
	assert_float(absf(top.x)).is_less(spec.size_m().x * 0.5)
	assert_float(absf(top.z)).is_less(spec.size_m().y * 0.5)
	# casa sem chaminé não tem boca
	spec.chimney = false
	assert_object(BuildingKit.chimney_top(spec)).is_null()


func test_only_houses_with_a_chimney_and_people_smoke() -> void:
	var lit := _house_with_chimney(10.0)
	var empty := _house_with_chimney(0.0, 34)
	SimFixture.place(_sim, &"lumberjack", Vector2i(66, 11), 0)
	var view := _view()
	assert_int(view.chimney_count()).is_equal(2)
	assert_int(view.lit_count()).is_equal(1)
	assert_object(view.top_of(lit)).is_not_null()
	assert_object(view.top_of(empty)).is_not_null()
	# a boca no mundo fica acima da casa
	var top: Vector3 = view.top_of(lit)
	assert_float(top.y).is_greater(_sim.data.tier(&"workers").house_height_m)


func test_the_view_follows_building_and_demolishing() -> void:
	var view := _view()
	var id := _house_with_chimney(10.0)
	view._process(0.0)
	assert_int(view.chimney_count()).is_equal(1)
	_sim.execute(DemolishCommand.new(0, Rect2i(_sim.world.building(id).origin, Vector2i(1, 1))))
	view._process(0.0)
	assert_int(view.chimney_count()).is_equal(0)


func test_more_smoke_in_the_morning_and_evening() -> void:
	var noon := ChimneySmokeView.amount_at(13.0)
	assert_float(noon).is_equal_approx(ChimneySmokeView.BASE_AMOUNT, 0.001)
	assert_float(ChimneySmokeView.amount_at(ChimneySmokeView.MORNING_HOUR)).is_equal_approx(1.0, 0.001)
	assert_float(ChimneySmokeView.amount_at(ChimneySmokeView.EVENING_HOUR)).is_equal_approx(1.0, 0.001)
	# liso: sem degrau na volta da meia-noite nem entre horas vizinhas
	for step: int in 240:
		var hour := step * 0.1
		assert_float(absf(ChimneySmokeView.amount_at(hour + 0.1) - ChimneySmokeView.amount_at(hour))).is_less(0.08)
	assert_float(ChimneySmokeView.amount_at(0.0)).is_equal_approx(ChimneySmokeView.amount_at(24.0), 0.0001)
