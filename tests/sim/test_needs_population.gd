extends GdUnitTestSuite
## Consumo por morador, divisão entre opções, cobertura de serviço por estrada, casa que enche
## e esvazia, upgrade, felicidade e imposto.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40), 1000)
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))


func _peasant_village(houses: int) -> Array[int]:
	var ids: Array[int] = []
	for i: int in houses:
		ids.append(SimFixture.house(_sim, 2 + i * 3, 20, &"peasants", 10.0))
	SimFixture.place(_sim, &"market", Vector2i(14, 21))
	return ids


func test_consumption_per_resident_comes_from_the_spec() -> void:
	_peasant_village(10)
	SimFixture.warm_supply(_sim)
	SimFixture.give(_sim, &"fish", 100.0)
	SimFixture.give(_sim, &"woolen_clothes", 100.0)
	SimFixture.run(_sim, 600.0)
	assert_float(SimFixture.residents(_sim)).is_equal(100.0)
	assert_float(100.0 - SimFixture.stock(_sim, &"fish")).is_equal_approx(100 * 0.005 * 10, 0.01)
	assert_float(100.0 - SimFixture.stock(_sim, &"woolen_clothes")).is_equal_approx(100 * 0.004 * 10, 0.01)


func test_options_of_a_category_split_the_consumption() -> void:
	for i: int in 5:
		SimFixture.house(_sim, 2 + i * 3, 20, &"workers", 20.0)
	SimFixture.give(_sim, &"fish", 100.0)
	SimFixture.give(_sim, &"bread", 100.0)
	var people_before := SimFixture.residents(_sim)
	SimFixture.run(_sim, 60.0)
	# a casa de operário sem as outras necessidades perde gente em linha reta: vale a média
	var people := (people_before + SimFixture.residents(_sim)) / 2.0
	assert_float(100.0 - SimFixture.stock(_sim, &"fish")).is_equal_approx(people * 0.005 / 2.0, 0.01)
	assert_float(100.0 - SimFixture.stock(_sim, &"bread")).is_equal_approx(people * 0.004 / 2.0, 0.01)


func test_service_covers_by_road_distance_not_straight_line() -> void:
	var near := SimFixture.house(_sim, 30, 20, &"peasants", 0.0)
	var far := SimFixture.house(_sim, 70, 20, &"peasants", 0.0)
	var market := SimFixture.place(_sim, &"market", Vector2i(40, 21))
	var derived := _sim.derived_state()
	assert_bool(derived.covered_by(near, &"market")).is_true()
	assert_bool(derived.covered_by(far, &"market")).is_false()
	assert_array(derived.service_houses[market]).contains([near])


func test_house_without_road_link_is_not_covered() -> void:
	SimFixture.place(_sim, &"market", Vector2i(40, 21))
	var isolated := SimFixture.place(_sim, &"house", Vector2i(42, 30), 0)
	assert_bool(_sim.derived_state().covered_by(isolated, &"market")).is_false()


func test_house_fills_up_when_needs_are_met() -> void:
	var houses := _peasant_village(1)
	_sim.world.building(houses[0]).residents = 0.0
	SimFixture.warm_supply(_sim)
	SimFixture.give(_sim, &"fish", 50.0)
	SimFixture.give(_sim, &"woolen_clothes", 50.0)
	SimFixture.run(_sim, 180.0)
	assert_float(_sim.world.building(houses[0]).residents).is_equal(10.0)


func test_without_needs_a_house_keeps_only_the_base() -> void:
	var house := SimFixture.house(_sim, 60, 20, &"peasants", 0.0)
	SimFixture.run(_sim, 300.0)
	assert_float(_sim.world.building(house).residents).is_equal_approx(10.0 * _sim.config.house_base_residents_fraction, 0.01)


func test_shortage_removes_one_resident_per_minute() -> void:
	var houses := _peasant_village(1)
	SimFixture.warm_supply(_sim)
	SimFixture.give(_sim, &"fish", 50.0)
	SimFixture.give(_sim, &"woolen_clothes", 50.0)
	SimFixture.run(_sim, 120.0)
	assert_float(_sim.world.building(houses[0]).residents).is_equal(10.0)
	SimFixture.give(_sim, &"fish", 0.0)
	SimFixture.give(_sim, &"woolen_clothes", 0.0)
	SimFixture.run(_sim, 60.0)
	var after_one_minute := _sim.world.building(houses[0]).residents
	SimFixture.run(_sim, 120.0)
	assert_float(after_one_minute).is_less(10.0)
	assert_float(after_one_minute - _sim.world.building(houses[0]).residents).is_equal_approx(2.0, 0.01)


func test_shortage_is_announced_once() -> void:
	_peasant_village(2)
	var announced: Array[StringName] = []
	var listener := func(_island: int, good: StringName) -> void: announced.append(good)
	EventBus.good_shortage.connect(listener)
	SimFixture.run(_sim, 120.0)
	EventBus.good_shortage.disconnect(listener)
	assert_array(announced).contains_exactly_in_any_order([&"fish", &"woolen_clothes"])


func test_full_house_with_all_needs_upgrades_with_planks() -> void:
	var houses := _peasant_village(3)
	SimFixture.warm_supply(_sim)
	_sim.execute(SetUpgradeBlockedCommand.new(houses[2], true))
	SimFixture.give(_sim, &"fish", 100.0)
	SimFixture.give(_sim, &"woolen_clothes", 100.0)
	SimFixture.give(_sim, &"planks", 3.0)
	var upgraded: Array[int] = []
	var listener := func(building_id: int) -> void: upgraded.append(building_id)
	EventBus.house_upgraded.connect(listener)
	SimFixture.run(_sim, 120.0)
	EventBus.house_upgraded.disconnect(listener)
	assert_array(upgraded).is_equal([houses[0]])
	assert_str(_sim.world.building(houses[0]).tier).is_equal(&"workers")
	assert_str(_sim.world.building(houses[1]).tier).is_equal(&"peasants")
	assert_str(_sim.world.building(houses[2]).tier).is_equal(&"peasants")
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(1.0)


## Peixe em 95% conta como atendido, mas a casa não enche: sobe assim mesmo, com os moradores que
## o atendimento permite (antes travava para sempre).
func test_house_upgrades_with_a_need_met_below_full_supply() -> void:
	var houses := _peasant_village(1)
	_sim.world.building(houses[0]).residents = 2.0
	SimFixture.warm_supply(_sim)
	SimFixture.give(_sim, &"woolen_clothes", 100.0)
	SimFixture.give(_sim, &"planks", 2.0)
	var economy := _sim.world.economy(SimFixture.ISLAND)
	var upgraded: Array[int] = []
	var residents_at_upgrade: Array[float] = []
	var listener := func(building_id: int) -> void:
		upgraded.append(building_id)
		residents_at_upgrade.append(_sim.world.building(building_id).residents)
	EventBus.house_upgraded.connect(listener)
	for i: int in 240:
		# só 95% do peixe que os moradores pedem chega a cada segundo
		var house := _sim.world.building(houses[0])
		if house.tier == &"peasants":
			economy.stock[&"fish"] = house.residents * 0.005 / 60.0 * 0.95
		SimFixture.run(_sim, 1.0)
	EventBus.house_upgraded.disconnect(listener)
	assert_array(upgraded).is_equal([houses[0]])
	assert_float(residents_at_upgrade[0]).is_less(10.0)


func test_house_below_what_its_supply_allows_does_not_upgrade() -> void:
	var houses := _peasant_village(1)
	_sim.world.building(houses[0]).residents = 5.0
	SimFixture.warm_supply(_sim)
	SimFixture.give(_sim, &"fish", 100.0)
	SimFixture.give(_sim, &"woolen_clothes", 100.0)
	SimFixture.give(_sim, &"planks", 2.0)
	SimFixture.run(_sim, 30.0)
	assert_str(_sim.world.building(houses[0]).tier).is_equal(&"peasants")
	assert_float(_sim.world.building(houses[0]).residents).is_less(10.0)


func test_luxury_raises_happiness_and_tax() -> void:
	var houses := _peasant_village(1)
	SimFixture.give(_sim, &"fish", 100.0)
	SimFixture.give(_sim, &"woolen_clothes", 100.0)
	SimFixture.run(_sim, 300.0)
	var plain := _sim.world.building(houses[0]).happiness
	var plain_tax := _sim.world.income_per_min
	SimFixture.give(_sim, &"spirits", 100.0)
	SimFixture.place(_sim, &"tavern", Vector2i(50, 21))
	SimFixture.run(_sim, 300.0)
	assert_float(_sim.world.building(houses[0]).happiness).is_greater(plain)
	assert_float(_sim.world.income_per_min).is_greater(plain_tax)


func test_tax_follows_the_spec_formula() -> void:
	var houses := _peasant_village(1)
	var house := _sim.world.building(houses[0])
	house.happiness = 50.0
	var tax := HouseNeeds.tax_per_min(_sim.world, _sim.data, _sim.config, _sim.derived_state(), house)
	assert_float(tax).is_equal_approx(10.0 * 0.6 * 1.0 * 1.0, 0.0001)
	house.happiness = 100.0
	_sim.execute(SetTaxLevelCommand.new(&"peasants", WorldState.TaxLevel.HIGH))
	tax = HouseNeeds.tax_per_min(_sim.world, _sim.data, _sim.config, _sim.derived_state(), house)
	assert_float(tax).is_equal_approx(10.0 * 0.6 * 1.4 * 1.5, 0.0001)


func test_unhappy_house_protests_and_pays_nothing() -> void:
	var houses := _peasant_village(1)
	var house := _sim.world.building(houses[0])
	house.happiness = 15.0
	assert_float(HouseNeeds.tax_per_min(_sim.world, _sim.data, _sim.config, _sim.derived_state(), house)).is_equal(0.0)


func test_second_option_in_a_category_gives_tax_bonus() -> void:
	for i: int in 2:
		SimFixture.house(_sim, 2 + i * 3, 20, &"workers", 20.0)
	SimFixture.give(_sim, &"fish", 100.0)
	SimFixture.run(_sim, 120.0)
	var house := _sim.world.building(_sim.derived_state().houses[0])
	var one := HouseNeeds.bonus_categories(_sim.world, _sim.derived_state(), _sim.config, house, _sim.data.tier(&"workers"))
	SimFixture.give(_sim, &"bread", 100.0)
	SimFixture.run(_sim, 120.0)
	var two := HouseNeeds.bonus_categories(_sim.world, _sim.derived_state(), _sim.config, house, _sim.data.tier(&"workers"))
	assert_int(two).is_equal(one + 1)


func test_pollution_lowers_happiness_of_houses_near_brickworks() -> void:
	var near := SimFixture.house(_sim, 10, 20, &"workers", 10.0)
	var far := SimFixture.house(_sim, 90, 20, &"workers", 10.0)
	SimFixture.place(_sim, &"brickworks", Vector2i(14, 21))
	var derived := _sim.derived_state()
	assert_float(derived.pollution[near]).is_greater(0.0)
	assert_float(derived.pollution[far]).is_equal(0.0)
	SimFixture.run(_sim, 300.0)
	assert_float(_sim.world.building(near).happiness).is_less(_sim.world.building(far).happiness)
