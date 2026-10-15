class_name PopulationSystem
extends RefCounted
## Moradores, felicidade, imposto e upgrade de cada casa.
## - A casa enche até uma fração do máximo sem nenhuma necessidade e até o máximo com todas as
##   básicas; o que falta sai aos poucos (1 morador por minuto), nunca tudo de uma vez.
## - Felicidade: base + luxo − falta de bens + nível de imposto − poluição (+ festa, Fase 11),
##   andando devagar. A chegada de imigrantes (Fase 11) acelera o enchimento.
## - O imposto da casa fica em tax_per_min para a economia somar no mesmo tick.
## - Cada tick avalia um grupo de casas (DerivedState.house_groups) com o tempo do ciclo
##   inteiro de grupos: cada casa é vista uma vez a cada house_update_groups ticks.
## - Upgrade: todas as básicas atendidas, casa cheia, materiais no estoque e sem bloqueio.
##   No máximo uma casa por ilha a cada tick, para o estoque não sumir de uma vez.


static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, dt: float) -> void:
	var group := world.tick % derived.house_groups.size()
	var dt_min := dt * derived.house_groups.size() / 60.0
	var upgraded_on: Dictionary[int, bool] = {}
	## ilha → classe → atendimento da classe (igual para todas as casas dela na ilha)
	var supplies: Dictionary[int, Dictionary] = {}
	var members: Array = derived.house_groups[group]
	for house_id: int in members:
		var house := world.building(house_id)
		if not supplies.has(house.island_id):
			supplies[house.island_id] = {}
		var by_tier: Dictionary = supplies[house.island_id]
		if not by_tier.has(house.tier):
			by_tier[house.tier] = HouseNeeds.tier_supply(world.economy(house.island_id), config, data.tier(house.tier))
		var supply: HouseNeeds.TierSupply = by_tier[house.tier]
		var tier := supply.tier
		var evaluation := HouseNeeds.evaluate(derived, config, house_id, supply)
		var capacity := float(tier.residents_per_house)
		var target := capacity * (config.house_base_residents_fraction + (1.0 - config.house_base_residents_fraction) * evaluation.basic_average)
		var events := world.events_state
		var arrival := config.residents_arrival_per_minute * (EventEffects.arrival(events, house.island_id) if not events.events.is_empty() else 1.0)
		var change := clampf(target - house.residents, -config.residents_lost_per_minute_on_shortage * dt_min,
				arrival * dt_min)
		house.residents = clampf(house.residents + change, 0.0, capacity)
		var pollution: float = derived.pollution.get(house_id, 0.0)
		var happiness_target: float = config.happiness_base \
				+ config.happiness_per_luxury * evaluation.luxury_total \
				- config.happiness_shortage_penalty * (1.0 - evaluation.basic_average) \
				+ config.tax_level_happiness[world.tax_level(house.tier)] \
				- config.happiness_pollution_penalty * pollution \
				+ (EventEffects.happiness(events, house.island_id) if not events.events.is_empty() else 0.0)
		house.happiness = move_toward(house.happiness, clampf(happiness_target, 0.0, 100.0), config.happiness_change_per_minute * dt_min)
		house.tax_per_min = HouseNeeds.tax_from(world, config, house, tier, evaluation.bonus_categories)
		if not upgraded_on.has(house.island_id) and evaluation.all_basic_met \
				and _try_upgrade(world, data, house, tier, capacity):
			upgraded_on[house.island_id] = true
	derived.recount_group(world, group)


static func _try_upgrade(world: WorldState, data: GameData, house: BuildingRecord, tier: TierDef, capacity: float) -> bool:
	var next := data.next_tier(tier.id)
	if next == null or house.upgrade_blocked or house.residents < capacity - 0.001:
		return false
	var economy := world.economy(house.island_id)
	if not economy.has_materials(next.upgrade_materials):
		return false
	for material: StringName in next.upgrade_materials:
		economy.take(material, next.upgrade_materials[material])
	house.tier = next.id
	EventBus.house_upgraded.emit(house.id)
	return true
