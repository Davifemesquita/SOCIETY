extends GdUnitTestSuite
## Especialistas (Fase 11): o comerciante traz uma oferta a cada volta, o jogador contrata (paga a
## contratação e o salário por minuto) e põe cada um num prédio de produção do grupo dele, um por
## prédio. Velocidade, corte de manutenção e tonelada extra; demolir devolve o especialista à lista.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	SimFixture.house(_sim, 60, 20, &"workers", 400.0)
	SimFixture.house(_sim, 70, 20, &"engineers", 200.0)


## Contrata pela oferta (posta à mão) e devolve o id.
func _hire(def_id: StringName) -> int:
	_sim.world.specialists_state.offers.append(def_id)
	var result := _sim.execute(SpecialistCommand.hire(def_id))
	assert_bool(result.ok()).is_true()
	return result.created_id


func _factory() -> int:
	SimFixture.give(_sim, &"steel", 20.0)
	return SimFixture.place(_sim, &"steel_beam_works", Vector2i(20, 21))


func test_definitions_are_valid_and_groups_cover_the_right_buildings() -> void:
	var data := GameData.get_default()
	assert_array(data.validate()).is_empty()
	assert_array(GameConfig.new().validate()).is_empty()
	assert_int(data.specialists.size()).is_greater_equal(6)
	assert_bool(data.specialist(&"agronomist").covers(data.building(&"wheat_farm"))).is_true()
	assert_bool(data.specialist(&"agronomist").covers(data.building(&"iron_mine"))).is_false()
	assert_bool(data.specialist(&"mining_engineer").covers(data.building(&"iron_mine"))).is_true()
	assert_bool(data.specialist(&"foreman").covers(data.building(&"steel_beam_works"))).is_true()
	assert_bool(data.specialist(&"foreman").covers(data.building(&"lumberjack"))).is_false()
	assert_bool(data.specialist(&"master_brewer").covers(data.building(&"brewery"))).is_true()
	assert_bool(data.specialist(&"master_brewer").covers(data.building(&"bakery"))).is_false()
	# a usina, as casas e os serviços não recebem ninguém
	for def_id: StringName in [&"power_station", &"house", &"market", &"warehouse"]:
		assert_bool(data.specialist(&"bookkeeper").covers(data.building(def_id))).is_false()


func test_offer_is_seeded_by_the_tour_and_respects_milestones() -> void:
	var data := GameData.get_default()
	var config := GameConfig.new()
	var first := SpecialistSystem.roll_offers(1840, 3, 6, data, config)
	assert_array(first).is_equal(SpecialistSystem.roll_offers(1840, 3, 6, data, config))
	assert_int(first.size()).is_equal(config.specialist_offers)
	# sem repetir na mesma oferta
	var seen: Dictionary[StringName, bool] = {}
	for def_id: StringName in first:
		assert_bool(seen.has(def_id)).is_false()
		seen[def_id] = true
	# voltas diferentes trazem ofertas diferentes em algum momento
	var differs := false
	for tour: int in range(4, 12):
		differs = differs or SpecialistSystem.roll_offers(1840, tour, 6, data, config) != first
	assert_bool(differs).is_true()
	# sem marco, só os liberados desde o começo
	for tour: int in 20:
		for def_id: StringName in SpecialistSystem.roll_offers(7, tour, 0, data, config):
			assert_int(data.specialist(def_id).after_milestone).is_equal(0)


func test_the_trader_brings_a_new_offer_each_tour() -> void:
	var state := _sim.world.specialists_state
	SpecialistSystem.run(_sim.world, _sim.data, _sim.config)
	assert_array(state.offers).is_empty()
	# com o navio do comerciante no mar, a oferta da volta chega
	_sim.world.trader.ship_id = 99
	_sim.world.trader.tour = 1
	_sim.world.milestones_reached = 6
	SpecialistSystem.run(_sim.world, _sim.data, _sim.config)
	assert_int(state.offer_tour).is_equal(1)
	assert_int(state.offers.size()).is_equal(_sim.config.specialist_offers)
	# contratar tira da oferta; a mesma volta não repõe
	var taken := state.offers[0]
	assert_bool(_sim.execute(SpecialistCommand.hire(taken)).ok()).is_true()
	SpecialistSystem.run(_sim.world, _sim.data, _sim.config)
	assert_bool(state.offers.has(taken)).is_false()
	assert_int(state.offers.size()).is_equal(_sim.config.specialist_offers - 1)
	_sim.world.trader.tour = 2
	SpecialistSystem.run(_sim.world, _sim.data, _sim.config)
	assert_int(state.offers.size()).is_equal(_sim.config.specialist_offers)


func test_hiring_costs_money_and_has_a_limit() -> void:
	_sim.free_build = false
	var state := _sim.world.specialists_state
	assert_str(_sim.execute(SpecialistCommand.hire(&"foreman")).reason).is_equal(SpecialistCommand.NO_OFFER)
	var money := _sim.world.money
	state.offers.append(&"foreman")
	var result := _sim.execute(SpecialistCommand.hire(&"foreman"))
	assert_bool(result.ok()).is_true()
	assert_float(_sim.world.money).is_equal(money - _sim.data.specialist(&"foreman").hire_cost)
	assert_array(state.offers).is_empty()
	assert_int(state.specialist(result.created_id).building_id).is_equal(0)
	# sem dinheiro
	_sim.world.money = _sim.config.min_balance_for(_sim.world.difficulty)
	state.offers.append(&"foreman")
	assert_str(_sim.execute(SpecialistCommand.hire(&"foreman")).reason).is_equal(PlacementRules.NO_MONEY)
	# teto de contratados
	_sim.world.money = 1_000_000.0
	_sim.config.max_specialists = 1
	assert_str(_sim.execute(SpecialistCommand.hire(&"foreman")).reason).is_equal(SpecialistCommand.LIMIT)


func test_salary_counts_in_the_upkeep_hired_or_assigned() -> void:
	var before := _sim.derived_state().upkeep_per_min
	_hire(&"foreman")
	assert_float(_sim.derived_state().upkeep_per_min).is_equal_approx(before + _sim.data.specialist(&"foreman").salary_per_min, 0.001)


func test_assign_checks_the_group_and_one_per_building() -> void:
	var factory := _factory()
	var farm := SimFixture.place(_sim, &"lumberjack", Vector2i(40, 21))
	var foreman := _hire(&"foreman")
	var other := _hire(&"foreman")
	assert_str(_sim.execute(SpecialistCommand.assign(foreman, farm)).reason).is_equal(SpecialistCommand.WRONG_BUILDING)
	assert_str(_sim.execute(SpecialistCommand.assign(foreman, 9999)).reason).is_equal(SpecialistCommand.WRONG_BUILDING)
	assert_bool(_sim.execute(SpecialistCommand.assign(foreman, factory)).ok()).is_true()
	assert_str(_sim.execute(SpecialistCommand.assign(other, factory)).reason).is_equal(SpecialistCommand.SLOT_TAKEN)
	assert_object(_sim.world.specialists_state.at(factory)).is_same(_sim.world.specialists_state.specialist(foreman))
	assert_object(_sim.derived_state().entry_of(factory).specialist).is_same(_sim.world.specialists_state.specialist(foreman))
	# retirar e dispensar
	assert_bool(_sim.execute(SpecialistCommand.unassign(foreman)).ok()).is_true()
	assert_object(_sim.derived_state().entry_of(factory).specialist).is_null()
	assert_str(_sim.execute(SpecialistCommand.unassign(foreman)).reason).is_equal(SpecialistCommand.NO_SPECIALIST)
	assert_bool(_sim.execute(SpecialistCommand.dismiss(foreman)).ok()).is_true()
	assert_object(_sim.world.specialists_state.specialist(foreman)).is_null()


func test_speed_specialist_makes_the_factory_faster() -> void:
	var factory := _factory()
	assert_bool(_sim.execute(SpecialistCommand.assign(_hire(&"foreman"), factory)).ok()).is_true()
	# ciclo de 45 s a 130%: a segunda viga sai aos ~69 s (sem especialista, aos 90)
	SimFixture.run_production(_sim, 70.0)
	assert_float(SimFixture.stock(_sim, &"steel_beams")).is_equal(2.0)
	assert_float(_sim.world.building(factory).productivity).is_greater(1.0)


func test_factory_without_specialist_keeps_its_speed() -> void:
	_factory()
	SimFixture.run_production(_sim, 70.0)
	assert_float(SimFixture.stock(_sim, &"steel_beams")).is_equal(1.0)


func test_extra_output_specialist_adds_a_ton_every_few_cycles() -> void:
	var factory := _factory()
	var master := _hire(&"steelmaster")
	assert_bool(_sim.execute(SpecialistCommand.assign(master, factory)).ok()).is_true()
	var every := _sim.data.specialist(&"steelmaster").cycles_per_extra()
	SimFixture.run_production(_sim, 45.0 * every + 1.0)
	assert_float(SimFixture.stock(_sim, &"steel_beams")).is_equal(float(every + 1))
	assert_int(_sim.world.specialists_state.specialist(master).cycles).is_equal(0)


func test_upkeep_specialist_cuts_the_building_upkeep() -> void:
	var factory := _factory()
	var bookkeeper := _hire(&"bookkeeper")
	var hired := _sim.derived_state().upkeep_per_min
	assert_bool(_sim.execute(SpecialistCommand.assign(bookkeeper, factory)).ok()).is_true()
	var cut := _sim.data.building(&"steel_beam_works").upkeep_per_min * _sim.data.specialist(&"bookkeeper").amount
	assert_float(_sim.derived_state().upkeep_per_min).is_equal_approx(hired - cut, 0.001)


func test_demolishing_the_building_frees_the_specialist() -> void:
	var factory := _factory()
	var foreman := _hire(&"foreman")
	_sim.execute(SpecialistCommand.assign(foreman, factory))
	var record := _sim.world.building(factory)
	assert_bool(_sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(record.origin, Vector2i.ONE))).ok()).is_true()
	assert_int(_sim.world.specialists_state.specialist(foreman).building_id).is_equal(0)
	assert_int(_sim.world.specialists_state.unassigned_count()).is_equal(1)


func test_save_keeps_specialists_posts_cycles_and_offer() -> void:
	var factory := _factory()
	var master := _hire(&"steelmaster")
	_sim.execute(SpecialistCommand.assign(master, factory))
	_hire(&"agronomist")
	var state := _sim.world.specialists_state
	state.specialist(master).cycles = 2
	state.offer_tour = 5
	state.offers.assign([&"foreman", &"forester"])
	var loaded := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)
	assert_object(loaded).is_not_null()
	var copy := loaded.specialists_state
	assert_int(copy.specialists.size()).is_equal(2)
	assert_int(copy.at(factory).id).is_equal(master)
	assert_int(copy.at(factory).cycles).is_equal(2)
	assert_int(copy.next_id).is_equal(state.next_id)
	assert_int(copy.offer_tour).is_equal(5)
	assert_array(copy.offers).is_equal(state.offers)


func test_save_with_specialist_in_the_wrong_building_is_refused() -> void:
	var farm := SimFixture.place(_sim, &"lumberjack", Vector2i(40, 21))
	var foreman := _hire(&"foreman")
	_sim.world.specialists_state.specialist(foreman).building_id = farm
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()
	_sim.world.specialists_state.specialist(foreman).building_id = 9999
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()


func test_old_saves_start_without_specialists() -> void:
	var migrated := SaveMigrations.from_11_to_12({"world": {}})
	var world: Dictionary = migrated["world"]
	var saved: Dictionary = world["specialists"]
	var loaded := SpecialistsState.from_dict(saved, GameData.get_default())
	assert_object(loaded).is_not_null()
	assert_array(loaded.specialists).is_empty()
	assert_int(loaded.offer_tour).is_equal(-1)
	assert_int(SaveMigrations.all().size()).is_equal(SaveSystem.SAVE_VERSION - 1)
