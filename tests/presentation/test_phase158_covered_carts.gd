extends GdUnitTestSuite
## Carroça de lona (Fase 158): só a carroça do prédio de bem em saco ou caixote, uma a cada COVER_EVERY pelo id; a lona fica
## sobre a caçamba do modelo, sem passar dos lados; na rua, a carroça coberta leva a lona e esconde a carga, e a de toras
## segue com a carga à mostra.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(140, 40), 50, true)
	SimFixture.port(_sim)


func test_only_sacks_and_crates_and_every_other_building() -> void:
	var covered := 0
	for home_id: int in range(1, 101):
		if CartView.covers(GoodDef.Pile.SACK, home_id):
			covered += 1
		assert_bool(CartView.covers(GoodDef.Pile.SACK, home_id)).is_equal(CartView.covers(GoodDef.Pile.CRATE, home_id))
		for pile: int in [GoodDef.Pile.LOGS, GoodDef.Pile.BARREL, GoodDef.Pile.HEAP, GoodDef.Pile.NONE]:
			assert_bool(CartView.covers(pile, home_id)).is_false()
	assert_int(covered).is_equal(100 / CartView.COVER_EVERY)


func test_the_canvas_sits_on_the_bed_of_the_cart() -> void:
	var canvas := CartView.canvas_mesh().get_aabb()
	var cart := CartView.model_mesh().get_aabb()
	# nos lados da caçamba (os arcos saltam um pouco da lona), dentro do comprimento do modelo
	assert_float(maxf(absf(canvas.position.x), absf(canvas.end.x))).is_less(CartView.CANVAS_RADIUS_M + 0.05)
	assert_float(canvas.position.z).is_greater_equal(cart.position.z)
	assert_float(canvas.end.z).is_less_equal(cart.end.z)
	# a lona nasce na borda da caçamba e sobe acima da carga
	assert_float(canvas.position.y).is_equal_approx(CartView.CANVAS_FOOT_M, 0.01)
	assert_float(canvas.end.y).is_greater(CartView.BED_M - CartView.HEIGHT_M + CargoKit.ITEM_M * CartView.CARGO_SCALE)


func test_the_covered_cart_carries_the_canvas_and_hides_the_load() -> void:
	var mills: Array[int] = [SimFixture.place(_sim, &"mill", Vector2i(30, 7)), SimFixture.place(_sim, &"mill", Vector2i(36, 7))]
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(44, 7))
	SimFixture.place(_sim, &"warehouse", Vector2i(70, 7))
	for building_id: int in mills + [lumberjack]:
		_sim.world.building(building_id).output_buffer = 2.0
	SimFixture.run(_sim, 3.0)
	for building_id: int in mills + [lumberjack]:
		assert_bool(_sim.world.cart(building_id).is_away()).override_failure_message("carroça %d" % building_id).is_true()
	var view: CartView = auto_free(CartView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	view._process(0.0)
	assert_int(view.visible_carts()).is_equal(3)
	# uma das duas moendas (ids seguidos) anda de lona; a farinha dela não aparece
	assert_int(view.visible_covers()).is_equal(1)
	assert_int(view.cargo_items(GoodDef.Pile.SACK)).is_equal(mini(ceili(_sim.world.cart(_uncovered(mills)).tons() - 0.000001), 2))
	# as toras do lenhador seguem à mostra
	assert_int(view.cargo_items(GoodDef.Pile.LOGS)).is_greater(0)


func _uncovered(mills: Array[int]) -> int:
	for mill: int in mills:
		if not CartView.covers(GoodDef.Pile.SACK, mill):
			return mill
	return 0
