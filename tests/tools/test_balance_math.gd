extends GdUnitTestSuite
## Contas de balanceamento (Fase 27): a manutenção da cadeia por tonelada e por morador, como a planilha a mostra.


func test_the_chain_upkeep_adds_every_step_per_ton() -> void:
	var data := GameData.get_default()
	# pão: padaria 60/min a 1 t/min, moinho 30/min a 2 t/min e trigo 20/min a 1 t/min (seção 4)
	assert_float(BalanceMath.upkeep_per_ton(data, &"bread")).is_equal_approx(60.0 + 15.0 + 20.0, 0.01)
	# bem sem produtor fica de graça
	assert_float(BalanceMath.upkeep_per_ton(data, &"no_such_good")).is_equal(0.0)


func test_each_class_pays_its_basic_chain_with_room_to_spare() -> void:
	var data := GameData.get_default()
	# o consumo se divide entre os bens da categoria: o alimento dos operários é um terço de peixe, de pão e de
	# salsicha
	var workers := data.tier(&"workers")
	var food: NeedCategoryDef = null
	for need: NeedCategoryDef in workers.basic_needs:
		if need.id == &"food":
			food = need
	var only_food: Array[NeedCategoryDef] = [food]
	var expected := 0.0
	for good: StringName in food.goods:
		expected += data.good(good).consumption_per_resident_t_min / food.goods.size() * BalanceMath.upkeep_per_ton(data, good)
	assert_float(BalanceMath.needs_upkeep_per_resident(data, only_food)).is_equal_approx(expected, 0.0001)
	# toda classe paga a cadeia das necessidades básicas e o luxo com o imposto dela, com folga
	for tier: TierDef in data.tiers:
		var chain := BalanceMath.needs_upkeep_per_resident(data, tier.basic_needs) \
				+ BalanceMath.needs_upkeep_per_resident(data, tier.luxury_needs)
		assert_float(tier.tax_per_resident_min / chain).override_failure_message(String(tier.id)).is_greater(1.3)
