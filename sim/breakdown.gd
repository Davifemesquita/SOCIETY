class_name Breakdown
extends RefCounted
## O "porquê" dos números (Fase 47), só leitura, montado quando o jogador passa o mouse (nunca no tick): cada bem em
## t/min por fonte (produção e consumo dos prédios por tipo, consumo das casas por classe) e o dinheiro por minuto
## (imposto por classe, acordo com rivais, manutenção por tipo de prédio, navios e salários). As parcelas somam
## exatamente o que a tela mostra: produção menos consumo da linha das estatísticas, e receita menos manutenção.

enum Kind { BUILDING, TIER, SHIPS, SALARIES, TREATY, TOURISM }


class Source:
	var kind: Kind
	## Tipo do prédio ou classe (vazio em navios, salários e acordo).
	var id: StringName
	## Quantos prédios (ou navios) entram na parcela.
	var count: int = 0
	## Por minuto: positivo entra, negativo sai.
	var per_min: float = 0.0

	func _init(source_kind: Kind, source_id: StringName) -> void:
		kind = source_kind
		id = source_id


## Um bem numa ilha (ou em todas, island_id < 0): a produção de cada tipo de prédio, o consumo dos prédios que o usam e
## o das casas repartido pelas classes na proporção do que cada uma pede.
static func good(world: WorldState, data: GameData, derived: DerivedState, island_id: int, good_id: StringName) -> Array[Source]:
	var made: Dictionary[StringName, Source] = {}
	var used: Dictionary[StringName, Source] = {}
	for building_id: int in derived.production:
		var record := world.building(building_id)
		if island_id >= 0 and record.island_id != island_id:
			continue
		var def := data.building(record.def_id)
		var running := 60.0 / def.cycle_s * record.productivity
		if def.output == good_id:
			_add(made, Kind.BUILDING, def.id, running)
		if def.inputs.has(good_id):
			_add(used, Kind.BUILDING, def.id, -running)
	var tiers: Dictionary[StringName, Source] = {}
	for index: int in world.islands.size():
		if island_id >= 0 and index != island_id:
			continue
		var houses: float = world.economy(index).needs_consumption_per_min.get(good_id, 0.0)
		if houses <= 0.0:
			continue
		var weights := _tier_weights(data, derived.residents_by_tier(index), good_id)
		var total := 0.0
		for tier_id: StringName in weights:
			total += weights[tier_id]
		if total <= 0.0:
			# sem moradores que peçam o bem (a média ainda descendo): tudo na primeira classe, para a soma fechar
			weights = {data.tiers[0].id: 1.0}
			total = 1.0
		for tier_id: StringName in weights:
			if weights[tier_id] > 0.0:
				_add(tiers, Kind.TIER, tier_id, -houses * weights[tier_id] / total, 0)
	var sources: Array[Source] = []
	sources.append_array(_sorted(made))
	sources.append_array(_sorted(used))
	sources.append_array(_sorted(tiers))
	return sources


## O dinheiro por minuto: imposto por classe (as casas na última avaliação, na escala da receita que a economia somou),
## acordos com rivais, manutenção por tipo de prédio (com a pausa e o especialista), navios e salários.
static func money(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState) -> Array[Source]:
	# a barra mostra a receita e a manutenção do último tick (WorldState); as parcelas, refeitas agora, vão para a
	# escala delas (a diferença só existe no tick em que algo mudou)
	var taxes: Dictionary[StringName, Source] = {}
	for house_id: int in derived.houses:
		var house := world.building(house_id)
		_add(taxes, Kind.TIER, house.tier, house.tax_per_min)
	_scale_to(taxes, world.income_per_min - world.treaty_income_per_min - world.tourism_per_min, Kind.TIER, data.tiers[0].id)
	var ships := Source.new(Kind.SHIPS, &"")
	for ship: Ship in world.ships.values():
		if ship.owner == Ship.Owner.PLAYER:
			ships.count += 1
			ships.per_min -= data.ship(ship.def_id).upkeep_per_min
	var salaries := world.specialists_state.salaries_per_min()
	var costs: Dictionary[StringName, Source] = {}
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := data.building(record.def_id)
		if def.upkeep_per_min <= 0.0:
			continue
		var upkeep := def.upkeep_per_min * (config.paused_upkeep_factor if record.paused else 1.0) \
				* DerivedState.upkeep_factor(world.specialists_state.at(building_id))
		_add(costs, Kind.BUILDING, def.id, -upkeep)
	_scale_to(costs, -(world.upkeep_per_min + ships.per_min - salaries), Kind.BUILDING, &"")
	var sources: Array[Source] = []
	sources.append_array(_sorted(taxes))
	if world.treaty_income_per_min > 0.0:
		var treaty := Source.new(Kind.TREATY, &"")
		treaty.per_min = world.treaty_income_per_min
		sources.append(treaty)
	# Fase 68: os turistas
	if world.tourism_per_min > 0.0:
		var tourism := Source.new(Kind.TOURISM, &"")
		tourism.per_min = world.tourism_per_min
		sources.append(tourism)
	sources.append_array(_sorted(costs))
	if ships.count > 0:
		sources.append(ships)
	if salaries > 0.0:
		var paid := Source.new(Kind.SALARIES, &"")
		paid.per_min = -salaries
		sources.append(paid)
	return sources


static func total(sources: Array[Source]) -> float:
	var sum := 0.0
	for source: Source in sources:
		sum += source.per_min
	return sum


## Quanto cada classe pede do bem por minuto (moradores × consumo por morador ÷ opções da categoria), como o
## NeedsSystem reparte.
static func _tier_weights(data: GameData, residents: Dictionary[StringName, float], good_id: StringName) -> Dictionary[StringName, float]:
	var weights: Dictionary[StringName, float] = {}
	var per_resident := data.good(good_id).consumption_per_resident_t_min
	for tier: TierDef in data.tiers:
		var people: float = residents.get(tier.id, 0.0)
		if people <= 0.0:
			continue
		for need: NeedCategoryDef in tier.all_needs():
			if need.goods.has(good_id):
				weights[tier.id] = weights.get(tier.id, 0.0) + people * per_resident / need.goods.size()
	return weights


## Leva a soma das parcelas a "target" (proporcional); sem parcela para escalar, uma só com o alvo inteiro.
static func _scale_to(sources: Dictionary[StringName, Source], target: float, kind: Kind, fallback: StringName) -> void:
	var raw := 0.0
	for id: StringName in sources:
		raw += sources[id].per_min
	if absf(target) < 0.000001:
		sources.clear()
		return
	if absf(raw) < 0.000001:
		sources.clear()
		_add(sources, kind, fallback, target, 0)
		return
	var factor := target / raw
	for id: StringName in sources:
		sources[id].per_min *= factor


static func _add(into: Dictionary[StringName, Source], kind: Kind, id: StringName, per_min: float, count: int = 1) -> void:
	if not into.has(id):
		into[id] = Source.new(kind, id)
	into[id].per_min += per_min
	into[id].count += count


## Da maior parcela para a menor (em valor absoluto).
static func _sorted(sources: Dictionary[StringName, Source]) -> Array[Source]:
	var list: Array[Source] = []
	list.assign(sources.values())
	list.sort_custom(func(a: Source, b: Source) -> bool: return absf(a.per_min) > absf(b.per_min))
	return list
