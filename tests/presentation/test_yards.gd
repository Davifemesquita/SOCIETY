extends GdUnitTestSuite
## Quintal (Fase 15): varal atrás de parte das casas de camponeses e operários (nunca na casa da fogueira) e
## vasos dos dois lados da porta, na frente do corpo da casa.

const STREET := 10

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 30))
	SimFixture.road(_sim, Vector2i(2, STREET), Vector2i(70, STREET))


func _view() -> YardView:
	var view: YardView = auto_free(YardView.new())
	add_child(view)
	view.setup(_sim)
	return view


func test_some_houses_get_a_clothesline_but_never_the_bonfire_ones() -> void:
	var lines := 0
	for i: int in 12:
		var house := SimFixture.house(_sim, 4 + i * 4, STREET, &"peasants", 10.0)
		if house % YardView.CLOTHESLINE_EVERY == YardView.CLOTHESLINE_REST:
			lines += 1
		# a fogueira fica com as outras casas
		assert_bool(house % LampView.BONFIRE_EVERY == 0 and house % YardView.CLOTHESLINE_EVERY == YardView.CLOTHESLINE_REST).is_false()
	var view := _view()
	assert_int(lines).is_greater(0)
	assert_int(view.clothesline_count()).is_equal(lines)
	assert_int(view.cloth_count()).is_equal(lines * YardView.CLOTHES_PER_LINE)


func test_upper_classes_have_no_clothesline_or_pots() -> void:
	for i: int in 6:
		SimFixture.house(_sim, 4 + i * 4, STREET, &"engineers", 10.0)
	var view := _view()
	assert_int(view.clothesline_count()).is_equal(0)
	assert_int(view.pot_count()).is_equal(0)


func test_pots_stand_by_the_door_in_front_of_the_house_body() -> void:
	# casa de operários acima da rua (rotação 2, frente em +Z): os vasos ficam no lado da rua
	var house := SimFixture.house(_sim, 20, STREET, &"workers", 10.0)
	var record := _sim.world.building(house)
	var places := YardView.pot_places(_sim, record)
	assert_int(places.size()).is_equal(2)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var center := grid.rect_world(Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation))
	for place: Transform3D in places:
		assert_float(place.origin.z).is_greater(center.z)
		assert_float(absf(place.origin.x - center.x)).is_equal_approx(YardView.POT_SIDE_M, 0.001)
	# no quintal cercado dos camponeses o vaso recua uma fileira
	record.tier = &"peasants"
	var peasant := YardView.pot_places(_sim, record)
	assert_float(peasant[0].origin.z).is_equal_approx(places[0].origin.z - _sim.config.cell_size_m, 0.001)
