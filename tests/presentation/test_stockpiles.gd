extends GdUnitTestSuite
## Pilhas de estoque (Fase 13): uma peça por tonelada pronta diante do prédio, na forma do bem,
## crescendo com a produção e sumindo quando a carroça leva.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> StockpileView:
	var view: StockpileView = auto_free(StockpileView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	return view


func test_every_good_has_a_pile_and_the_kit_draws_it() -> void:
	for good: GoodDef in _sim.data.goods:
		if good.pile == GoodDef.Pile.NONE:
			continue
		var mesh := CargoKit.mesh(good.pile)
		assert_object(mesh).override_failure_message(String(good.id)).is_not_null()
		var box := mesh.get_aabb()
		# cabe numa peça e fica em cima do chão
		assert_float(box.position.y).override_failure_message(String(good.id)).is_greater_equal(-0.01)
		assert_float(maxf(box.size.x, box.size.z)).override_failure_message(String(good.id)).is_less_equal(CargoKit.ITEM_M + 0.05)
	assert_int(_sim.data.good(&"beer").pile).is_equal(GoodDef.Pile.BARREL)
	assert_int(_sim.data.good(&"flour").pile).is_equal(GoodDef.Pile.SACK)
	assert_int(_sim.data.good(&"coal").pile).is_equal(GoodDef.Pile.HEAP)
	assert_int(_sim.data.good(&"wood").pile).is_equal(GoodDef.Pile.LOGS)
	assert_int(_sim.data.good(&"clocks").pile).is_equal(GoodDef.Pile.CRATE)


func test_the_pile_grows_with_the_output_and_shrinks_when_the_cart_takes_it() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(4, 11), 0)
	var house := SimFixture.house(_sim, 20, 10, &"peasants", 5.0)
	var view := _view()
	assert_int(view.item_count()).is_equal(0)
	_sim.world.building(bakery).output_buffer = 2.5
	view.refresh()
	assert_int(view.items_of(bakery)).is_equal(2)
	assert_int(view.item_count()).is_equal(2)
	_sim.world.building(bakery).output_buffer = 4.0
	view.refresh()
	assert_int(view.item_count()).is_equal(4)
	_sim.world.building(bakery).output_buffer = 0.0
	view.refresh()
	assert_int(view.item_count()).is_equal(0)
	# casa não tem pilha
	assert_int(view.items_of(house)).is_equal(0)


func test_the_pile_sits_in_front_of_the_building_away_from_the_door() -> void:
	for rotation: int in 4:
		var sim := SimFixture.simulation(Vector2i(80, 40))
		sim.free_build = true
		sim.ignore_terrain = true
		var origin := Vector2i(20, 20)
		var placed := sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND, &"brewery", origin, rotation))
		assert_bool(placed.ok()).is_true()
		var id: int = placed.placed[0]
		var view: StockpileView = auto_free(StockpileView.new())
		add_child(view)
		view.setup(sim, sim.config.cell_size_m)
		var def := sim.data.building(&"brewery")
		var area := Footprint.rect(origin, def.size, rotation)
		var center := GridSpace.rect_center(area, 2.0)
		var anchor := view.anchor_of(id).origin
		var front := Footprint.front_direction(rotation)
		var out := Vector2(anchor.x - center.x, anchor.z - center.z)
		var label := "rotação %d" % rotation
		# na frente, logo depois da parede
		var half := def.size.y * 1.0
		assert_float(out.dot(Vector2(front))).override_failure_message(label).is_between(half, half + 1.0)
		# longe da porta
		var door := GridSpace.cell_center(Footprint.entrance_cell(origin, def.size, rotation), 2.0)
		var pile_middle := view.anchor_of(id) * Vector3(CargoKit.ITEM_M, 0.0, 0.0)
		assert_float(Vector2(pile_middle.x - door.x, pile_middle.z - door.z).length()).override_failure_message(label).is_greater(1.5)


func test_demolishing_takes_the_pile_away() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(4, 11), 0)
	var view := _view()
	_sim.world.building(bakery).output_buffer = 3.0
	view.refresh()
	assert_int(view.item_count()).is_equal(3)
	_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(4, 11), Vector2i(1, 1))))
	assert_int(view.item_count()).is_equal(0)
