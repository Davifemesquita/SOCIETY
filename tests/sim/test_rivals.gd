extends GdUnitTestSuite
## Companhias rivais (Fase 11): desligadas por padrão; ligadas, colonizam ilhas livres na hora
## marcada e sempre as mesmas para a mesma semente, respeitam os tetos, crescem, põem o navio delas
## entre a ilha e o comerciante e travam a colonização do jogador na ilha delas. A diplomacia:
## presente, acordo (com renda), guerra, paz, a deriva da relação e a IA da postura. Tudo no save.


## Arquipélago pequeno da semente 1840 com entreposto na principal e os tempos encurtados.
func _rival_sim(enabled: bool = true) -> Simulation:
	var config := GameConfig.new()
	config.starting_ship = &""
	config.starting_materials = {}
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, data, 0)
	var sim := Simulation.new(config, data, world)
	sim.free_build = true
	var post := SiteFinder.find(sim, &"trading_post", 0, world.island(0).size / 2)
	var origin: Vector2i = post[0]
	var rotation: int = post[1]
	assert(sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation)).ok())
	if enabled:
		world.rivals_state.start(data, config)
		for rival: RivalState in world.rivals_state.rivals:
			rival.def = rival.def.duplicate()
			rival.def.first_colony_s = 20.0
			rival.def.colony_interval_s = 40.0
	return sim


func _claims(sim: Simulation, seconds: float) -> Array[String]:
	var seen: Array[String] = []
	var record := func(rival: StringName, island_id: int) -> void: seen.append("%s@%d:%d" % [rival, island_id, sim.world.tick])
	EventBus.rival_colonized.connect(record)
	SimFixture.run(sim, seconds)
	EventBus.rival_colonized.disconnect(record)
	return seen


func test_data_has_rivals_with_every_personality() -> void:
	var data := GameData.get_default()
	assert_array(data.validate()).is_empty()
	assert_int(data.rivals.size()).is_greater_equal(2)
	var personalities: Dictionary[int, bool] = {}
	for def: RivalDef in data.rivals:
		personalities[def.personality] = true
	assert_int(personalities.size()).is_equal(3)


func test_disabled_worlds_have_no_rivals() -> void:
	var sim := _rival_sim(false)
	SimFixture.run(sim, 120.0)
	assert_int(sim.world.rivals_state.rivals.size()).is_equal(0)
	assert_bool(SimFixture.simulation().world.rivals_state.enabled).is_false()


func test_rivals_colonize_free_islands_the_same_way_for_the_same_seed() -> void:
	var first := _claims(_rival_sim(), 200.0)
	var second := _claims(_rival_sim(), 200.0)
	assert_int(first.size()).is_greater_equal(2)
	assert_array(second).is_equal(first)


func test_rivals_respect_caps_and_never_take_the_players_islands() -> void:
	var sim := _rival_sim()
	SimFixture.run(sim, 600.0)
	var state := sim.world.rivals_state
	assert_int(state.claimed_count()).is_less_equal(RivalSystem.island_cap(sim.world, sim.config))
	for rival: RivalState in state.rivals:
		assert_int(rival.islands.size()).is_less_equal(rival.def.max_islands)
		for island_id: int in rival.islands:
			assert_int(island_id).is_not_equal(0)
			assert_bool(sim.world.has_trading_post(island_id, sim.data)).is_false()
			# tropical só depois do tempo dela
			assert_bool(sim.world.is_tropical(island_id, sim.data)).is_false()


func test_villages_grow_toward_the_island_cap() -> void:
	var sim := _rival_sim()
	SimFixture.run(sim, 60.0)
	var rival := sim.world.rivals_state.rivals[0]
	assert_int(rival.islands.size()).is_equal(1)
	var island_id: int = rival.island_ids()[0]
	var start := rival.islands[island_id]
	SimFixture.run(sim, 600.0)
	assert_float(rival.islands[island_id]).is_greater(start + 10.0)
	var grid := sim.world.island(island_id)
	assert_float(rival.islands[island_id]).is_less_equal(grid.size.x * grid.size.y * sim.config.rival_residents_per_cell + 0.001)


func test_rival_ship_sails_between_its_island_and_the_trader() -> void:
	var sim := _rival_sim()
	sim.config.rival_ship_dwell_s = 5.0
	SimFixture.run(sim, 30.0)
	var rival := sim.world.rivals_state.rivals[0]
	var ship := sim.world.ship(rival.ship_id)
	assert_object(ship).is_not_null()
	assert_int(ship.owner).is_equal(Ship.Owner.RIVAL)
	assert_array(sim.world.player_ships()).not_contains([ship])
	var visited: Dictionary[int, bool] = {}
	for step: int in 400:
		SimFixture.run(sim, 5.0)
		if ship.state == Ship.State.IDLE:
			visited[ship.at] = true
	assert_bool(visited.has(Ship.TRADER_POST)).is_true()
	assert_bool(visited.has(rival.island_ids()[0])).is_true()


func test_player_cannot_colonize_a_rival_island() -> void:
	var sim := _rival_sim()
	SimFixture.run(sim, 30.0)
	var rival := sim.world.rivals_state.rivals[0]
	var island_id: int = rival.island_ids()[0]
	sim.free_build = false
	var post := sim.data.building(&"trading_post")
	var site := SiteFinder.find(sim, &"trading_post", island_id, sim.world.island(island_id).size / 2)
	var origin: Vector2i = site[0]
	var rotation: int = site[1]
	assert_str(sim.placement_reason(post, origin, rotation, island_id)).is_equal(PlacementRules.RIVAL_ISLAND)


func test_gift_trade_war_and_peace() -> void:
	var sim := _rival_sim()
	SimFixture.run(sim, 30.0)
	var config := sim.config
	var rival := sim.world.rivals_state.by_id(&"hanseatic")
	rival.relation = 0.0
	sim.world.money = 100000.0
	var money := sim.world.money
	assert_bool(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.GIFT)).ok()).is_true()
	assert_float(rival.relation).is_equal_approx(config.rival_gift_relation, 0.001)
	assert_float(money - sim.world.money).is_equal_approx(config.rival_gift_money, 0.001)
	assert_str(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.GIFT)).reason).is_equal(DiplomacyCommand.TOO_SOON)
	# acordo só com relação alta
	rival.relation = config.rival_trade_relation - 1.0
	assert_str(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.PROPOSE_TRADE)).reason).is_equal(DiplomacyCommand.REFUSES)
	rival.relation = config.rival_trade_relation + 5.0
	assert_bool(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.PROPOSE_TRADE)).ok()).is_true()
	assert_int(rival.stance).is_equal(RivalState.Stance.TRADE)
	money = sim.world.money
	SimFixture.run(sim, 60.0)
	assert_float(sim.world.treaty_income_per_min).is_greater(0.0)
	# a renda do acordo entra no caixa (a principal só tem o entreposto: sem outra entrada)
	assert_float(sim.world.money).is_greater(money - sim.world.upkeep_per_min)
	# guerra
	assert_bool(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.DECLARE_WAR)).ok()).is_true()
	assert_int(rival.stance).is_equal(RivalState.Stance.WAR)
	assert_float(sim.world.rivals_state.by_id(&"hanseatic").relation).is_less(0.0)
	# paz: cedo demais, depois com relação baixa recusa, com relação melhor aceita
	assert_str(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.PROPOSE_PEACE)).reason).is_equal(DiplomacyCommand.TOO_SOON)
	rival.stance_tick -= config.ticks_of(config.rival_stance_cooldown_s)
	rival.relation = config.rival_peace_relation - 1.0
	assert_str(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.PROPOSE_PEACE)).reason).is_equal(DiplomacyCommand.REFUSES)
	rival.relation = config.rival_peace_relation + 1.0
	assert_bool(sim.execute(DiplomacyCommand.new(rival.def_id, DiplomacyCommand.Action.PROPOSE_PEACE)).ok()).is_true()
	assert_int(rival.stance).is_equal(RivalState.Stance.NEUTRAL)


func test_relation_drifts_and_the_ai_picks_its_stance() -> void:
	var sim := _rival_sim()
	var config := sim.config
	var aggressive := sim.world.rivals_state.by_id(&"ironside")
	var peaceful := sim.world.rivals_state.by_id(&"verdant")
	aggressive.relation = config.rival_war_relation - 5.0
	peaceful.relation = -100.0
	peaceful.stance = RivalState.Stance.WAR
	var trading := sim.world.rivals_state.by_id(&"hanseatic")
	trading.stance = RivalState.Stance.TRADE
	trading.relation = -1.0
	sim.world.tick += config.ticks_of(config.rival_stance_cooldown_s)
	SimFixture.run(sim, 2.0)
	assert_int(aggressive.stance).is_equal(RivalState.Stance.WAR)
	assert_int(trading.stance).is_equal(RivalState.Stance.NEUTRAL)
	assert_int(peaceful.stance).is_equal(RivalState.Stance.WAR)
	var before := peaceful.relation
	SimFixture.run(sim, 60.0)
	assert_float(peaceful.relation).is_greater(before)
	peaceful.relation = config.rival_auto_peace_relation + 1.0
	peaceful.stance_tick = -1_000_000
	SimFixture.run(sim, 2.0)
	assert_int(peaceful.stance).is_equal(RivalState.Stance.NEUTRAL)


func test_player_colonies_cool_the_ambitious_rivals() -> void:
	var sim := _rival_sim()
	var ambitious := sim.world.rivals_state.by_id(&"hanseatic")
	var peaceful := sim.world.rivals_state.by_id(&"verdant")
	var ambitious_before := ambitious.relation
	var peaceful_before := peaceful.relation
	RivalSystem.on_player_colony(sim.world, sim.config)
	assert_float(ambitious.relation).is_equal_approx(ambitious_before - sim.config.rival_colony_penalty, 0.001)
	assert_float(peaceful.relation).is_equal(peaceful_before)


func test_save_and_load_keeps_the_rivals_and_continues_the_same() -> void:
	var sim := _rival_sim()
	SimFixture.run(sim, 120.0)
	var state := sim.world.rivals_state
	assert_int(state.claimed_count()).is_greater(0)
	var loaded := WorldState.from_dict(sim.world.to_dict(), sim.data, sim.config)
	assert_object(loaded).is_not_null()
	assert_dict(loaded.rivals_state.to_dict()).is_equal(state.to_dict())
	# as definições encurtadas do teste não vão para o save: a cópia usa as mesmas
	for index: int in state.rivals.size():
		loaded.rivals_state.rivals[index].def = state.rivals[index].def
	var copy := Simulation.new(sim.config, sim.data, loaded)
	var original := _claims(sim, 200.0)
	var reloaded := _claims(copy, 200.0)
	assert_array(reloaded).is_equal(original)
	assert_dict(copy.world.rivals_state.to_dict()).is_equal(sim.world.rivals_state.to_dict())


func test_bad_rival_data_refuses_the_save() -> void:
	var sim := _rival_sim()
	SimFixture.run(sim, 60.0)
	var saved := sim.world.to_dict()
	var rivals: Dictionary = saved["rivals"]
	var list: Array = rivals["rivals"]
	var first: Dictionary = list[0]
	var islands: Array = first["islands"]
	var island: Dictionary = islands[0]
	island["island"] = 0
	assert_object(WorldState.from_dict(saved, sim.data, sim.config)).is_null()


func test_old_saves_migrate_with_rivals() -> void:
	var migrated := SaveMigrations.from_9_to_10({"world": {"ships": [{"owner": 0}]}})
	var world: Dictionary = migrated["world"]
	var rivals: Dictionary = world["rivals"]
	assert_bool(rivals["enabled"]).is_true()
	var list: Array = rivals["rivals"]
	assert_int(list.size()).is_equal(GameData.get_default().rivals.size())
	assert_int(SaveSystem.SAVE_VERSION).is_greater_equal(10)
