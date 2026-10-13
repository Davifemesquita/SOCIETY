class_name IslandEconomy
extends RefCounted
## Economia de uma ilha: estoque compartilhado e atendimento das necessidades.
## Os campos "runtime" saem dos sistemas a cada tick e não vão para o save.

var profile_id: StringName
## Toneladas por bem no estoque da ilha.
var stock: Dictionary[StringName, float] = {}
## Atendimento médio de cada categoria de necessidade por classe: tier → categoria → 0..1.
var category_supply: Dictionary[StringName, Dictionary] = {}
## Atendimento médio de cada bem de consumo (consumido ÷ pedido), 0..1.
var good_supply: Dictionary[StringName, float] = {}
## Bens já anunciados em falta (para avisar uma vez por queda).
var shortage_announced: Dictionary[StringName, bool] = {}
## Comércio passivo com o comerciante (Fase 6), em toneladas por bem: vende o que passar de
## sell_above e compra até ter buy_up_to. Bem ausente = não negocia.
var sell_above: Dictionary[StringName, int] = {}
var buy_up_to: Dictionary[StringName, int] = {}

# runtime
var workforce_available: Dictionary[StringName, float] = {}
var workforce_demand: Dictionary[StringName, float] = {}
var workforce_factor: Dictionary[StringName, float] = {}
## Consumo das necessidades em t/min (média recente, para as estatísticas).
var needs_consumption_per_min: Dictionary[StringName, float] = {}


func amount(good: StringName) -> float:
	return stock.get(good, 0.0)


func add(good: StringName, tons: float, capacity: float) -> float:
	var accepted := clampf(capacity - amount(good), 0.0, tons)
	stock[good] = amount(good) + accepted
	return accepted


func take(good: StringName, tons: float) -> float:
	var taken := minf(amount(good), tons)
	stock[good] = amount(good) - taken
	return taken


func has_materials(materials: Dictionary[StringName, int]) -> bool:
	for good: StringName in materials:
		if amount(good) + 0.000001 < materials[good]:
			return false
	return true


func supply_of(tier: StringName, category: StringName) -> float:
	var by_category: Dictionary = category_supply.get(tier, {})
	return by_category.get(category, 0.0)


func set_supply(tier: StringName, category: StringName, value: float) -> void:
	if not category_supply.has(tier):
		category_supply[tier] = {}
	category_supply[tier][category] = value


func workforce(tier: StringName) -> float:
	return workforce_factor.get(tier, 1.0)


func to_dict() -> Dictionary:
	return {
		"profile": profile_id,
		"stock": stock.duplicate(),
		"category_supply": category_supply.duplicate(true),
		"good_supply": good_supply.duplicate(),
		"shortage_announced": shortage_announced.duplicate(),
		"sell_above": sell_above.duplicate(),
		"buy_up_to": buy_up_to.duplicate(),
	}


static func from_dict(data: Dictionary) -> IslandEconomy:
	var raw_profile: Variant = data.get("profile")
	var raw_stock: Variant = data.get("stock")
	var raw_supply: Variant = data.get("category_supply")
	var raw_good_supply: Variant = data.get("good_supply")
	var raw_announced: Variant = data.get("shortage_announced")
	if not (raw_profile is StringName and raw_stock is Dictionary and raw_supply is Dictionary \
			and raw_good_supply is Dictionary and raw_announced is Dictionary):
		return null
	var economy := IslandEconomy.new()
	economy.profile_id = raw_profile
	var stock_data: Dictionary = raw_stock
	for good: Variant in stock_data:
		var tons: Variant = stock_data[good]
		if not (good is StringName and tons is float):
			return null
		var tons_value: float = tons
		if tons_value < 0.0:
			return null
		economy.stock[good] = tons_value
	var supply_data: Dictionary = raw_supply
	for tier: Variant in supply_data:
		var by_category: Variant = supply_data[tier]
		if not (tier is StringName and by_category is Dictionary):
			return null
		var categories: Dictionary = by_category
		for category: Variant in categories:
			var value: Variant = categories[category]
			if not (category is StringName and value is float):
				return null
			var tier_id: StringName = tier
			var category_id: StringName = category
			var supply: float = value
			economy.set_supply(tier_id, category_id, supply)
	var good_supply_data: Dictionary = raw_good_supply
	for good: Variant in good_supply_data:
		var value: Variant = good_supply_data[good]
		if not (good is StringName and value is float):
			return null
		economy.good_supply[good] = value
	var announced_data: Dictionary = raw_announced
	for good: Variant in announced_data:
		var flag: Variant = announced_data[good]
		if not (good is StringName and flag is bool):
			return null
		economy.shortage_announced[good] = flag
	for pair: Array in [[data.get("sell_above"), economy.sell_above], [data.get("buy_up_to"), economy.buy_up_to]]:
		var raw: Variant = pair[0]
		if not raw is Dictionary:
			return null
		var source: Dictionary = raw
		var into: Dictionary[StringName, int] = pair[1]
		for good: Variant in source:
			var tons: Variant = source[good]
			if not (good is StringName and tons is int):
				return null
			var tons_value: int = tons
			if tons_value < 0:
				return null
			into[good] = tons_value
	return economy
