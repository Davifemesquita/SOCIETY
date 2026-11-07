extends GdUnitTestSuite
## Prefeitura (Fase 66): a política escolhida vale nos prédios em volta (até policy_radius_cells), com estrada, somando
## a manutenção dela; jornada longa acelera a produção, vigia de incêndio corta a chance de fogo, feriados sobem a
## felicidade e a coletoria o imposto das casas. A mesma política de duas prefeituras vale uma vez; o comando recusa o
## que não é prefeitura e a política bloqueada. A política vai no save.

const STREET := 20


func _sim() -> Simulation:
	var sim := SimFixture.simulation()
	sim.free_build = true
	SimFixture.road(sim, Vector2i(0, STREET), Vector2i(119, STREET))
	return sim


## Prefeitura de frente para a rua, em x.
func _hall(sim: Simulation, x: int, policy: StringName = &"") -> int:
	var hall := SimFixture.place(sim, &"town_hall", Vector2i(x, STREET - 4), 2)
	if policy != &"":
		assert_bool(sim.execute(SetPolicyCommand.new(hall, policy)).ok()).is_true()
	return hall


func test_data_has_the_town_hall_and_valid_policies() -> void:
	var data := GameData.get_default()
	assert_array(data.validate()).is_empty()
	var hall := data.building(&"town_hall")
	assert_object(hall).is_not_null()
	assert_bool(hall.is_town_hall()).is_true()
	assert_int(hall.kind).is_equal(BuildingDef.Kind.SERVICE)
	assert_int(data.policies.size()).is_equal(4)
	for policy: PolicyDef in data.policies:
		assert_str(tr(policy.title_key())).override_failure_message(policy.title_key()).is_not_equal(policy.title_key())
		assert_str(tr(policy.description_key())).is_not_equal(policy.description_key())
	assert_str(tr(hall.name_key)).is_not_equal(hall.name_key)
	assert_bool(Icons.has("building_town_hall")).is_true()


func test_policy_reach_and_upkeep() -> void:
	var sim := _sim()
	var near := SimFixture.house(sim, 30, STREET, &"peasants", 5.0)
	var far := SimFixture.house(sim, 110, STREET, &"peasants", 5.0)
	var hall := _hall(sim, 20)
	var before := sim.derived_state().upkeep_per_min
	assert_bool(sim.execute(SetPolicyCommand.new(hall, &"holidays")).ok()).is_true()
	var derived := sim.derived_state()
	var reach: Array = derived.policy_reach[hall]
	assert_bool(reach.has(near)).is_true()
	assert_bool(reach.has(far)).is_false()
	assert_float(derived.policy_happiness.get(near, 0.0)).is_equal(8.0)
	assert_float(derived.policy_happiness.get(far, 0.0)).is_equal(0.0)
	assert_float(derived.upkeep_per_min - before).is_equal_approx(sim.data.policy(&"holidays").upkeep_per_min, 0.001)
	# sem política, sem efeito e sem a manutenção dela
	assert_bool(sim.execute(SetPolicyCommand.new(hall, &"")).ok()).is_true()
	assert_bool(sim.derived_state().policy_happiness.is_empty()).is_true()
	assert_float(sim.derived_state().upkeep_per_min).is_equal_approx(before, 0.001)


func test_the_same_policy_does_not_stack_but_different_ones_do() -> void:
	var sim := _sim()
	var house := SimFixture.house(sim, 30, STREET, &"peasants", 5.0)
	_hall(sim, 20, &"fire_watch")
	_hall(sim, 40, &"fire_watch")
	var derived := sim.derived_state()
	assert_float(derived.policy_fire[house]).is_equal_approx(0.4, 0.0001)
	_hall(sim, 50, &"holidays")
	derived = sim.derived_state()
	assert_float(derived.policy_fire[house]).is_equal_approx(0.4, 0.0001)
	assert_float(derived.policy_happiness[house]).is_equal(8.0)


func test_holidays_raise_happiness_and_tax_office_raises_tax() -> void:
	var happiness := PackedFloat32Array()
	for policy: StringName in [&"", &"holidays"]:
		var sim := _sim()
		var house := SimFixture.house(sim, 30, STREET, &"peasants", 10.0)
		_hall(sim, 20, policy)
		SimFixture.run(sim, 600.0)
		happiness.append(sim.world.building(house).happiness)
	assert_float(happiness[1]).is_greater(happiness[0] + 5.0)
	# o imposto (a casa feliz paga, como no teste dos riscos): a coletoria soma 15%
	var tax := PackedFloat32Array()
	for policy: StringName in [&"", &"tax_office"]:
		var sim := _sim()
		var house := SimFixture.house(sim, 30, STREET, &"peasants", 10.0)
		sim.world.building(house).happiness = 60.0
		_hall(sim, 20, policy)
		SimFixture.run(sim, 4.0)
		tax.append(sim.world.building(house).tax_per_min)
	assert_float(tax[0]).is_greater(0.0)
	assert_float(tax[1] / tax[0]).is_equal_approx(1.15, 0.01)


func test_long_shifts_speed_up_production_nearby() -> void:
	var outputs: Array[float] = []
	for policy: StringName in [&"", &"long_shifts"]:
		var sim := _sim()
		SimFixture.house(sim, 60, STREET, &"peasants", 10.0)
		var lumberjack := SimFixture.place(sim, &"lumberjack", Vector2i(30, STREET + 1), 0)
		_hall(sim, 20, policy)
		var derived := sim.derived_state()
		if policy != &"":
			assert_float(derived.policy_speed.get(lumberjack, 0.0)).is_equal_approx(0.15, 0.0001)
		outputs.append(derived.policy_speed.get(lumberjack, 0.0))
	assert_float(outputs[1]).is_greater(outputs[0])


func test_no_road_no_policy() -> void:
	var sim := SimFixture.simulation()
	sim.free_build = true
	var house := SimFixture.house(sim, 30, STREET, &"peasants", 5.0)
	var hall := SimFixture.place(sim, &"town_hall", Vector2i(10, 2), 0)
	sim.execute(SetPolicyCommand.new(hall, &"holidays"))
	assert_bool(sim.derived_state().policy_happiness.has(house)).is_false()


func test_command_refuses_other_buildings_and_locked_policies() -> void:
	var sim := _sim()
	var house := SimFixture.house(sim, 30, STREET, &"peasants", 5.0)
	var hall := _hall(sim, 20)
	sim.free_build = false
	assert_str(String(sim.execute(SetPolicyCommand.new(house, &"holidays")).reason)).is_equal(String(SetPolicyCommand.NOT_TOWN_HALL))
	assert_str(String(sim.execute(SetPolicyCommand.new(hall, &"no_such_policy")).reason)).is_equal(String(SetPolicyCommand.POLICY_LOCKED))
	# a coletoria pede um marco
	assert_int(sim.world.milestones_reached).is_equal(0)
	assert_str(String(sim.execute(SetPolicyCommand.new(hall, &"tax_office")).reason)).is_equal(String(SetPolicyCommand.POLICY_LOCKED))
	assert_bool(sim.execute(SetPolicyCommand.new(hall, &"long_shifts")).ok()).is_true()


func test_the_policy_goes_in_the_save() -> void:
	var sim := _sim()
	var hall := _hall(sim, 20, &"fire_watch")
	var saved := sim.world.to_dict()
	var loaded := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(loaded).is_not_null()
	assert_str(String(loaded.building(hall).policy)).is_equal("fire_watch")
	# política desconhecida, ou numa casa, recusa o save
	var buildings: Array = saved["buildings"]
	for raw: Dictionary in buildings:
		if raw["id"] == hall:
			raw["policy"] = &"no_such_policy"
	assert_object(WorldState.from_dict(saved, sim.data, sim.config)).is_null()
