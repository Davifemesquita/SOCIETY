extends GdUnitTestSuite
## Boias no porto (Fase 144): diante do entreposto, boias em pares no mar, a vermelha à esquerda de quem chega e a verde à
## direita; elas boiam, afundadas e balançando; outros prédios não têm.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_the_buoys_mark_the_way_in_in_pairs() -> void:
	var id := SimFixture.port(_sim)
	var record := _sim.world.building(id)
	var def := _sim.def_of(record)
	var found := BuoyView.spots(_sim.world, record, def, _sim.config.cell_size_m)
	assert_int(found.size()).is_equal(BuoyView.BUOYS_PER_POST)
	var grid := _sim.world.island(0)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var out := HarborView.seaward(_sim.world, center, area, _sim.config.cell_size_m, record.rotation)
	var across := Vector3(-out.z, 0.0, out.x)
	var reds := 0
	for spot: Array in found:
		var at: Vector3 = spot[0]
		var red: bool = spot[1]
		assert_bool(HarborView.afloat(_sim.world, at)).is_true()
		# mar adentro, e a vermelha do lado +través (a esquerda de quem chega com a proa para a terra)
		assert_float((at - center).dot(out)).is_greater(0.0)
		assert_bool(red == ((at - center).dot(across) > 0.0)).is_true()
		if red:
			reds += 1
	assert_int(reds).is_equal(BuoyView.BUOYS_PER_POST / 2)


func test_a_buoy_floats_low_and_rocks() -> void:
	var at := Vector3(10.0, 0.0, -30.0)
	var heights: Array[float] = []
	var tilted := false
	for step: int in 40:
		var place := BuoyView.pose(at, 3, step * 0.3)
		heights.append(place.origin.y)
		assert_float(place.origin.y).is_less(0.0)
		if place.basis.y.normalized().dot(Vector3.UP) < 0.995:
			tilted = true
	assert_float(heights.max() - heights.min()).is_greater(0.05)
	assert_bool(tilted).is_true()


func test_only_trading_posts_have_buoys() -> void:
	SimFixture.place(_sim, &"lumberjack", Vector2i(40, 10))
	var view: BuoyView = auto_free(BuoyView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.buoy_count()).is_equal(0)
	SimFixture.port(_sim)
	view.rebuild()
	assert_int(view.buoy_count()).is_equal(BuoyView.BUOYS_PER_POST)
