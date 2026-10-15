extends GdUnitTestSuite
## Eventos e encomendas (Fase 11): desligados por padrão; ligados, saem da semente na mesma ordem e
## na mesma hora, valem pelo tempo deles e só mexem nos multiplicadores (produção, preço, navios,
## felicidade, chegada). A encomenda é oferecida, aceita ou recusada, entregue vendendo no posto do
## comerciante e paga o prêmio no prazo; vencida, some sem multa. Tudo vai no save.


## Duas ilhas com entreposto e os tempos encurtados (eventos a cada ~20 s, encomendas a cada 30 s).
func _fast_sim(enabled: bool = true) -> Simulation:
	var sim := SimFixture.two_islands()
	sim.world.seed = 1840
	sim.config.event_first_after_s = 10.0
	sim.config.event_interval_s = 20.0
	sim.config.event_jitter_s = 5.0
	sim.config.mission_first_after_s = 5.0
	sim.config.mission_interval_s = 30.0
	sim.config.mission_offer_s = 60.0
	sim.config.max_active_events = 4
	sim.world.events_state.enabled = enabled
	return sim


## Evento posto à mão (sem sorteio), valendo por seconds.
func _inject(sim: Simulation, effect: EventDef.Effect, amount: float, island_id: int = -1, seconds: float = 60.0,
		group: EventDef.Group = EventDef.Group.ALL, good: StringName = &"") -> WorldEvent:
	var def := EventDef.new()
	def.id = &"test_event"
	def.effect = effect
	def.amount = amount
	def.target_group = group
	def.duration_s = seconds
	var event := WorldEvent.new()
	event.def = def
	event.def_id = def.id
	event.island_id = island_id
	event.good = good
	event.started_tick = sim.world.tick
	event.ends_tick = sim.world.tick + sim.config.ticks_of(seconds)
	sim.world.events_state.events.append(event)
	return event


func _history(sim: Simulation, seconds: float) -> Array[String]:
	var seen: Array[String] = []
	var record := func(def_id: StringName, island_id: int) -> void:
		seen.append("%s@%d:%d" % [def_id, island_id, sim.world.tick])
	EventBus.world_event_started.connect(record)
	SimFixture.run(sim, seconds)
	EventBus.world_event_started.disconnect(record)
	return seen


func test_data_has_events_and_missions_and_is_valid() -> void:
	var data := GameData.get_default()
	assert_array(data.validate()).is_empty()
	assert_int(data.events.size()).is_greater_equal(6)
	assert_int(data.missions.size()).is_greater_equal(8)
	assert_array(GameConfig.get_default().validate()).is_empty()
	# há encomenda e evento logo no começo (nenhum marco)
	assert_bool(data.missions.any(func(def: MissionDef) -> bool: return def.after_milestone == 0)).is_true()
	assert_bool(data.events.any(func(def: EventDef) -> bool: return def.after_milestone == 0)).is_true()


func test_disabled_world_never_gets_events_or_missions() -> void:
	var sim := _fast_sim(false)
	SimFixture.run(sim, 120.0)
	assert_int(sim.world.events_state.events.size()).is_equal(0)
	assert_int(sim.world.events_state.missions.size()).is_equal(0)
	assert_int(sim.world.events_state.event_count).is_equal(0)


func test_new_simulation_worlds_start_disabled() -> void:
	assert_bool(SimFixture.simulation().world.events_state.enabled).is_false()
	var config := GameConfig.get_default()
	assert_bool(ArchipelagoGenerator.new_world(7, config, GameData.get_default()).events_state.enabled).is_false()


func test_events_follow_the_seed_and_respect_the_limit() -> void:
	var first := _history(_fast_sim(), 200.0)
	var second := _history(_fast_sim(), 200.0)
	assert_int(first.size()).is_greater_equal(4)
	assert_array(second).is_equal(first)
	var other := _fast_sim()
	other.world.seed = 99
	assert_array(_history(other, 200.0)).is_not_equal(first)


func test_events_respect_the_concurrent_limit_and_end_on_time() -> void:
	var sim := _fast_sim()
	sim.config.event_interval_s = 6.0
	sim.config.event_jitter_s = 1.0
	var ended: Array[StringName] = []
	EventBus.world_event_ended.connect(func(def_id: StringName, _island: int) -> void: ended.append(def_id))
	# 500 s: os eventos do começo duram de 360 a 600 s
	for step: int in 100:
		SimFixture.run(sim, 5.0)
		assert_int(sim.world.events_state.events.size()).is_less_equal(sim.config.max_active_events)
		var ids: Dictionary[StringName, bool] = {}
		for event: WorldEvent in sim.world.events_state.events:
			assert_bool(ids.has(event.def_id)).is_false()
			ids[event.def_id] = true
			assert_int(event.ends_tick).is_greater(sim.world.tick - sim.config.events_check_ticks)
			if event.def.is_local():
				assert_array(sim.world.colonized_islands(sim.data)).contains([event.island_id])
	assert_int(ended.size()).is_greater(0)


func test_locked_events_wait_for_their_milestone() -> void:
	var sim := _fast_sim()
	sim.config.event_interval_s = 6.0
	sim.config.event_jitter_s = 1.0
	var seen: Dictionary[StringName, bool] = {}
	EventBus.world_event_started.connect(func(def_id: StringName, _island: int) -> void: seen[def_id] = true)
	SimFixture.run(sim, 400.0)
	for def_id: StringName in seen:
		assert_int(sim.data.event(def_id).after_milestone).is_equal(0)


func test_production_event_speeds_only_its_group_on_its_island() -> void:
	var sim := _fast_sim()
	var event := _inject(sim, EventDef.Effect.PRODUCTION, 1.25, 0, 60.0, EventDef.Group.FARMS)
	var state := sim.world.events_state
	var farm := sim.data.building(&"potato_farm")
	var mine := sim.data.building(&"coal_mine")
	assert_float(EventEffects.production(state, 0, farm)).is_equal_approx(1.25, 0.0001)
	assert_float(EventEffects.production(state, 1, farm)).is_equal(1.0)
	assert_float(EventEffects.production(state, 0, mine)).is_equal(1.0)
	event.def.target_group = EventDef.Group.MINES
	assert_float(EventEffects.production(state, 0, mine)).is_equal_approx(1.25, 0.0001)
	assert_float(EventEffects.production(state, 0, farm)).is_equal(1.0)


func test_production_boost_makes_more_goods() -> void:
	var sim := SimFixture.simulation()
	SimFixture.road(sim, Vector2i(0, 20), Vector2i(119, 20))
	SimFixture.house(sim, 60, 20, &"peasants", 10.0)
	SimFixture.place(sim, &"lumberjack", Vector2i(10, 21))
	_inject(sim, EventDef.Effect.PRODUCTION, 2.0, 0, 600.0)
	SimFixture.run_production(sim, 30.4)
	# ciclo de 15 s pela metade: 4 t em vez de 2
	assert_float(SimFixture.stock(sim, &"wood")).is_equal(4.0)


func test_price_ship_happiness_and_arrival_effects() -> void:
	var sim := _fast_sim()
	var plain := sim.world.trader_price(sim.data, sim.config, &"bricks")
	_inject(sim, EventDef.Effect.TRADER_PRICE, 1.4, -1, 60.0, EventDef.Group.ALL, &"bricks")
	_inject(sim, EventDef.Effect.SHIP_SPEED, 0.6)
	_inject(sim, EventDef.Effect.HAPPINESS, 12.0, 1)
	_inject(sim, EventDef.Effect.ARRIVAL, 2.0, 1)
	var state := sim.world.events_state
	assert_float(sim.world.trader_price(sim.data, sim.config, &"bricks")).is_equal_approx(plain * 1.4, 0.001)
	assert_float(EventEffects.price(state, &"fish")).is_equal(1.0)
	assert_float(EventEffects.ship_speed(state)).is_equal_approx(0.6, 0.0001)
	assert_float(EventEffects.happiness(state, 1)).is_equal(12.0)
	assert_float(EventEffects.happiness(state, 0)).is_equal(0.0)
	assert_float(EventEffects.arrival(state, 1)).is_equal(2.0)
	assert_float(EventEffects.arrival(state, 0)).is_equal(1.0)


func test_storm_slows_the_ship() -> void:
	var calm := _fast_sim(false)
	var stormy := _fast_sim(false)
	var times: Array[float] = []
	for sim: Simulation in [calm, stormy]:
		if sim == stormy:
			_inject(sim, EventDef.Effect.SHIP_SPEED, 0.5, -1, 3600.0)
		var ship_id := SimFixture.ship(sim, 0)
		var ship := sim.world.ship(ship_id)
		SimFixture.run(sim, 0.2)
		sim.execute(MoveShipCommand.new(ship_id, 1))
		times.append(SimFixture.run_until(sim, func() -> bool: return ship.state == Ship.State.IDLE and ship.at == 1, 900.0))
	assert_float(times[1]).is_greater(times[0] * 1.6)


func test_happiness_event_raises_the_house_target() -> void:
	var sims: Array[Simulation] = [SimFixture.simulation(), SimFixture.simulation()]
	var happiness: Array[float] = []
	for index: int in 2:
		var sim := sims[index]
		SimFixture.road(sim, Vector2i(0, 20), Vector2i(119, 20))
		var house := SimFixture.house(sim, 60, 20, &"peasants", 10.0)
		if index == 1:
			_inject(sim, EventDef.Effect.HAPPINESS, 12.0, 0, 3600.0)
		SimFixture.run(sim, 600.0)
		happiness.append(sim.world.building(house).happiness)
	assert_float(happiness[1]).is_greater(happiness[0] + 5.0)


func test_mission_offer_accept_deliver_and_bonus() -> void:
	var sim := _fast_sim()
	var offered: Array[int] = []
	var done: Array[int] = []
	EventBus.mission_offered.connect(func(id: int) -> void: offered.append(id))
	EventBus.mission_completed.connect(func(_def: StringName, bonus: int) -> void: done.append(bonus))
	SimFixture.run_until(sim, func() -> bool: return not offered.is_empty(), 60.0)
	assert_int(offered.size()).is_equal(1)
	var item := sim.world.events_state.mission(offered[0])
	assert_int(item.state).is_equal(Mission.State.OFFERED)
	assert_int(item.def.after_milestone).is_equal(0)
	assert_bool(sim.execute(AnswerMissionCommand.new(item.id, true)).ok()).is_true()
	assert_int(item.state).is_equal(Mission.State.ACCEPTED)
	assert_int(item.ticks_left(sim.world.tick)).is_equal(sim.config.ticks_of(item.def.duration_s))
	# não se responde duas vezes
	assert_str(sim.execute(AnswerMissionCommand.new(item.id, false)).reason).is_equal(AnswerMissionCommand.NO_MISSION)
	var ship_id := SimFixture.ship(sim, 0)
	var ship := sim.world.ship(ship_id)
	var good := item.def.good
	ship.at = Ship.TRADER_POST
	ship.load_good(good, float(item.def.tons) + 5.0, sim.data.ship(ship.def_id).slot_capacity_t)
	var price := sim.world.trader_price(sim.data, sim.config, good)
	var money := sim.world.money
	var half := float(item.def.tons) / 2.0
	assert_bool(sim.execute(TradeWithTraderCommand.new(ship_id, good, -half)).ok()).is_true()
	assert_float(item.delivered).is_equal_approx(half, 0.0001)
	assert_float(sim.world.money - money).is_equal_approx(half * price, 0.01)
	assert_int(done.size()).is_equal(0)
	money = sim.world.money
	sim.execute(TradeWithTraderCommand.new(ship_id, good, -(half + 5.0)))
	# a encomenda leva o que falta; os 5 t a mais são vendidos ao preço normal
	assert_int(done.size()).is_equal(1)
	assert_int(done[0]).is_equal(item.def.bonus(sim.data))
	assert_float(sim.world.money - money).is_equal_approx((half + 5.0) * price + item.def.bonus(sim.data), 0.01)
	assert_object(sim.world.events_state.mission(item.id)).is_null()
	assert_int(sim.world.events_state.missions_done).is_equal(1)


func test_route_unloading_at_the_post_delivers_the_mission() -> void:
	var sim := _fast_sim()
	sim.world.events_state.next_offer_tick = 999_999_999
	var item := Mission.new()
	item.id = sim.world.events_state.next_mission_id
	sim.world.events_state.next_mission_id += 1
	item.def = sim.data.mission(&"planks")
	item.def_id = item.def.id
	item.state = Mission.State.ACCEPTED
	item.expires_tick = sim.world.tick + sim.config.ticks_of(3600.0)
	sim.world.events_state.missions.append(item)
	SimFixture.give(sim, &"planks", 40.0)
	var ship_id := SimFixture.ship(sim, 0)
	var route := SimFixture.route(sim, [[0, [[&"planks", true, 40]]], [Ship.TRADER_POST, [[&"planks", false, 40]]]])
	sim.execute(SetShipRouteCommand.new(ship_id, route))
	var bonus: Array[int] = []
	EventBus.mission_completed.connect(func(_def: StringName, amount: int) -> void: bonus.append(amount))
	SimFixture.run_until(sim, func() -> bool: return not bonus.is_empty(), 1800.0)
	assert_array(bonus).is_equal([item.def.bonus(sim.data)])


func test_declined_and_unanswered_offers_disappear_and_expired_missions_cost_nothing() -> void:
	var sim := _fast_sim()
	sim.config.mission_offer_s = 20.0
	var expired: Array[bool] = []
	EventBus.mission_expired.connect(func(_def: StringName, accepted: bool) -> void: expired.append(accepted))
	SimFixture.run_until(sim, func() -> bool: return not sim.world.events_state.missions.is_empty(), 60.0)
	var first := sim.world.events_state.missions[0]
	assert_bool(sim.execute(AnswerMissionCommand.new(first.id, false)).ok()).is_true()
	assert_object(sim.world.events_state.mission(first.id)).is_null()
	SimFixture.run_until(sim, func() -> bool: return not sim.world.events_state.missions.is_empty(), 60.0)
	var second := sim.world.events_state.missions[0]
	SimFixture.run(sim, 21.0)
	assert_object(sim.world.events_state.mission(second.id)).is_null()
	assert_array(expired).is_equal([false])
	SimFixture.run_until(sim, func() -> bool: return not sim.world.events_state.missions.is_empty(), 60.0)
	var third := sim.world.events_state.missions[0]
	sim.execute(AnswerMissionCommand.new(third.id, true))
	SimFixture.run(sim, third.def.duration_s + 1.0)
	assert_object(sim.world.events_state.mission(third.id)).is_null()
	assert_array(expired).contains([true])


func test_open_missions_respect_the_limit_and_never_repeat_a_good() -> void:
	var sim := _fast_sim()
	sim.config.mission_interval_s = 5.0
	for step: int in 40:
		SimFixture.run(sim, 5.0)
		var missions := sim.world.events_state.missions
		assert_int(missions.size()).is_less_equal(sim.config.max_open_missions)
		var goods: Dictionary[StringName, bool] = {}
		for item: Mission in missions:
			assert_bool(goods.has(item.def.good)).is_false()
			goods[item.def.good] = true


func test_no_missions_without_a_trading_post() -> void:
	var sim := SimFixture.simulation()
	sim.config.mission_first_after_s = 5.0
	sim.world.events_state.enabled = true
	SimFixture.run(sim, 60.0)
	assert_int(sim.world.events_state.missions.size()).is_equal(0)


func test_save_and_load_keeps_events_and_missions_and_continues_the_same() -> void:
	var sim := _fast_sim()
	SimFixture.run(sim, 90.0)
	var state := sim.world.events_state
	if not state.missions.is_empty():
		sim.execute(AnswerMissionCommand.new(state.missions[0].id, true))
	assert_int(state.events.size() + state.missions.size()).is_greater(0)
	var saved := sim.world.to_dict()
	var loaded_world := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(loaded_world).is_not_null()
	var copy := Simulation.new(sim.config, sim.data, loaded_world)
	assert_dict(loaded_world.events_state.to_dict()).is_equal(state.to_dict())
	var original := _history(sim, 120.0)
	var reloaded := _history(copy, 120.0)
	assert_array(reloaded).is_equal(original)
	assert_dict(copy.world.events_state.to_dict()).is_equal(sim.world.events_state.to_dict())


func test_corrupt_events_refuse_the_save() -> void:
	var sim := _fast_sim()
	_inject(sim, EventDef.Effect.SHIP_SPEED, 0.6)
	var saved := sim.world.to_dict()
	var events: Dictionary = saved["events"]
	var list: Array = events["events"]
	var first: Dictionary = list[0]
	first["def"] = &"no_such_event"
	assert_object(WorldState.from_dict(saved, sim.data, sim.config)).is_null()


func test_old_saves_migrate_with_events_on() -> void:
	var migrated := SaveMigrations.from_8_to_9({"world": {}})
	var world: Dictionary = migrated["world"]
	var events: Dictionary = world["events"]
	assert_bool(events["enabled"]).is_true()
	assert_int(SaveSystem.SAVE_VERSION).is_equal(9)
	assert_int(SaveMigrations.all().size()).is_equal(SaveSystem.SAVE_VERSION - 1)
