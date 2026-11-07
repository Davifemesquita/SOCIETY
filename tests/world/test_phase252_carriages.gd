extends GdUnitTestSuite
## Carruagem à porta do teatro (Fase 252): o teatro com a estrada encostada na fachada de entrada ganha a carruagem na célula de
## estrada à frente dele, ao longo da rua; sem estrada ali, nada; outros prédios não têm; a carruagem é comprida e de pé.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_carriage_waits_on_the_road_in_front_of_the_theater() -> void:
	SimFixture.road(_sim, Vector2i(5, 10), Vector2i(50, 10))
	var id := SimFixture.place(_sim, &"theater", Vector2i(20, 11), 0)
	var record := _sim.world.building(id)
	var found: Variant = CarriageView.spot(_sim, record)
	assert_bool(found is Transform3D).is_true()
	var place: Transform3D = found
	var grid := _sim.world.island(0)
	var cell := grid.world_to_cell(place.origin)
	assert_bool(grid.has_road(cell)).is_true()
	assert_bool(cell in Footprint.front_cells(record.origin, _sim.def_of(record).size, record.rotation)).is_true()
	# ao longo da rua (a rua corre em x)
	assert_float(absf(place.basis.x.normalized().x)).is_greater(0.99)


func test_no_road_in_front_means_no_carriage() -> void:
	SimFixture.road(_sim, Vector2i(5, 30), Vector2i(50, 30))
	var id := SimFixture.place(_sim, &"theater", Vector2i(20, 11), 0)
	assert_object(CarriageView.spot(_sim, _sim.world.building(id))).is_null()


func test_other_buildings_have_none() -> void:
	SimFixture.road(_sim, Vector2i(5, 10), Vector2i(50, 10))
	var id := SimFixture.place(_sim, &"school", Vector2i(20, 11), 0)
	assert_object(CarriageView.spot(_sim, _sim.world.building(id))).is_null()


func test_the_carriage_is_long_and_standing() -> void:
	var box := CarriageView.carriage_mesh().get_aabb()
	assert_float(box.size.x).is_greater(box.size.z * 1.5)
	assert_float(box.end.y).is_between(1.3, 2.0)
	assert_float(box.position.y).is_greater(-0.05)
