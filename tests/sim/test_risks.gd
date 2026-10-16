extends GdUnitTestSuite
## Riscos (seção 8, opcionais): incêndio em casa e produção, doença em casa. O quartel de bombeiros
## protege o que encosta na estrada ao alcance dele (fogo apagado em fire_extinguish_s, chance menor);
## sem ele o prédio queima fire_burnout_s e se perde. O hospital cura a casa em disease_cure_s; sem ele
## a doença dura disease_duration_s e a casa perde moradores. Desligados, nada acontece.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.world.risks_state.enabled = true
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	SimFixture.warm_supply(_sim)


func _station() -> int:
	return SimFixture.place(_sim, &"fire_station", Vector2i(10, 21))


func _hospital() -> int:
	return SimFixture.place(_sim, &"hospital", Vector2i(14, 21))


## Chance de 100% a cada conferência, para o sorteio não depender da sorte.
func _certain_risks() -> void:
	_sim.config.fire_chance_per_hour = 1.0e9
	_sim.config.disease_chance_per_hour = 1.0e9
	_sim.config.fire_protected_factor = 0.0
	_sim.config.disease_protected_factor = 0.0
	_sim.world.milestones_reached = 2


func test_data_defines_the_fire_station_and_the_hospital() -> void:
	var data := GameData.get_default()
	assert_int(data.building(&"fire_station").protects).is_equal(BuildingDef.Hazard.FIRE)
	assert_int(data.building(&"hospital").protects).is_equal(BuildingDef.Hazard.DISEASE)
	assert_bool(data.building(&"house").can_burn()).is_true()
	assert_bool(data.building(&"bakery").can_burn()).is_true()
	assert_float(data.building(&"bakery").fire_risk).is_greater(data.building(&"lumberjack").fire_risk)
	for def_id: StringName in [&"market", &"warehouse", &"field", &"fire_station", &"trading_post"]:
		assert_bool(data.building(def_id).can_burn()).override_failure_message(String(def_id)).is_false()
	assert_array(data.validate()).is_empty()
	assert_array(GameConfig.new().validate()).is_empty()


func test_station_protects_houses_and_production_in_its_reach() -> void:
	var station := _station()
	var near_house := SimFixture.house(_sim, 30, 20, &"peasants", 10.0)
	var near_bakery := SimFixture.place(_sim, &"bakery", Vector2i(20, 21))
	var far_bakery := SimFixture.place(_sim, &"bakery", Vector2i(100, 21))
	var derived := _sim.derived_state()
	assert_bool(derived.fire_protected.has(near_house)).is_true()
	assert_bool(derived.fire_protected.has(near_bakery)).is_true()
	assert_bool(derived.fire_protected.has(far_bakery)).is_false()
	assert_array(derived.protected_by[station]).contains([near_house, near_bakery])
	assert_bool(derived.health_protected.has(near_house)).is_false()


func test_unprotected_fire_destroys_the_building() -> void:
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(100, 21))
	var lost: Array[StringName] = []
	var on_lost := func(_id: int, def_id: StringName, _island: int) -> void: lost.append(def_id)
	EventBus.building_lost.connect(on_lost)
	RiskSystem.ignite(_sim.world, bakery)
	SimFixture.run(_sim, 2.0)
	assert_int(_sim.world.building(bakery).state).is_equal(BuildingRecord.State.ON_FIRE)
	SimFixture.run(_sim, _sim.config.fire_burnout_s)
	EventBus.building_lost.disconnect(on_lost)
	assert_object(_sim.world.building(bakery)).is_null()
	assert_int(_sim.world.island(0).building_at(Vector2i(100, 21))).is_equal(0)
	assert_array(lost).contains_exactly([&"bakery"])
	assert_int(_sim.world.risks_state.buildings_lost).is_equal(1)
	assert_bool(_sim.world.risks_state.fires.is_empty()).is_true()


func test_protected_fire_is_put_out_and_the_building_stays() -> void:
	_station()
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(20, 21))
	RiskSystem.ignite(_sim.world, bakery)
	SimFixture.run(_sim, _sim.config.fire_extinguish_s + 6.0)
	assert_object(_sim.world.building(bakery)).is_not_null()
	assert_bool(_sim.world.risks_state.is_burning(bakery)).is_false()
	assert_int(_sim.world.risks_state.buildings_lost).is_equal(0)


func test_station_built_during_the_fire_still_saves_the_building() -> void:
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(20, 21))
	RiskSystem.ignite(_sim.world, bakery)
	SimFixture.run(_sim, _sim.config.fire_burnout_s * 0.5)
	_station()
	SimFixture.run(_sim, _sim.config.fire_burnout_s)
	assert_object(_sim.world.building(bakery)).is_not_null()
	assert_bool(_sim.world.risks_state.is_burning(bakery)).is_false()


func test_burning_house_pays_no_tax() -> void:
	var house := SimFixture.house(_sim, 30, 20, &"peasants", 10.0)
	_sim.world.building(house).happiness = 60.0
	_station()
	SimFixture.run(_sim, 4.0)
	assert_float(_sim.world.building(house).tax_per_min).is_greater(0.0)
	RiskSystem.ignite(_sim.world, house)
	SimFixture.run(_sim, 4.0)
	assert_float(_sim.world.building(house).tax_per_min).is_equal(0.0)


func test_sick_house_loses_residents_and_the_hospital_cures_it_sooner() -> void:
	_hospital()
	var near := SimFixture.house(_sim, 30, 20, &"peasants", 10.0)
	var far := SimFixture.house(_sim, 100, 20, &"peasants", 10.0)
	assert_bool(_sim.derived_state().health_protected.has(near)).is_true()
	assert_bool(_sim.derived_state().health_protected.has(far)).is_false()
	RiskSystem.infect(_sim.world, near)
	RiskSystem.infect(_sim.world, far)
	SimFixture.run(_sim, _sim.config.disease_cure_s + 6.0)
	assert_bool(_sim.world.risks_state.is_sick(near)).is_false()
	assert_bool(_sim.world.risks_state.is_sick(far)).is_true()
	assert_float(_sim.world.building(far).residents).is_less(9.0)
	SimFixture.run(_sim, _sim.config.disease_duration_s)
	assert_bool(_sim.world.risks_state.is_sick(far)).is_false()
	assert_int(_sim.world.risks_state.outbreaks_cured).is_equal(2)


func test_protection_and_the_milestone_gate_the_draw() -> void:
	_station()
	_hospital()
	var near := SimFixture.house(_sim, 30, 20, &"peasants", 10.0)
	var far := SimFixture.place(_sim, &"bakery", Vector2i(100, 21))
	_certain_risks()
	_sim.world.milestones_reached = 0
	SimFixture.run(_sim, 10.0)
	assert_bool(_sim.world.risks_state.fires.is_empty()).is_true()
	_sim.world.milestones_reached = 2
	SimFixture.run(_sim, 10.0)
	assert_bool(_sim.world.risks_state.is_burning(far)).is_true()
	assert_bool(_sim.world.risks_state.is_burning(near)).is_false()
	assert_bool(_sim.world.risks_state.is_sick(near)).is_false()


func test_fires_stop_at_the_cap() -> void:
	for x: int in [40, 50, 60, 70, 80, 90]:
		SimFixture.place(_sim, &"bakery", Vector2i(x, 21))
	_certain_risks()
	SimFixture.run(_sim, 10.0)
	assert_int(_sim.world.risks_state.fires.size()).is_equal(_sim.config.max_active_fires)


func test_disabled_risks_never_happen() -> void:
	SimFixture.place(_sim, &"bakery", Vector2i(100, 21))
	SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	_certain_risks()
	_sim.world.risks_state.enabled = false
	SimFixture.run(_sim, 30.0)
	assert_bool(_sim.world.risks_state.fires.is_empty()).is_true()
	assert_bool(_sim.world.risks_state.outbreaks.is_empty()).is_true()


func test_demolish_forgets_the_fire() -> void:
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(100, 21))
	RiskSystem.ignite(_sim.world, bakery)
	_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(100, 21), Vector2i.ONE)))
	assert_bool(_sim.world.risks_state.fires.is_empty()).is_true()
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_not_null()


func test_save_keeps_fires_and_outbreaks_and_the_match_goes_on_the_same() -> void:
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(100, 21))
	var house := SimFixture.house(_sim, 60, 20, &"peasants", 10.0)
	SimFixture.run(_sim, 3.0)
	RiskSystem.ignite(_sim.world, bakery)
	RiskSystem.infect(_sim.world, house)
	SimFixture.run(_sim, 3.0)
	_certain_risks()
	var loaded := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)
	assert_object(loaded).is_not_null()
	assert_bool(loaded.risks_state.enabled).is_true()
	assert_int(loaded.risks_state.fires[bakery]).is_equal(_sim.world.risks_state.fires[bakery])
	assert_bool(loaded.risks_state.is_sick(house)).is_true()
	var copy := Simulation.new(_sim.config, _sim.data, loaded)
	copy.free_build = true
	SimFixture.run(_sim, 120.0)
	SimFixture.run(copy, 120.0)
	assert_dict(copy.world.risks_state.to_dict()).is_equal(_sim.world.risks_state.to_dict())
	assert_bool(_sim.world.buildings.has(bakery)).is_false()


func test_save_with_risk_on_the_wrong_building_is_refused() -> void:
	var market := SimFixture.place(_sim, &"market", Vector2i(40, 21))
	_sim.world.risks_state.fires[market] = 0
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()
	_sim.world.risks_state.fires.clear()
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(100, 21))
	_sim.world.risks_state.outbreaks[bakery] = 0
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()
	_sim.world.risks_state.outbreaks.clear()
	_sim.world.risks_state.fires[9999] = 0
	assert_object(WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)).is_null()


func test_old_saves_open_with_risks_off() -> void:
	var migrated := SaveMigrations.from_12_to_13({"world": {}})
	var world: Dictionary = migrated["world"]
	var saved: Dictionary = world["risks"]
	var loaded := RisksState.from_dict(saved, WorldState.new(), GameData.get_default())
	assert_object(loaded).is_not_null()
	assert_bool(loaded.enabled).is_false()
	assert_int(SaveMigrations.all().size()).is_equal(SaveSystem.SAVE_VERSION - 1)
