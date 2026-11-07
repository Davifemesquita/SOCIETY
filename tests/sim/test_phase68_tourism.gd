extends GdUnitTestSuite
## Turismo (Fase 68): a ilha com entreposto e casas tem atratividade (a beleza que espalha menos a poluição); com os
## eventos ligados, os turistas pagam por ela a cada minuto (mais na festa), somando no dinheiro, na receita e numa
## parcela própria do detalhamento; sem os eventos (testes, robô), nada.

const STREET := 6


func _sim(events: bool = true) -> Simulation:
	var sim := SimFixture.simulation()
	sim.free_build = true
	SimFixture.port(sim)
	SimFixture.house_on_main_road(sim, 30, &"peasants", 5.0)
	sim.world.events_state.enabled = events
	# o jornal fora do caminho (a manchete mexe na felicidade, não no turismo)
	sim.world.events_state.next_edition_tick = 999_999_999
	return sim


func _decorate(sim: Simulation) -> void:
	SimFixture.place(sim, &"fountain_square", Vector2i(40, STREET + 1), 0)
	SimFixture.place(sim, &"statue", Vector2i(50, STREET + 1), 0)


func test_attractiveness_is_beauty_minus_pollution() -> void:
	var sim := _sim()
	assert_float(sim.derived_state().attractiveness.get(SimFixture.ISLAND, -1.0)).is_equal(0.0)
	_decorate(sim)
	var derived := sim.derived_state()
	var expected := 0.0
	for building_id: int in sim.world.building_ids():
		var def := sim.def_of(sim.world.building(building_id))
		if def.beauty > 0.0 and def.beauty_radius_cells > 0:
			expected += DerivedState.beauty_strength(sim.world, sim.data, building_id) * sim.config.attractiveness_per_beauty
	assert_float(expected).is_greater(0.0)
	assert_float(derived.attractiveness[SimFixture.ISLAND]).is_equal_approx(expected, 0.001)
	# uma fábrica poluente desconta
	SimFixture.place(sim, &"furnace", Vector2i(80, STREET + 1), 0)
	assert_float(sim.derived_state().attractiveness[SimFixture.ISLAND]).is_less(expected)


func test_no_trading_post_no_tourists() -> void:
	var sim := SimFixture.simulation()
	sim.free_build = true
	SimFixture.road(sim, Vector2i(0, STREET), Vector2i(119, STREET))
	SimFixture.house_on_main_road(sim, 30, &"peasants", 5.0)
	_decorate(sim)
	assert_bool(sim.derived_state().attractiveness.has(SimFixture.ISLAND)).is_false()


func test_tourists_pay_with_events_on_and_more_in_a_festival() -> void:
	var sim := _sim()
	_decorate(sim)
	SimFixture.run(sim, 1.0)
	var derived := sim.derived_state()
	var expected: float = derived.attractiveness[SimFixture.ISLAND] * sim.config.tourism_coins_per_point
	assert_float(sim.world.tourism_per_min).is_equal_approx(expected, 0.001)
	assert_float(sim.world.income_per_min).is_greater_equal(sim.world.tourism_per_min)
	# a festa na ilha
	var event := WorldEvent.new()
	event.def = sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = SimFixture.ISLAND
	event.ends_tick = sim.world.tick + 100000
	sim.world.events_state.events.append(event)
	SimFixture.run(sim, 0.2)
	assert_float(sim.world.tourism_per_min).is_equal_approx(expected * (1.0 + sim.config.tourism_festival_bonus), 0.001)
	# o detalhamento do dinheiro tem a parcela dos turistas e continua fechando
	var sources := Breakdown.money(sim.world, sim.data, sim.config, sim.derived_state())
	var tourism := sources.filter(func(source: Breakdown.Source) -> bool: return source.kind == Breakdown.Kind.TOURISM)
	assert_int(tourism.size()).is_equal(1)
	assert_float(Breakdown.total(sources)).is_equal_approx(sim.world.income_per_min - sim.world.upkeep_per_min, 0.001)


func test_tourists_pay_into_the_money() -> void:
	var sim := _sim()
	_decorate(sim)
	SimFixture.run(sim, 1.0)
	# um tick a mais: o dinheiro muda pela receita (imposto + turistas) menos a manutenção, do mesmo tick
	var before := sim.world.money
	sim.run_ticks(1)
	var dt := sim.config.tick_interval()
	assert_float(sim.world.money - before).is_equal_approx(
			(sim.world.income_per_min - sim.world.upkeep_per_min) * dt / 60.0, 0.0001)
	assert_float(sim.world.tourism_per_min).is_greater(0.0)


func test_no_tourism_with_events_off() -> void:
	var sim := _sim(false)
	_decorate(sim)
	SimFixture.run(sim, 5.0)
	assert_float(sim.world.tourism_per_min).is_equal(0.0)
	assert_float(sim.derived_state().attractiveness[SimFixture.ISLAND]).is_greater(0.0)
