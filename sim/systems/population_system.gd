class_name PopulationSystem
extends RefCounted
## Moradores, felicidade, imposto e upgrade de cada casa.
## - A casa enche até uma fração do máximo sem nenhuma necessidade e até o máximo com todas as
##   básicas; o que falta sai aos poucos (1 morador por minuto), nunca tudo de uma vez.
## - Felicidade: base + luxo − falta de bens + nível de imposto − poluição + beleza (decoração, Fase 16) (+ festa, Fase 11),
##   andando devagar. A chegada de imigrantes (Fase 11) acelera o enchimento.
## - O imposto da casa fica em tax_per_min para a economia somar no mesmo tick.
## - Cada tick avalia um grupo de casas (DerivedState.house_groups) com o tempo do ciclo
##   inteiro de grupos: cada casa é vista uma vez a cada house_update_groups ticks.
## - Upgrade: todas as básicas atendidas, casa cheia, materiais no estoque e sem bloqueio.
##   No máximo uma casa por ilha a cada tick, para o estoque não sumir de uma vez.
## - Riscos: a casa em chamas não paga imposto nem recebe gente nem sobe; a doente perde
##   disease_residents_lost_per_min moradores e disease_happiness_penalty de felicidade e não sobe.


static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, dt: float) -> void:
	var group := world.tick % derived.house_groups.size()
	var dt_min := dt * derived.house_groups.size() / 60.0
	var upgraded_on: Dictionary[int, bool] = {}
	## ilha → classe → atendimento da classe (igual para todas as casas dela na ilha)
	var supplies: Dictionary[int, Dictionary] = {}
	## Fase 29: a avaliação só depende do atendimento da classe na ilha e dos serviços que cobrem a casa, e muitas
	## casas têm a mesma cobertura: atendimento → cobertura → avaliação, dentro do tick
	var evaluations: Dictionary[HouseNeeds.TierSupply, Dictionary] = {}
	## Fase 29: o que não muda de casa para casa sai do laço — chegada e efeito de evento por ilha, se há fogo ou
	## doença, a felicidade do nível de imposto por classe
	var events := world.events_state
	var any_event := not events.events.is_empty()
	var risks := world.risks_state
	var any_fire := not risks.fires.is_empty()
	var any_outbreak := not risks.outbreaks.is_empty()
	var arrival_by_island: Dictionary[int, float] = {}
	var event_happiness: Dictionary[int, float] = {}
	var tax_happiness: Dictionary[StringName, float] = {}
	var shortage_step := config.residents_lost_per_minute_on_shortage * dt_min
	var happiness_step := config.happiness_change_per_minute * dt_min
	var base_fraction := config.house_base_residents_fraction
	var members: Array = derived.house_groups[group]
	for house_id: int in members:
		var house := world.building(house_id)
		var island := house.island_id
		if not supplies.has(island):
			supplies[island] = {}
			arrival_by_island[island] = config.residents_arrival_per_minute \
					* (EventEffects.arrival(events, island) if any_event else 1.0)
			event_happiness[island] = EventEffects.happiness(events, island) if any_event else 0.0
		var by_tier: Dictionary = supplies[island]
		if not by_tier.has(house.tier):
			var fresh := HouseNeeds.tier_supply(world.economy(island), config, data.tier(house.tier))
			by_tier[house.tier] = fresh
			evaluations[fresh] = {}
			if not tax_happiness.has(house.tier):
				tax_happiness[house.tier] = config.tax_level_happiness[world.tax_level(house.tier)]
		var supply: HouseNeeds.TierSupply = by_tier[house.tier]
		var tier := supply.tier
		var covering: Array = derived.coverage.get(house_id, [])
		var cached: Dictionary = evaluations[supply]
		var evaluation: HouseNeeds.Evaluation = cached.get(covering)
		if evaluation == null:
			evaluation = HouseNeeds.evaluate(derived, config, house_id, supply)
			cached[covering] = evaluation
		var capacity := float(tier.residents_per_house)
		var target := capacity * (base_fraction + (1.0 - base_fraction) * evaluation.basic_average)
		var burning := any_fire and risks.fires.has(house_id)
		var sick := any_outbreak and risks.outbreaks.has(house_id)
		var change := clampf(target - house.residents, -shortage_step, arrival_by_island[island] * dt_min)
		if burning:
			change = minf(change, 0.0)
		if sick:
			change = minf(change, 0.0) - config.disease_residents_lost_per_min * dt_min
		house.residents = clampf(house.residents + change, 0.0, capacity)
		var pollution: float = derived.pollution.get(house_id, 0.0)
		var beauty: float = derived.beauty.get(house_id, 0.0)
		var happiness_target: float = config.happiness_base \
				+ config.happiness_per_luxury * evaluation.luxury_total \
				- config.happiness_shortage_penalty * (1.0 - evaluation.basic_average) \
				+ tax_happiness[house.tier] \
				- config.happiness_pollution_penalty * pollution \
				+ config.happiness_per_beauty * beauty \
				+ event_happiness[island] \
				- (config.disease_happiness_penalty if sick else 0.0)
		house.happiness = move_toward(house.happiness, clampf(happiness_target, 0.0, 100.0), happiness_step)
		house.tax_per_min = 0.0 if burning else HouseNeeds.tax_from(world, config, house, tier, evaluation.bonus_categories)
		if not upgraded_on.has(island) and evaluation.all_basic_met and not burning and not sick \
				and _try_upgrade(world, data, house, tier, target):
			upgraded_on[island] = true
	derived.recount_group(world, group)


## Sobe quando a casa chegou aos moradores que o atendimento dela permite (target). Exigir a casa
## cheia travava a subida para sempre com uma necessidade em 95%: a categoria já conta como
## atendida (need_met_threshold), mas a casa só enche com 100%.
static func _try_upgrade(world: WorldState, data: GameData, house: BuildingRecord, tier: TierDef, target: float) -> bool:
	var next := data.next_tier(tier.id)
	if next == null or house.upgrade_blocked or house.residents < target - 0.001:
		return false
	var economy := world.economy(house.island_id)
	if not economy.has_materials(next.upgrade_materials):
		return false
	for material: StringName in next.upgrade_materials:
		economy.take(material, next.upgrade_materials[material])
	house.tier = next.id
	EventBus.house_upgraded.emit(house.id)
	return true
