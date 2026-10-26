extends GdUnitTestSuite
## O "porquê" dos números (Fase 47): a decomposição de cada bem e do dinheiro, só leitura e montada sob demanda, soma
## exatamente o que a tela mostra (produção menos consumo da linha das estatísticas; receita menos manutenção) e não
## mexe no estado da simulação.

var _sim: Simulation
var _bakeries: Array[int] = []


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(140, 40), 100000)
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(139, 20))
	SimFixture.farm(_sim, &"wheat_farm", 8, 20)
	SimFixture.farm(_sim, &"wheat_farm", 34, 20)
	SimFixture.place(_sim, &"mill", Vector2i(60, 21))
	_bakeries = [SimFixture.place(_sim, &"bakery", Vector2i(66, 21)), SimFixture.place(_sim, &"bakery", Vector2i(72, 21))]
	for i: int in 3:
		SimFixture.house(_sim, 80 + i * 3, 20, &"peasants", 10.0)
	for i: int in 5:
		SimFixture.house(_sim, 95 + i * 3, 20, &"workers", 20.0)
	SimFixture.give(_sim, &"fish", 200.0)
	SimFixture.run_production(_sim, 300.0)


func _sum(good: StringName, island_id: int = SimFixture.ISLAND) -> float:
	return Breakdown.total(Breakdown.good(_sim.world, _sim.data, _sim.derived_state(), island_id, good))


func test_each_good_adds_up_to_the_statistics_line() -> void:
	var report := _sim.statistics()
	for line: Statistics.GoodLine in report.goods:
		assert_float(_sum(line.good)).override_failure_message(str(line.good)) \
				.is_equal_approx(line.produced - line.consumed(), 0.000001)
	# o trigo: duas fazendas fazem, o moinho gasta
	var wheat := Breakdown.good(_sim.world, _sim.data, _sim.derived_state(), SimFixture.ISLAND, &"wheat")
	assert_int(wheat.size()).is_equal(2)
	assert_int(wheat[0].kind).is_equal(Breakdown.Kind.BUILDING)
	assert_str(wheat[0].id).is_equal("wheat_farm")
	assert_int(wheat[0].count).is_equal(2)
	assert_float(wheat[0].per_min).is_greater(0.0)
	assert_str(wheat[1].id).is_equal("mill")
	assert_float(wheat[1].per_min).is_less(0.0)


func test_house_consumption_is_split_by_tier() -> void:
	# o consumo das casas é média de 20 s: a simulação inteira por 2 min (run_production não passa pelas necessidades)
	SimFixture.run(_sim, 120.0)
	var fish := Breakdown.good(_sim.world, _sim.data, _sim.derived_state(), SimFixture.ISLAND, &"fish")
	var tiers: Array[StringName] = []
	var by_tier := 0.0
	for source: Breakdown.Source in fish:
		if source.kind == Breakdown.Kind.TIER:
			tiers.append(source.id)
			by_tier += source.per_min
	assert_array(tiers).contains_exactly_in_any_order([&"peasants", &"workers"])
	var houses: float = _sim.world.economy(SimFixture.ISLAND).needs_consumption_per_min.get(&"fish", 0.0)
	assert_float(houses).is_greater(0.0)
	assert_float(-by_tier).is_equal_approx(houses, 0.000001)
	# 100 operários comem mais que 30 camponeses (o mesmo peixe por morador)
	assert_float(absf(fish[0].per_min)).is_greater(absf(fish[1].per_min))
	assert_str(fish[0].id).is_equal("workers")


func test_all_islands_is_the_sum_of_each() -> void:
	for good: StringName in [&"wheat", &"flour", &"bread", &"fish"]:
		var each := 0.0
		for island_id: int in _sim.world.islands.size():
			each += _sum(good, island_id)
		assert_float(_sum(good, -1)).is_equal_approx(each, 0.000001)


func test_money_adds_up_to_income_minus_upkeep() -> void:
	_sim.execute(SetPausedCommand.new(_bakeries[1], true))
	SimFixture.run(_sim, 30.0)
	var world := _sim.world
	var sources := Breakdown.money(world, _sim.data, _sim.config, _sim.derived_state())
	assert_float(Breakdown.total(sources)).is_equal_approx(world.income_per_min - world.upkeep_per_min, 0.000001)
	var income := 0.0
	var bakery := 0.0
	for source: Breakdown.Source in sources:
		if source.per_min > 0.0:
			income += source.per_min
		if source.id == &"bakery":
			bakery = source.per_min
	assert_float(income).is_equal_approx(world.income_per_min, 0.000001)
	# uma padaria pausada paga a fração de pausa: as duas juntas pagam 1 + fator
	var upkeep := float(_sim.data.building(&"bakery").upkeep_per_min)
	assert_float(-bakery).is_equal_approx(upkeep * (1.0 + _sim.config.paused_upkeep_factor), 0.000001)


func test_ships_and_an_empty_island_still_add_up() -> void:
	SimFixture.port(_sim)
	SimFixture.ship(_sim)
	SimFixture.run(_sim, 5.0)
	var world := _sim.world
	var sources := Breakdown.money(world, _sim.data, _sim.config, _sim.derived_state())
	assert_float(Breakdown.total(sources)).is_equal_approx(world.income_per_min - world.upkeep_per_min, 0.000001)
	assert_bool(sources.any(func(source: Breakdown.Source) -> bool: return source.kind == Breakdown.Kind.SHIPS)).is_true()
	# um bem que ninguém faz nem usa: nenhuma parcela, soma zero
	assert_array(Breakdown.good(world, _sim.data, _sim.derived_state(), SimFixture.ISLAND, &"jewelry")).is_empty()


func test_reading_does_not_touch_the_simulation() -> void:
	var before := var_to_str(_sim.world.to_dict())
	for good_def: GoodDef in _sim.data.goods:
		Breakdown.good(_sim.world, _sim.data, _sim.derived_state(), -1, good_def.id)
	Breakdown.money(_sim.world, _sim.data, _sim.config, _sim.derived_state())
	assert_str(var_to_str(_sim.world.to_dict())).is_equal(before)
