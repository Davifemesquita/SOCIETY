class_name NeedsSystem
extends RefCounted
## Consumo e atendimento das necessidades de bens, por ilha e por classe. O consumo é
## abstrato: sai direto do estoque da ilha. Numa categoria, as opções com estoque dividem o
## consumo; o atendimento (consumido ÷ pedido) entra numa média móvel por categoria.
## Os serviços não consomem nada: a cobertura deles é por casa (DerivedState).


static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, dt: float) -> void:
	var smoothing := 1.0 - exp(-dt / config.supply_smoothing_seconds)
	var dt_min := dt / 60.0
	for island_id: int in world.economies.size():
		var economy := world.economy(island_id)
		# ilha sem casa (colônia só de produção, ilha vazia): nada a consumir nem a avaliar
		if not derived.islands_with_houses.has(island_id):
			economy.needs_consumption_per_min.clear()
			continue
		var residents := derived.residents_by_tier(island_id)
		var demanded: Dictionary[StringName, float] = {}
		var consumed: Dictionary[StringName, float] = {}
		var basic_goods: Dictionary[StringName, bool] = {}
		for tier: TierDef in data.tiers:
			var people: float = residents.get(tier.id, 0.0)
			if people > 0.0:
				for need: NeedCategoryDef in tier.basic_needs:
					for good: StringName in need.goods:
						basic_goods[good] = true
			for need: NeedCategoryDef in tier.all_needs():
				if need.goods.is_empty():
					continue
				var fulfilled := _consume(economy, data, need, people, dt_min, demanded, consumed)
				economy.set_supply(tier.id, need.id, lerpf(economy.supply_of(tier.id, need.id), fulfilled, smoothing))
		_update_goods(island_id, economy, data, config, demanded, consumed, basic_goods, smoothing, dt_min)


## Consome a categoria e devolve o atendimento deste tick (0..1). Sem moradores, conta
## como atendida se algum bem dela está no estoque (para a primeira casa já ver verde).
static func _consume(economy: IslandEconomy, data: GameData, need: NeedCategoryDef, people: float, dt_min: float,
		demanded: Dictionary[StringName, float], consumed: Dictionary[StringName, float]) -> float:
	var available: Array[StringName] = []
	for good: StringName in need.goods:
		if economy.amount(good) > 0.000001:
			available.append(good)
	if available.is_empty():
		for good: StringName in need.goods:
			if people > 0.0:
				var wanted := people * data.good(good).consumption_per_resident_t_min * dt_min / need.goods.size()
				demanded[good] = demanded.get(good, 0.0) + wanted
		return 0.0
	if people <= 0.0:
		return 1.0
	var wanted_total := 0.0
	var got_total := 0.0
	for good: StringName in available:
		var wanted := people * data.good(good).consumption_per_resident_t_min * dt_min / available.size()
		var got := economy.take(good, wanted)
		demanded[good] = demanded.get(good, 0.0) + wanted
		consumed[good] = consumed.get(good, 0.0) + got
		wanted_total += wanted
		got_total += got
	return got_total / wanted_total


## Atendimento médio por bem e o aviso de falta, uma vez a cada queda. Só bem de necessidade
## básica avisa: luxo não é exigido e avisar toda bebida que ainda não existe seria ruído.
static func _update_goods(island_id: int, economy: IslandEconomy, data: GameData, config: GameConfig,
		demanded: Dictionary[StringName, float], consumed: Dictionary[StringName, float],
		basic_goods: Dictionary[StringName, bool], smoothing: float, dt_min: float) -> void:
	var rate_smoothing := 1.0 - exp(-dt_min * 60.0 / config.productivity_smoothing_seconds)
	for good_def: GoodDef in data.goods:
		if good_def.consumption_per_resident_t_min <= 0.0:
			continue
		var good := good_def.id
		var wanted: float = demanded.get(good, 0.0)
		var got: float = consumed.get(good, 0.0)
		var instant := 1.0
		if wanted > 0.0:
			instant = got / wanted
		elif economy.amount(good) <= 0.000001:
			instant = 0.0
		# média, como a produção: o bem chega de 1 em 1 t e o consumo do instante pisca
		var rate: float = economy.needs_consumption_per_min.get(good, 0.0)
		economy.needs_consumption_per_min[good] = lerpf(rate, got / dt_min, rate_smoothing)
		var previous: float = economy.good_supply.get(good, 0.0)
		var supply := lerpf(previous, instant, smoothing)
		economy.good_supply[good] = supply
		var announced: bool = economy.shortage_announced.get(good, false)
		if wanted > 0.0 and basic_goods.has(good) and supply < config.need_partial_threshold and not announced:
			economy.shortage_announced[good] = true
			EventBus.good_shortage.emit(island_id, good)
		elif announced and supply >= config.need_met_threshold:
			economy.shortage_announced[good] = false
