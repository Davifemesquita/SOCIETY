extends GdUnitTestSuite
## Combate naval (Fase 11): fragata com casco e canhões; em guerra, o navio armado atira no inimigo
## mais perto ao alcance e o casco a zero afunda o navio com a carga; sem guerra ninguém atira; o
## comerciante nunca é alvo; o casco se repara no porto próprio. Em guerra a rival arma fragatas, que
## somem na paz; perder fragata aproxima a rival da paz. Tudo no save.


## Duas ilhas planas, a 2 com uma rival (ironside) dona dela, em guerra ou não.
func _war_sim(at_war: bool = true) -> Simulation:
	var sim := SimFixture.two_islands()
	sim.world.seed = 1840
	sim.execute(DemolishCommand.new(1, Rect2i(0, 0, 6, 6)))
	sim.world.rivals_state.start(sim.data, sim.config)
	var rival := sim.world.rivals_state.by_id(&"ironside")
	rival.islands[1] = 200.0
	for other: RivalState in sim.world.rivals_state.rivals:
		other.next_colony_tick = 999_999_999
	if at_war:
		RivalSystem.set_stance(sim.world, rival, RivalState.Stance.WAR)
	return sim


## Navio posto direto no mar, num ponto (sem esperar viagem).
func _ship_at(sim: Simulation, def_id: StringName, owner: Ship.Owner, point: Vector2) -> Ship:
	var ship := Ship.new(sim.world.next_ship_id, sim.data.ship(def_id), owner)
	sim.world.next_ship_id += 1
	ship.position = point
	ship.previous_position = point
	ship.at = Ship.NOWHERE
	sim.world.ships[ship.id] = ship
	return ship


func _rival_frigate(sim: Simulation, point: Vector2) -> Ship:
	var ship := _ship_at(sim, &"frigate", Ship.Owner.RIVAL, point)
	sim.world.rivals_state.by_id(&"ironside").warships.append(ship.id)
	return ship


func _sea_point(sim: Simulation) -> Vector2:
	return sim.harbors().trader_post + Vector2(0.0, 60.0)


func test_frigate_has_hull_and_cannons_and_merchants_have_none() -> void:
	var data := GameData.get_default()
	var frigate := data.ship(&"frigate")
	assert_object(frigate).is_not_null()
	assert_int(frigate.cannons).is_greater(0)
	assert_float(frigate.salvo_damage).is_greater(0.0)
	assert_float(frigate.hull_points).is_greater(data.ship(&"merchant_ship").hull_points)
	assert_int(data.ship(&"merchant_ship").cannons).is_equal(0)
	assert_array(data.validate()).is_empty()


func test_at_war_the_frigate_sinks_an_enemy_merchant_with_its_cargo() -> void:
	var sim := _war_sim()
	var point := _sea_point(sim)
	var frigate := _ship_at(sim, &"frigate", Ship.Owner.PLAYER, point)
	var rival := sim.world.rivals_state.by_id(&"ironside")
	var merchant := _ship_at(sim, &"merchant_ship", Ship.Owner.RIVAL, point + Vector2(40.0, 0.0))
	rival.ship_id = merchant.id
	merchant.timer = 9999.0
	merchant.load_good(&"fish", 30.0, 50.0)
	var shots: Array[int] = []
	var sunk: Array[int] = []
	EventBus.ship_fired.connect(func(attacker: int, _target: int) -> void: shots.append(attacker))
	EventBus.ship_sunk.connect(func(ship_id: int, _owner: int, _at: Vector2) -> void: sunk.append(ship_id))
	var hits := ceili(sim.data.ship(&"merchant_ship").hull_points / sim.data.ship(&"frigate").salvo_damage)
	SimFixture.run(sim, hits * sim.data.ship(&"frigate").reload_s + 1.0)
	assert_array(sunk).contains([merchant.id])
	assert_object(sim.world.ship(merchant.id)).is_null()
	assert_int(rival.ship_id).is_equal(0)
	assert_int(shots.size()).is_greater_equal(hits)
	assert_object(sim.world.ship(frigate.id)).is_not_null()


func test_no_shots_without_war_and_never_at_the_trader() -> void:
	var sim := _war_sim(false)
	var point := _sea_point(sim)
	_ship_at(sim, &"frigate", Ship.Owner.PLAYER, point)
	var enemy := _rival_frigate(sim, point + Vector2(30.0, 0.0))
	var shots: Array[int] = []
	EventBus.ship_fired.connect(func(attacker: int, _target: int) -> void: shots.append(attacker))
	SimFixture.run(sim, 30.0)
	assert_int(shots.size()).is_equal(0)
	# guerra com outra rival não põe o comerciante na mira
	RivalSystem.set_stance(sim.world, sim.world.rivals_state.by_id(&"hanseatic"), RivalState.Stance.WAR)
	SimFixture.run(sim, 1.0)
	var trader := sim.world.ship(sim.world.trader.ship_id)
	assert_object(trader).is_not_null()
	trader.position = point + Vector2(-20.0, 0.0)
	SimFixture.run(sim, 30.0)
	assert_float(trader.hp).is_equal(sim.data.ship(trader.def_id).hull_points)
	assert_float(enemy.hp).is_equal(sim.data.ship(&"frigate").hull_points)


func test_out_of_range_nobody_fires() -> void:
	var sim := _war_sim()
	var point := _sea_point(sim)
	_ship_at(sim, &"frigate", Ship.Owner.PLAYER, point)
	var enemy := _rival_frigate(sim, point + Vector2(sim.data.ship(&"frigate").cannon_range_m + 20.0, 0.0))
	enemy.timer = 9999.0
	SimFixture.run(sim, 20.0)
	assert_float(enemy.hp).is_equal(sim.data.ship(&"frigate").hull_points)


func test_hull_repairs_in_a_home_port() -> void:
	var sim := _war_sim(false)
	var ship_id := SimFixture.ship(sim, 0)
	var ship := sim.world.ship(ship_id)
	SimFixture.run(sim, 1.0)
	ship.hp = 10.0
	SimFixture.run(sim, 10.0)
	assert_float(ship.hp).is_equal_approx(minf(10.0 + sim.config.ship_repair_per_s * 10.0, sim.data.ship(ship.def_id).hull_points), 1.0)


func test_rival_arms_frigates_at_war_and_disarms_at_peace() -> void:
	var sim := _war_sim()
	var rival := sim.world.rivals_state.by_id(&"ironside")
	SimFixture.run(sim, sim.config.rival_warship_build_s * sim.config.rival_warships + 10.0)
	assert_int(rival.warships.size()).is_equal(sim.config.rival_warships)
	for ship_id: int in rival.warships:
		assert_str(sim.world.ship(ship_id).def_id).is_equal("frigate")
		assert_object(sim.world.rivals_state.by_ship(ship_id)).is_same(rival)
	rival.stance_tick = -1_000_000
	rival.relation = 0.0
	sim.world.money = 100000.0
	assert_bool(sim.execute(DiplomacyCommand.new(&"ironside", DiplomacyCommand.Action.PROPOSE_PEACE)).ok()).is_true()
	SimFixture.run(sim, 2.0)
	assert_int(rival.warships.size()).is_equal(0)


func test_losing_a_frigate_warms_the_rival() -> void:
	var sim := _war_sim()
	var point := _sea_point(sim)
	_ship_at(sim, &"frigate", Ship.Owner.PLAYER, point)
	var enemy := _rival_frigate(sim, point + Vector2(30.0, 0.0))
	enemy.hp = 1.0
	enemy.timer = 9999.0
	var rival := sim.world.rivals_state.by_id(&"ironside")
	rival.relation = -80.0
	SimFixture.run(sim, 2.0)
	assert_object(sim.world.ship(enemy.id)).is_null()
	assert_float(rival.relation).is_greater_equal(-80.0 + sim.config.rival_loss_relation - 1.0)


func test_player_ship_sinks_under_fire() -> void:
	var sim := _war_sim()
	var point := _sea_point(sim)
	var merchant := _ship_at(sim, &"merchant_ship", Ship.Owner.PLAYER, point)
	var enemy := _rival_frigate(sim, point + Vector2(30.0, 0.0))
	enemy.timer = 9999.0
	var lost: Array[int] = []
	EventBus.ship_sunk.connect(func(ship_id: int, owner: int, _at: Vector2) -> void:
		if owner == Ship.Owner.PLAYER:
			lost.append(ship_id))
	SimFixture.run(sim, 120.0)
	assert_array(lost).contains([merchant.id])
	assert_array(sim.world.player_ships()).not_contains([merchant])


func test_buying_a_frigate_waits_for_its_milestone() -> void:
	var sim := _war_sim(false)
	sim.free_build = false
	sim.world.money = 100000.0
	SimFixture.give(sim, &"planks", 100.0)
	SimFixture.give(sim, &"bricks", 100.0)
	var frigate := sim.data.ship(&"frigate")
	sim.world.milestones_reached = frigate.unlock_milestone - 1
	assert_str(sim.execute(BuyShipCommand.new(0, &"frigate")).reason).is_equal(PlacementRules.SHIP_LOCKED)
	sim.world.milestones_reached = frigate.unlock_milestone
	assert_bool(sim.execute(BuyShipCommand.new(0, &"frigate")).ok()).is_true()


func test_save_keeps_hulls_reloads_and_rival_frigates() -> void:
	var sim := _war_sim()
	SimFixture.run(sim, sim.config.rival_warship_build_s + 10.0)
	var rival := sim.world.rivals_state.by_id(&"ironside")
	assert_int(rival.warships.size()).is_greater(0)
	var frigate := sim.world.ship(rival.warships[0])
	frigate.hp = 123.5
	frigate.reload_left = 2.25
	var loaded := WorldState.from_dict(sim.world.to_dict(), sim.data, sim.config)
	assert_object(loaded).is_not_null()
	assert_float(loaded.ship(frigate.id).hp).is_equal(123.5)
	assert_float(loaded.ship(frigate.id).reload_left).is_equal(2.25)
	assert_array(loaded.rivals_state.by_id(&"ironside").warships).is_equal(rival.warships)


func test_old_saves_get_full_hulls() -> void:
	var migrated := SaveMigrations.from_10_to_11({"world": {"ships": [{"def": &"merchant_ship"}],
			"rivals": {"enabled": true, "rivals": [{"def": &"ironside"}]}}})
	var world: Dictionary = migrated["world"]
	var ships: Array = world["ships"]
	var ship: Dictionary = ships[0]
	assert_float(ship["hp"]).is_equal(GameData.get_default().ship(&"merchant_ship").hull_points)
	var rivals: Dictionary = world["rivals"]
	var list: Array = rivals["rivals"]
	var rival: Dictionary = list[0]
	assert_array(rival["warships"]).is_empty()
	assert_int(SaveSystem.SAVE_VERSION).is_greater_equal(11)
