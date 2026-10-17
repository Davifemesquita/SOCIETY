extends GdUnitTestSuite
## Cesto e saco na mão (Fase 15): as peças têm a base no chão e cabem na mão, e a PedestrianView mostra o
## cesto só em quem sai do mercado carregando.

const STREET := 10


func test_the_basket_and_the_sack_stand_on_their_base() -> void:
	for mesh: ArrayMesh in [CarriedGoods.basket_mesh(), CarriedGoods.sack_mesh()]:
		var box := mesh.get_aabb()
		assert_float(box.position.y).is_equal_approx(0.0, 0.001)
		assert_float(box.size.x).is_less(0.5)
		assert_float(box.size.y).is_less(0.5)


func test_pedestrians_leaving_the_market_show_a_basket() -> void:
	var sim := SimFixture.simulation(Vector2i(80, 30))
	SimFixture.road(sim, Vector2i(2, STREET), Vector2i(70, STREET))
	for i: int in 6:
		SimFixture.house(sim, 4 + i * 3, STREET, &"peasants", 20.0)
	SimFixture.place(sim, &"market", Vector2i(26, STREET + 1), 0)
	SimFixture.place(sim, &"lumberjack", Vector2i(36, STREET + 1), 0)
	var view: PedestrianView = auto_free(PedestrianView.new())
	add_child(view)
	view.setup(sim, sim.config, 3)
	view.crowd.activity_override = 1.0
	var baskets := 0
	for second: int in 400:
		view.crowd.update(1.0, 12.0)
		view.apply()
		baskets = maxi(baskets, view.carried_count(Crowd.Load.BASKET))
	assert_int(baskets).is_greater(0)
	# ninguém sai de fazenda aqui: nenhum saco
	assert_int(view.carried_count(Crowd.Load.SACK)).is_equal(0)
