extends GdUnitTestSuite
## Objetivo da partida (Fase 12): partida livre nunca acaba; com objetivo, cumprir vence (match_won) e
## passar do prazo perde (match_lost); depois disso não confere mais. O objetivo vai no save; saves
## antigos seguem livres. Os cenários e as conquistas dos dados são válidos.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))


func test_free_match_never_ends() -> void:
	SimFixture.house(_sim, 30, 20, &"artisans", 30.0)
	SimFixture.run(_sim, 5.0)
	assert_bool(_sim.world.victory_state.has_goal()).is_false()
	assert_int(_sim.world.victory_state.outcome).is_equal(VictoryState.Outcome.PLAYING)


func test_meeting_the_objective_wins() -> void:
	VictorySystem.start(_sim.world, _sim.config, GoalDef.Kind.TIER_POPULATION, &"artisans", 20, 0.0)
	var won := [0]
	var on_won := func() -> void: won[0] += 1
	EventBus.match_won.connect(on_won)
	SimFixture.run(_sim, 2.0)
	assert_int(_sim.world.victory_state.outcome).is_equal(VictoryState.Outcome.PLAYING)
	var house := SimFixture.house(_sim, 30, 20, &"artisans", 25.0)
	SimFixture.run(_sim, 2.0)
	assert_int(_sim.world.victory_state.outcome).is_equal(VictoryState.Outcome.WON)
	assert_int(_sim.world.victory_state.ended_tick).is_greater(0)
	# vencida, não confere mais (nem perde se a gente for embora)
	_sim.world.building(house).residents = 0.0
	SimFixture.run(_sim, 2.0)
	EventBus.match_won.disconnect(on_won)
	assert_int(won[0]).is_equal(1)
	assert_int(_sim.world.victory_state.outcome).is_equal(VictoryState.Outcome.WON)


func test_missing_the_deadline_loses() -> void:
	VictorySystem.start(_sim.world, _sim.config, GoalDef.Kind.MONEY, &"", 10_000_000, 0.5)
	var lost := [0]
	var on_lost := func() -> void: lost[0] += 1
	EventBus.match_lost.connect(on_lost)
	SimFixture.run(_sim, 25.0)
	assert_int(_sim.world.victory_state.outcome).is_equal(VictoryState.Outcome.PLAYING)
	SimFixture.run(_sim, 10.0)
	EventBus.match_lost.disconnect(on_lost)
	assert_int(_sim.world.victory_state.outcome).is_equal(VictoryState.Outcome.LOST)
	assert_int(lost[0]).is_equal(1)


func test_money_objective_counts_the_coins() -> void:
	_sim.world.money = 1234.9
	VictorySystem.start(_sim.world, _sim.config, GoalDef.Kind.MONEY, &"", 2000, 0.0)
	assert_int(VictorySystem.progress(_sim.world, _sim.data, _sim.config, _sim.derived_state())).is_equal(1234)
	_sim.world.money = -50.0
	assert_int(VictorySystem.progress(_sim.world, _sim.data, _sim.config, _sim.derived_state())).is_equal(0)


func test_save_keeps_the_objective() -> void:
	VictorySystem.start(_sim.world, _sim.config, GoalDef.Kind.TIER_POPULATION, &"investors", 100, 120.0, &"poor_colony")
	var loaded := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)
	assert_object(loaded).is_not_null()
	var state := loaded.victory_state
	assert_int(state.kind).is_equal(GoalDef.Kind.TIER_POPULATION)
	assert_str(state.target).is_equal("investors")
	assert_int(state.amount).is_equal(100)
	assert_int(state.deadline_tick).is_equal(_sim.config.ticks_of(7200.0))
	assert_str(state.scenario_id).is_equal("poor_colony")
	_sim.world.victory_state.target = &"pirates"
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()
	_sim.world.victory_state.target = &"investors"
	_sim.world.victory_state.scenario_id = &"nowhere"
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()


func test_old_saves_stay_free() -> void:
	var migrated := SaveMigrations.from_14_to_15({"world": {}})
	var world: Dictionary = migrated["world"]
	var saved: Dictionary = world["victory"]
	var loaded := VictoryState.from_dict(saved, GameData.get_default())
	assert_object(loaded).is_not_null()
	assert_bool(loaded.has_goal()).is_false()
	assert_int(SaveMigrations.all().size()).is_equal(SaveSystem.SAVE_VERSION - 1)


func test_scenarios_and_achievements_are_valid() -> void:
	var data := GameData.get_default()
	assert_int(data.scenarios.size()).is_equal(3)
	assert_str(data.scenarios[0].id).is_equal("poor_colony")
	assert_object(data.scenario(&"island_race")).is_not_null()
	assert_int(data.achievements.size()).is_greater_equal(8)
	for def: ScenarioDef in data.scenarios:
		var found := data.achievements.filter(func(item: AchievementDef) -> bool:
			return item.kind == AchievementDef.Kind.VICTORY and item.target == def.id)
		assert_int(found.size()).override_failure_message(String(def.id)).is_equal(1)
	assert_array(data.validate()).is_empty()
	assert_array(GameConfig.new().validate()).is_empty()
