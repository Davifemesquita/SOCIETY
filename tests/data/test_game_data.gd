extends GdUnitTestSuite
## As definições carregam, são consistentes, têm tradução e seguem as tabelas da especificação
## (seções 4 e 5): proporções das cadeias e consumo por morador.

var _data: GameData


func before_test() -> void:
	_data = GameData.get_default()


func test_data_loads_and_is_valid() -> void:
	assert_array(Array(_data.validate())).is_empty()
	assert_int(_data.goods.size()).is_equal(23)
	assert_int(_data.tiers.size()).is_equal(2)
	assert_int(_data.buildings.size()).is_equal(33)
	assert_int(_data.ships.size()).is_equal(2)
	assert_object(_data.trader()).is_not_null()


func test_every_name_is_translated() -> void:
	var keys: Array[String] = []
	for def: BuildingDef in _data.buildings:
		keys.append(def.name_key)
	for def: GoodDef in _data.goods:
		keys.append(def.name_key)
	for def: ShipDef in _data.ships:
		keys.append(def.name_key)
	keys.append(_data.trader().name_key)
	for tier: TierDef in _data.tiers:
		keys.append(tier.name_key)
		for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
			keys.append(need.name_key)
	for key: String in keys:
		assert_str(TranslationServer.translate(key)).override_failure_message("sem tradução: " + key).is_not_equal(key)


## Produtores × t/min de cada = consumidores × t/min que cada um pede (1 t por ciclo).
func _assert_balanced(producer: StringName, producers: int, consumer: StringName, consumers: int) -> void:
	var made := producers * _data.building(producer).output_per_min()
	var used := consumers * _data.building(consumer).output_per_min()
	assert_float(made).override_failure_message("%s:%s fora de %d:%d" % [producer, consumer, producers, consumers]).is_equal_approx(used, 0.0001)


func test_chain_proportions_from_the_spec() -> void:
	_assert_balanced(&"lumberjack", 1, &"sawmill", 1)
	_assert_balanced(&"sheep_farm", 1, &"weavery", 1)
	_assert_balanced(&"potato_farm", 2, &"distillery", 1)
	_assert_balanced(&"wheat_farm", 2, &"mill", 1)
	_assert_balanced(&"mill", 1, &"bakery", 2)
	_assert_balanced(&"pig_farm", 1, &"butcher", 1)
	_assert_balanced(&"pig_farm", 2, &"rendering_works", 2)
	_assert_balanced(&"rendering_works", 2, &"soap_factory", 1)
	_assert_balanced(&"wheat_farm", 2, &"malthouse", 1)
	_assert_balanced(&"malthouse", 1, &"brewery", 2)
	_assert_balanced(&"hop_farm", 3, &"brewery", 2)
	_assert_balanced(&"clay_pit", 1, &"brickworks", 2)
	_assert_balanced(&"iron_mine", 2, &"furnace", 4)
	_assert_balanced(&"coal_mine", 2, &"furnace", 4)
	_assert_balanced(&"furnace", 4, &"steel_beam_works", 3)


func test_one_building_supplies_the_spec_population() -> void:
	var expected: Dictionary[StringName, float] = {&"fish": 400, &"woolen_clothes": 500, &"spirits": 600, &"bread": 250,
			&"sausages": 250, &"soap": 1000, &"beer": 500}
	var producer_of: Dictionary[StringName, StringName] = {&"fish": &"fishery", &"woolen_clothes": &"weavery",
			&"spirits": &"distillery", &"bread": &"bakery", &"sausages": &"butcher", &"soap": &"soap_factory", &"beer": &"brewery"}
	for good: StringName in expected:
		var producer: StringName = producer_of[good]
		var rate := _data.building(producer).output_per_min()
		var people := rate / _data.good(good).consumption_per_resident_t_min
		var wanted: float = expected[good]
		assert_float(people).override_failure_message(str(good)).is_equal_approx(wanted, 7.0)


func test_tiers_follow_the_spec_table() -> void:
	var peasants := _data.tier(&"peasants")
	var workers := _data.tier(&"workers")
	assert_int(peasants.residents_per_house).is_equal(10)
	assert_float(peasants.tax_per_resident_min).is_equal(0.6)
	assert_int(workers.residents_per_house).is_equal(20)
	assert_float(workers.tax_per_resident_min).is_equal(1.2)
	assert_dict(workers.upgrade_materials).is_equal({&"planks": 2})
	assert_object(_data.next_tier(&"peasants")).is_same(workers)
	assert_object(_data.next_tier(&"workers")).is_null()


func test_workforce_follows_the_spec_table() -> void:
	assert_str(_data.building(&"bakery").workforce_tier).is_equal(&"workers")
	assert_int(_data.building(&"bakery").workers).is_equal(50)
	assert_str(_data.building(&"mill").workforce_tier).is_equal(&"peasants")
	assert_int(_data.building(&"steel_beam_works").workers).is_equal(125)
	assert_int(_data.building(&"brickworks").unlock_residents).is_equal(150)


func test_broken_references_are_reported() -> void:
	var broken := GameData.new()
	var def := BuildingDef.new()
	def.id = &"x"
	def.name_key = "X"
	def.output = &"nao_existe"
	def.workforce_tier = &"ninguem"
	broken.buildings = [def, def]
	var problems := broken.validate()
	assert_bool(problems.size() >= 3).is_true()
