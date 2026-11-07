extends GdUnitTestSuite
## Expedições (Fase 69): o navio parado da companhia sai do mapa pelo custo do destino e volta ao porto de onde saiu no
## fim do prazo; o sorteio pela semente e pelo número dá naufrágio (o navio se perde), mãos vazias ou a recompensa (uma
## peça do tipo do destino, guardada, ou moedas); as recusas; tudo no save (o antigo carrega sem expedição).


func _sim() -> Simulation:
	var sim := SimFixture.two_islands()
	sim.world.seed = 1840
	sim.world.money = 100000.0
	# a obra livre do fixture não cobraria a expedição nem bloquearia o destino pelo marco
	sim.free_build = false
	return sim


## Um navio comprado com a obra livre (o fixture não tem os materiais), que depois volta a cobrar.
func _ship(sim: Simulation) -> int:
	sim.free_build = true
	var ship_id := SimFixture.ship(sim)
	sim.free_build = false
	return ship_id


func _trip(sim: Simulation, def_id: StringName, number: int) -> ExpeditionsState.Trip:
	var trip := ExpeditionsState.Trip.new()
	trip.number = number
	trip.def_id = def_id
	trip.def = sim.data.expedition(def_id)
	trip.ship = Ship.new(999, sim.data.ships[0])
	return trip


func test_data_has_four_valid_destinations() -> void:
	var data := GameData.get_default()
	assert_array(data.validate()).is_empty()
	assert_int(data.expeditions.size()).is_equal(4)
	for def: ExpeditionDef in data.expeditions:
		assert_str(tr(def.title_key())).override_failure_message(def.title_key()).is_not_equal(def.title_key())
		assert_str(tr(def.description_key())).is_not_equal(def.description_key())


func test_the_ship_leaves_and_comes_back_home() -> void:
	var sim := _sim()
	var ship_id := _ship(sim)
	SimFixture.run(sim, 1.0)
	var home := sim.world.ship(ship_id).at
	var money := sim.world.money
	var def := sim.data.expedition(&"spice_islands")
	assert_bool(sim.execute(StartExpeditionCommand.new(ship_id, def.id)).ok()).is_true()
	assert_object(sim.world.ship(ship_id)).is_null()
	assert_float(sim.world.money).is_equal_approx(money - def.cost_money, 0.001)
	assert_object(sim.world.expeditions_state.trip_of(ship_id)).is_not_null()
	var returned: Array[int] = []
	EventBus.expedition_returned.connect(func(_id: StringName, outcome: int, _exhibit: StringName) -> void: returned.append(outcome))
	SimFixture.run(sim, def.duration_s + 2.0)
	assert_int(returned.size()).is_equal(1)
	assert_bool(sim.world.expeditions_state.trips.is_empty()).is_true()
	if returned[0] == ExpeditionSystem.Outcome.LOST:
		assert_object(sim.world.ship(ship_id)).is_null()
	else:
		var ship := sim.world.ship(ship_id)
		assert_object(ship).is_not_null()
		assert_int(ship.at).is_equal(home)
		assert_bool(ship.is_placed()).is_true()
		assert_int(ship.state).is_equal(Ship.State.IDLE)


func test_the_draw_gives_every_outcome_and_pays_the_reward() -> void:
	var sim := _sim()
	var seen: Dictionary[int, bool] = {}
	for number: int in 200:
		var money := sim.world.money
		var trip := _trip(sim, &"savanna_coast", number)
		var result := ExpeditionSystem.resolve(sim.world, sim.data, trip)
		var outcome: int = result[0]
		var exhibit: StringName = result[1]
		seen[outcome] = true
		if outcome == ExpeditionSystem.Outcome.REWARD:
			if exhibit != &"":
				# um animal ainda não comprado, guardado
				assert_int(sim.data.exhibit(exhibit).kind).is_equal(ExhibitDef.Kind.ANIMAL)
				assert_int(sim.world.exhibits_state.placed[exhibit]).is_equal(0)
			else:
				# sem animal sobrando: o dobro do custo
				assert_float(sim.world.money - money).is_equal_approx(trip.def.cost_money * 2.0, 0.001)
		else:
			assert_str(String(exhibit)).is_equal("")
	assert_int(seen.size()).is_equal(3)
	# a mesma semente e o mesmo número dão o mesmo resultado
	var a := ExpeditionSystem.resolve(_sim().world, sim.data, _trip(sim, &"spice_islands", 7))
	var b := ExpeditionSystem.resolve(_sim().world, sim.data, _trip(sim, &"spice_islands", 7))
	assert_array(a).is_equal(b)


func test_refusals() -> void:
	var sim := _sim()
	var ship_id := _ship(sim)
	SimFixture.run(sim, 1.0)
	# destino bloqueado pelo marco
	assert_str(String(sim.execute(StartExpeditionCommand.new(ship_id, &"northern_seas")).reason)).is_equal(String(StartExpeditionCommand.LOCKED))
	# sem dinheiro
	sim.world.money = 10.0
	assert_str(String(sim.execute(StartExpeditionCommand.new(ship_id, &"spice_islands")).reason)).is_equal(String(PlacementRules.NO_MONEY))
	sim.world.money = 100000.0
	# navegando não vai
	sim.execute(MoveShipCommand.new(ship_id, 1))
	SimFixture.run(sim, 0.4)
	assert_str(String(sim.execute(StartExpeditionCommand.new(ship_id, &"spice_islands")).reason)).is_equal(String(StartExpeditionCommand.NO_SHIP))
	assert_str(String(sim.execute(StartExpeditionCommand.new(12345, &"spice_islands")).reason)).is_equal(String(StartExpeditionCommand.NO_SHIP))


func test_expeditions_go_in_the_save() -> void:
	var sim := _sim()
	var ship_id := _ship(sim)
	SimFixture.run(sim, 1.0)
	assert_bool(sim.execute(StartExpeditionCommand.new(ship_id, &"ancient_ruins")).ok()).is_true()
	var saved := sim.world.to_dict()
	var loaded := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(loaded).is_not_null()
	assert_dict(loaded.expeditions_state.to_dict()).is_equal(sim.world.expeditions_state.to_dict())
	# as duas partidas voltam iguais
	var copy := Simulation.new(sim.config, sim.data, loaded)
	var outcomes: Array[String] = []
	var record := func(id: StringName, outcome: int, exhibit: StringName) -> void: outcomes.append("%s/%d/%s" % [id, outcome, exhibit])
	EventBus.expedition_returned.connect(record)
	SimFixture.run(sim, 500.0)
	SimFixture.run(copy, 500.0)
	EventBus.expedition_returned.disconnect(record)
	assert_int(outcomes.size()).is_equal(2)
	assert_str(outcomes[0]).is_equal(outcomes[1])
	# o save de antes da fase carrega sem expedição
	var old := saved.duplicate(true)
	old.erase("expeditions")
	var from_old := WorldState.from_dict(old, sim.data, sim.config)
	assert_object(from_old).is_not_null()
	assert_bool(from_old.expeditions_state.trips.is_empty()).is_true()
