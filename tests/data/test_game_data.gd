extends GdUnitTestSuite
## As definições carregam, são consistentes, têm tradução e seguem as tabelas da especificação
## (seções 4 e 5): proporções das cadeias e consumo por morador.

var _data: GameData


func before_test() -> void:
	_data = GameData.get_default()


func test_data_loads_and_is_valid() -> void:
	assert_array(Array(_data.validate())).is_empty()
	assert_int(_data.goods.size()).is_equal(41)
	assert_int(_data.tiers.size()).is_equal(5)
	assert_int(_data.buildings.size()).is_equal(61)
	assert_int(_data.ships.size()).is_equal(4)
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


## Cadeias da Fase 8 (números nossos; a especificação só sugere os bens).
func test_upper_chain_proportions() -> void:
	_assert_balanced(&"sand_pit", 1, &"glassworks", 2)
	_assert_balanced(&"coal_mine", 1, &"glassworks", 2)
	_assert_balanced(&"glassworks", 1, &"window_works", 1)
	_assert_balanced(&"furnace", 1, &"sewing_machine_factory", 1)
	_assert_balanced(&"fishery", 1, &"cannery", 2)
	_assert_balanced(&"glassworks", 1, &"lamp_factory", 1)
	_assert_balanced(&"glassworks", 2, &"clockmaker", 3)
	_assert_balanced(&"vineyard", 3, &"champagne_cellar", 2)
	_assert_balanced(&"rum_distillery", 1, &"coffee_roaster", 1)


func test_one_building_supplies_the_spec_population() -> void:
	var expected: Dictionary[StringName, float] = {&"fish": 400, &"woolen_clothes": 500, &"spirits": 600, &"bread": 250,
			&"sausages": 250, &"soap": 1000, &"beer": 500,
			# Fase 8 (números nossos)
			&"canned_food": 400, &"sewing_machines": 500, &"rum": 800, &"coffee": 667, &"light_bulbs": 667,
			&"clocks": 667, &"glasses": 1000, &"champagne": 500, &"cigars": 500, &"jewelry": 667}
	var producer_of: Dictionary[StringName, StringName] = {&"fish": &"fishery", &"woolen_clothes": &"weavery",
			&"spirits": &"distillery", &"bread": &"bakery", &"sausages": &"butcher", &"soap": &"soap_factory", &"beer": &"brewery",
			&"canned_food": &"cannery", &"sewing_machines": &"sewing_machine_factory", &"rum": &"rum_distillery",
			&"coffee": &"coffee_roaster", &"light_bulbs": &"lamp_factory", &"clocks": &"clockmaker", &"glasses": &"optician",
			&"champagne": &"champagne_cellar", &"cigars": &"cigar_factory", &"jewelry": &"goldsmith"}
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
	assert_object(_data.next_tier(&"workers")).is_same(_data.tier(&"artisans"))


## Fase 8: as três classes de cima (seção 4) e a ordem do upgrade até a quinta.
func test_upper_tiers_follow_the_spec_table() -> void:
	var expected := {
		&"artisans": [30, 2.4, {&"bricks": 2, &"planks": 1}],
		&"engineers": [40, 4.0, {&"bricks": 2, &"steel_beams": 2}],
		&"investors": [50, 7.0, {&"steel_beams": 2, &"windows": 2}],
	}
	for tier_id: StringName in expected:
		var row: Array = expected[tier_id]
		var residents: int = row[0]
		var tax: float = row[1]
		var materials: Dictionary = row[2]
		var tier := _data.tier(tier_id)
		assert_int(tier.residents_per_house).is_equal(residents)
		assert_float(tier.tax_per_resident_min).is_equal_approx(tax, 0.0001)
		assert_dict(tier.upgrade_materials).is_equal(materials)
	var order: Array[StringName] = []
	for tier: TierDef in _data.tiers:
		order.append(tier.id)
	assert_array(order).is_equal([&"peasants", &"workers", &"artisans", &"engineers", &"investors"])
	assert_object(_data.next_tier(&"investors")).is_null()


## Nenhuma necessidade básica de quem ainda sobe de classe depende de bem importado ou tropical:
## chegar à quinta classe nunca pede o comerciante nem as ilhas tropicais (Fase 11), que ficam no
## luxo e nos investidores.
func test_climbing_never_depends_on_imports() -> void:
	for tier: TierDef in _data.tiers:
		if _data.next_tier(tier.id) == null:
			continue
		for need: NeedCategoryDef in tier.basic_needs:
			var local := not need.services.is_empty()
			for good: StringName in need.goods:
				local = local or _is_made_locally(good)
			assert_bool(local).override_failure_message("%s/%s só se atende com importado ou tropical" % [tier.id, need.id]).is_true()


## O bem sai de uma cadeia que começa no terreno de uma ilha temperada.
func _is_made_locally(good: StringName, depth: int = 0) -> bool:
	if depth > 8:
		return false
	for def: BuildingDef in _data.buildings:
		if def.is_production() and def.output == good and _temperate_terrain(def):
			var all_local := true
			for input: StringName in def.inputs:
				if not _is_made_locally(input, depth + 1):
					all_local = false
			if all_local:
				return true
	return false


## O prédio cabe numa ilha temperada (a fertilidade ou a jazida dele existe numa delas).
func _temperate_terrain(def: BuildingDef) -> bool:
	if def.fertility == &"" and def.deposit == &"":
		return true
	for profile: IslandProfileDef in _data.island_profiles:
		if profile.is_tropical():
			continue
		if (def.fertility == &"" or profile.fertilities.has(def.fertility)) and (def.deposit == &"" or profile.deposits.has(def.deposit)):
			return true
	return false


## Fase 11: cana, café, tabaco e ouro só crescem nas ilhas tropicais, cada um em pelo menos uma
## delas, e as cadeias novas fecham com as fábricas da Fase 8.
func test_tropical_goods_grow_only_in_the_tropics() -> void:
	var tropical_goods: Array[StringName] = [&"sugar", &"coffee_beans", &"tobacco", &"gold"]
	for good: StringName in tropical_goods:
		var in_tropics := false
		for profile: IslandProfileDef in _data.island_profiles:
			var has := profile.fertilities.has(good) or profile.deposits.has(good)
			if profile.is_tropical():
				in_tropics = in_tropics or has
			else:
				assert_bool(has).override_failure_message("%s na ilha temperada %s" % [good, profile.id]).is_false()
		assert_bool(in_tropics).override_failure_message(str(good)).is_true()
	for profile_id: StringName in GameConfig.get_default().tropical_island_profiles:
		assert_bool(_data.profile(profile_id).is_tropical()).is_true()
	assert_str(_data.building(&"gold_mine").deposit).is_equal(&"gold")
	_assert_balanced(&"sugar_cane_farm", 1, &"rum_distillery", 1)
	_assert_balanced(&"coffee_plantation", 2, &"coffee_roaster", 1)
	_assert_balanced(&"tobacco_plantation", 1, &"cigar_factory", 1)
	_assert_balanced(&"gold_mine", 2, &"goldsmith", 3)
	# a plantação libera junto com a fábrica que a consome
	for pair: Array in [[&"sugar_cane_farm", &"rum_distillery"], [&"coffee_plantation", &"coffee_roaster"],
			[&"tobacco_plantation", &"cigar_factory"], [&"gold_mine", &"goldsmith"]]:
		var producer: StringName = pair[0]
		var consumer: StringName = pair[1]
		assert_str(_data.building(producer).unlock_tier).is_equal(_data.building(consumer).unlock_tier)
		assert_int(_data.building(producer).unlock_residents).is_equal(_data.building(consumer).unlock_residents)


func _is_produced(good: StringName) -> bool:
	for def: BuildingDef in _data.buildings:
		if def.is_production() and def.output == good:
			return true
	return false


## Tudo o que alguém consome ou usa tem quem produza, ou vem do comerciante.
func test_every_good_has_a_source() -> void:
	for good: GoodDef in _data.goods:
		assert_bool(_is_produced(good.id) or _data.trader().sells.has(good.id)) \
				.override_failure_message("sem origem: " + good.id).is_true()


## Cada classe tem os prédios de produção que pedem a mão de obra dela (a aba do menu não fica vazia).
func test_every_tier_works_somewhere() -> void:
	for tier: TierDef in _data.tiers:
		var count := _data.buildings.filter(func(def: BuildingDef) -> bool:
			return def.is_production() and def.workforce_tier == tier.id).size()
		assert_int(count).override_failure_message(str(tier.id)).is_greater(0)


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
