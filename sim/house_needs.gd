class_name HouseNeeds
extends RefCounted
## Leitura das necessidades de uma casa, usada pela população, pela economia e pelo painel.
## Categoria de bem: a média de atendimento da classe na ilha. Categoria de serviço: 1 se
## algum serviço dela cobre a casa. As duas juntas valem o maior.
##
## A parte de bens é igual para todas as casas da mesma classe na ilha: TierSupply a calcula
## uma vez por tick, e evaluate() só soma a cobertura de serviço de cada casa.


class TierSupply:
	var tier: TierDef
	## Necessidades básicas e depois as de luxo.
	var needs: Array[NeedCategoryDef] = []
	var basic_count: int = 0
	## Atendimento da parte de bens de cada necessidade (0 se ela não tem bem).
	var goods_value: PackedFloat64Array = PackedFloat64Array()
	## Bens da necessidade em uso (com estoque e atendimento acima do limite).
	var goods_active: PackedInt32Array = PackedInt32Array()


## O que a casa tem agora: média das básicas, se todas estão atendidas, soma do luxo e
## quantas categorias têm duas opções ou mais (bônus de imposto).
class Evaluation:
	## Atendimento de cada necessidade (básicas e depois luxo); só preenchido para o painel.
	var values: PackedFloat64Array = PackedFloat64Array()
	var basic_average: float = 1.0
	var all_basic_met: bool = true
	var luxury_total: float = 0.0
	var bonus_categories: int = 0


static func tier_supply(economy: IslandEconomy, config: GameConfig, tier: TierDef) -> TierSupply:
	var supply := TierSupply.new()
	supply.tier = tier
	supply.needs.append_array(tier.basic_needs)
	supply.needs.append_array(tier.luxury_needs)
	supply.basic_count = tier.basic_needs.size()
	supply.goods_value.resize(supply.needs.size())
	supply.goods_active.resize(supply.needs.size())
	for index: int in supply.needs.size():
		var need := supply.needs[index]
		if need.goods.is_empty():
			continue
		supply.goods_value[index] = economy.supply_of(tier.id, need.id)
		var active := 0
		for good: StringName in need.goods:
			var ratio: float = economy.good_supply.get(good, 0.0)
			if economy.amount(good) > 0.000001 and ratio >= config.need_met_threshold:
				active += 1
		supply.goods_active[index] = active
	return supply


static func evaluate(derived: DerivedState, config: GameConfig, house_id: int, supply: TierSupply, with_values: bool = false) -> Evaluation:
	var result := Evaluation.new()
	var covering: Array = derived.coverage.get(house_id, [])
	if with_values:
		result.values.resize(supply.needs.size())
	var basic_total := 0.0
	for index: int in supply.needs.size():
		var need := supply.needs[index]
		var value := supply.goods_value[index]
		var options := supply.goods_active[index]
		if not covering.is_empty():
			for service: StringName in need.services:
				if covering.has(service):
					value = 1.0
					options += 1
		if with_values:
			result.values[index] = value
		if options >= 2:
			result.bonus_categories += 1
		if index < supply.basic_count:
			basic_total += value
			if value < config.need_met_threshold:
				result.all_basic_met = false
		else:
			result.luxury_total += value
	if supply.basic_count > 0:
		result.basic_average = basic_total / supply.basic_count
	return result


## Imposto em moedas por minuto. Abaixo do limite de felicidade, a casa protesta e não paga.
static func tax_from(world: WorldState, config: GameConfig, house: BuildingRecord, tier: TierDef, bonus_categories: int) -> float:
	if house.happiness < config.protest_happiness_threshold:
		return 0.0
	var level_multiplier := config.tax_level_multipliers[world.tax_level(house.tier)]
	var happiness_multiplier := lerpf(config.happiness_tax_multiplier_min, config.happiness_tax_multiplier_max, house.happiness / 100.0)
	var bonus := 1.0 + config.extra_need_option_tax_bonus * bonus_categories
	return house.residents * tier.tax_per_resident_min * level_multiplier * happiness_multiplier * bonus


## Avaliação de uma casa só, para o painel e os testes.
static func evaluate_house(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, house: BuildingRecord) -> Evaluation:
	var tier := data.tier(house.tier)
	return evaluate(derived, config, house.id, tier_supply(world.economy(house.island_id), config, tier), true)


static func satisfaction(world: WorldState, derived: DerivedState, house: BuildingRecord, need: NeedCategoryDef) -> float:
	var value := 0.0
	if not need.goods.is_empty():
		value = world.economy(house.island_id).supply_of(house.tier, need.id)
	var covering: Array = derived.coverage.get(house.id, [])
	for service: StringName in need.services:
		if covering.has(service):
			return 1.0
	return value


static func bonus_categories(world: WorldState, derived: DerivedState, config: GameConfig, house: BuildingRecord, tier: TierDef) -> int:
	return evaluate(derived, config, house.id, tier_supply(world.economy(house.island_id), config, tier)).bonus_categories


static func max_residents(tier: TierDef) -> int:
	return tier.residents_per_house


static func tax_per_min(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, house: BuildingRecord) -> float:
	var evaluation := evaluate_house(world, data, config, derived, house)
	return tax_from(world, config, house, data.tier(house.tier), evaluation.bonus_categories)
