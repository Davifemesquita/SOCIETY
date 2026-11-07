extends GdUnitTestSuite
## Bandeirolas da feira (Fase 133): o mercado ganha quatro postes nos cantos do pátio, dentro do lote e do lado da frente;
## outros prédios não têm; a vista desenha uma malha com os mercados.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_the_market_court_gets_four_posts_in_front() -> void:
	for rotation: int in 4:
		var sim := SimFixture.simulation()
		sim.free_build = true
		var id := SimFixture.place(sim, &"market", Vector2i(20, 10), rotation)
		var record := sim.world.building(id)
		var def := sim.def_of(record)
		var grid := sim.world.island(0)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var lot := Rect2(Vector2(area.position) * grid.cell_size + grid.origin_m, Vector2(area.size) * grid.cell_size)
		var tops := MarketBuntingView.posts(sim, record)
		assert_int(tops.size()).is_equal(4)
		var center := lot.get_center()
		var front := Vector2(Footprint.front_direction(record.rotation))
		for top: Vector3 in tops:
			assert_bool(lot.has_point(Vector2(top.x, top.z))).is_true()
			# no pátio: a metade da frente do lote
			assert_float((Vector2(top.x, top.z) - center).dot(front)).is_greater_equal(-0.01)


func test_other_buildings_have_no_bunting() -> void:
	var id := SimFixture.place(_sim, &"bakery", Vector2i(20, 10))
	assert_int(MarketBuntingView.posts(_sim, _sim.world.building(id)).size()).is_equal(0)


func test_the_view_counts_the_markets() -> void:
	SimFixture.place(_sim, &"market", Vector2i(20, 10))
	SimFixture.place(_sim, &"market", Vector2i(40, 10))
	var view: MarketBuntingView = auto_free(MarketBuntingView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.market_count()).is_equal(2)
