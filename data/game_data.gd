class_name GameData
extends Resource
## Todas as definições do jogo: bens, classes, prédios e perfis de ilha.
## A ordem dos prédios é a do menu de construção; a das classes é a do upgrade.

const DEFAULT_PATH := "res://data/game_data.tres"

static var _default: GameData

@export var goods: Array[GoodDef] = []
@export var tiers: Array[TierDef] = []
@export var buildings: Array[BuildingDef] = []
@export var island_profiles: Array[IslandProfileDef] = []
## Navios (Fase 6): o primeiro é o que o jogador compra.
@export var ships: Array[ShipDef] = []
@export var traders: Array[TraderDef] = []
## Metas guiadas (Fase 8), na ordem em que o jogador as recebe.
@export var goals: Array[GoalDef] = []
## Eventos da partida e encomendas do comerciante (Fase 11).
@export var events: Array[EventDef] = []
@export var missions: Array[MissionDef] = []
## Companhias rivais (Fase 11).
@export var rivals: Array[RivalDef] = []
## Especialistas que o comerciante traz (Fase 11).
@export var specialists: Array[SpecialistDef] = []
## Cenários prontos e conquistas (Fase 12).
@export var scenarios: Array[ScenarioDef] = []
@export var achievements: Array[AchievementDef] = []
## Manchetes do jornal (Fase 63): as de notícia, sorteadas a cada edição, e as de propaganda, compradas.
@export var headlines: Array[HeadlineDef] = []
## Políticas da prefeitura (Fase 66).
@export var policies: Array[PolicyDef] = []
## Peças do zoológico e do museu (Fase 67).
@export var exhibits: Array[ExhibitDef] = []
## Destinos das expedições (Fase 69).
@export var expeditions: Array[ExpeditionDef] = []

var _building_index: Dictionary[StringName, BuildingDef] = {}
var _good_index: Dictionary[StringName, GoodDef] = {}
var _tier_index: Dictionary[StringName, TierDef] = {}


static func get_default() -> GameData:
	if _default == null:
		_default = load(DEFAULT_PATH) as GameData
	return _default


## Busca por id em dicionário (os sistemas consultam a cada tick, para cada prédio).
## O índice se refaz quando o tamanho da lista muda.
func building(id: StringName) -> BuildingDef:
	if _building_index.size() != buildings.size():
		_building_index.clear()
		for def: BuildingDef in buildings:
			_building_index[def.id] = def
	return _building_index.get(id)


func good(id: StringName) -> GoodDef:
	if _good_index.size() != goods.size():
		_good_index.clear()
		for def: GoodDef in goods:
			_good_index[def.id] = def
	return _good_index.get(id)


func tier(id: StringName) -> TierDef:
	if _tier_index.size() != tiers.size():
		_tier_index.clear()
		for def: TierDef in tiers:
			_tier_index[def.id] = def
	return _tier_index.get(id)


func tier_index(id: StringName) -> int:
	for index: int in tiers.size():
		if tiers[index].id == id:
			return index
	return -1


## A classe acima desta, ou null se for a última.
func next_tier(id: StringName) -> TierDef:
	var index := tier_index(id)
	return tiers[index + 1] if index >= 0 and index + 1 < tiers.size() else null


func scenario(id: StringName) -> ScenarioDef:
	for def: ScenarioDef in scenarios:
		if def.id == id:
			return def
	return null


func ship(id: StringName) -> ShipDef:
	for def: ShipDef in ships:
		if def.id == id:
			return def
	return null


## O comerciante neutro (o único do jogo base), ou null.
func trader() -> TraderDef:
	return traders[0] if not traders.is_empty() else null


func profile(id: StringName) -> IslandProfileDef:
	for def: IslandProfileDef in island_profiles:
		if def.id == id:
			return def
	return null


func event(id: StringName) -> EventDef:
	for def: EventDef in events:
		if def.id == id:
			return def
	return null


func expedition(id: StringName) -> ExpeditionDef:
	for def: ExpeditionDef in expeditions:
		if def.id == id:
			return def
	return null


func exhibit(id: StringName) -> ExhibitDef:
	for def: ExhibitDef in exhibits:
		if def.id == id:
			return def
	return null


func policy(id: StringName) -> PolicyDef:
	for def: PolicyDef in policies:
		if def.id == id:
			return def
	return null


func headline(id: StringName) -> HeadlineDef:
	for def: HeadlineDef in headlines:
		if def.id == id:
			return def
	return null


func rival(id: StringName) -> RivalDef:
	for def: RivalDef in rivals:
		if def.id == id:
			return def
	return null


func specialist(id: StringName) -> SpecialistDef:
	for def: SpecialistDef in specialists:
		if def.id == id:
			return def
	return null


func mission(id: StringName) -> MissionDef:
	for def: MissionDef in missions:
		if def.id == id:
			return def
	return null


## Lista definições inválidas ou referências quebradas. Vazia quando está tudo certo.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	_check_ids(problems, "bem", goods.map(func(def: GoodDef) -> StringName: return def.id))
	_check_ids(problems, "classe", tiers.map(func(def: TierDef) -> StringName: return def.id))
	_check_ids(problems, "prédio", buildings.map(func(def: BuildingDef) -> StringName: return def.id))
	for def: BuildingDef in buildings:
		if def.size.x <= 0 or def.size.y <= 0:
			problems.append("%s: tamanho deve ser positivo" % def.id)
		if def.wall_material < 0 or def.wall_material >= BuildingMaterials.Wall.size():
			problems.append("%s: textura de parede fora da lista" % def.id)
		for material: StringName in def.cost_materials:
			if good(material) == null:
				problems.append("%s: material desconhecido %s" % [def.id, material])
		if def.unlock_tier != &"" and tier(def.unlock_tier) == null:
			problems.append("%s: classe de desbloqueio desconhecida" % def.id)
		if def.is_production():
			if def.cycle_s <= 0.0 or (good(def.output) == null and not def.is_power_plant() and not def.is_shipyard()):
				problems.append("%s: produção sem ciclo ou sem saída válida" % def.id)
			if tier(def.workforce_tier) == null:
				problems.append("%s: classe de trabalho desconhecida" % def.id)
			for input: StringName in def.inputs:
				if good(input) == null:
					problems.append("%s: entrada desconhecida %s" % [def.id, input])
			if def.modules_required > 0 and building(def.module_id) == null:
				problems.append("%s: módulo desconhecido %s" % [def.id, def.module_id])
			for ship_id: StringName in def.shipyard_ships:
				if ship(ship_id) == null:
					problems.append("%s: navio desconhecido %s" % [def.id, ship_id])
	for tier_def: TierDef in tiers:
		if tier_def.wall_material < 0 or tier_def.wall_material >= BuildingMaterials.Wall.size() \
				or tier_def.roof_material < 0 or tier_def.roof_material >= BuildingMaterials.Roof.size():
			problems.append("%s: textura de parede ou telhado fora da lista" % tier_def.id)
		if tier_def.clothing_colors.is_empty():
			problems.append("%s: sem cores de roupa para os pedestres" % tier_def.id)
		for material: StringName in tier_def.upgrade_materials:
			if good(material) == null:
				problems.append("%s: material de upgrade desconhecido %s" % [tier_def.id, material])
		for need: NeedCategoryDef in tier_def.basic_needs + tier_def.luxury_needs:
			if need.option_count() == 0:
				problems.append("%s/%s: categoria sem opção" % [tier_def.id, need.id])
			for good_id: StringName in need.goods:
				if good(good_id) == null or good(good_id).consumption_per_resident_t_min <= 0.0:
					problems.append("%s/%s: bem sem consumo definido %s" % [tier_def.id, need.id, good_id])
			for service_id: StringName in need.services:
				var service := building(service_id)
				if service == null or service.kind != BuildingDef.Kind.SERVICE:
					problems.append("%s/%s: serviço desconhecido %s" % [tier_def.id, need.id, service_id])
	if island_profiles.is_empty():
		problems.append("nenhum perfil de ilha")
	_check_ids(problems, "navio", ships.map(func(def: ShipDef) -> StringName: return def.id))
	for ship_def: ShipDef in ships:
		if ship_def.cargo_slots <= 0 or ship_def.slot_capacity_t <= 0 or ship_def.speed_m_s <= 0.0:
			problems.append("%s: porão e velocidade devem ser positivos" % ship_def.id)
		if ship_def.hull_points <= 0.0 or (ship_def.cannons > 0 and (ship_def.salvo_damage <= 0.0 or ship_def.cannon_range_m <= 0.0 or ship_def.reload_s <= 0.0)):
			problems.append("%s: casco positivo; navio armado com dano, alcance e recarga positivos" % ship_def.id)
		for material: StringName in ship_def.cost_materials:
			if good(material) == null:
				problems.append("%s: material desconhecido %s" % [ship_def.id, material])
	for trader_def: TraderDef in traders:
		if ship(trader_def.ship) == null:
			problems.append("%s: navio desconhecido %s" % [trader_def.id, trader_def.ship])
		for good_id: StringName in trader_def.sells + trader_def.buys:
			if good(good_id) == null:
				problems.append("%s: bem desconhecido %s" % [trader_def.id, good_id])
		if trader_def.visit_interval_s <= 0.0 or trader_def.max_tons_per_visit <= 0:
			problems.append("%s: intervalo e teto por visita devem ser positivos" % trader_def.id)
	_check_ids(problems, "cenário", scenarios.map(func(def: ScenarioDef) -> StringName: return def.id))
	for scenario_def: ScenarioDef in scenarios:
		if scenario_def.victory_amount <= 0 or scenario_def.time_limit_min < 0.0 or scenario_def.archipelago_size < 0 \
				or scenario_def.archipelago_size > 2 or scenario_def.difficulty < 0 or scenario_def.difficulty > 2:
			problems.append("cenário %s: objetivo positivo, prazo não negativo, tamanho e dificuldade de 0 a 2" % scenario_def.id)
		if scenario_def.victory_kind == GoalDef.Kind.TIER_POPULATION and tier(scenario_def.victory_target) == null:
			problems.append("cenário %s: classe desconhecida %s" % [scenario_def.id, scenario_def.victory_target])
	_check_ids(problems, "conquista", achievements.map(func(def: AchievementDef) -> StringName: return def.id))
	for achievement_def: AchievementDef in achievements:
		if achievement_def.amount <= 0:
			problems.append("conquista %s: quantidade positiva" % achievement_def.id)
		if achievement_def.kind == AchievementDef.Kind.TIER_POPULATION and tier(achievement_def.target) == null:
			problems.append("conquista %s: classe desconhecida %s" % [achievement_def.id, achievement_def.target])
		if achievement_def.kind == AchievementDef.Kind.VICTORY and achievement_def.target != &"" and scenario(achievement_def.target) == null:
			problems.append("conquista %s: cenário desconhecido %s" % [achievement_def.id, achievement_def.target])
	_check_ids(problems, "meta", goals.map(func(def: GoalDef) -> StringName: return def.id))
	for goal: GoalDef in goals:
		_check_goal(problems, goal)
	_check_ids(problems, "evento", events.map(func(def: EventDef) -> StringName: return def.id))
	for event_def: EventDef in events:
		if event_def.duration_s <= 0.0 or event_def.weight <= 0 or event_def.after_milestone < 0:
			problems.append("evento %s: duração e peso positivos, marco não negativo" % event_def.id)
		if event_def.effect != EventDef.Effect.HAPPINESS and event_def.amount <= 0.0:
			problems.append("evento %s: multiplicador deve ser positivo" % event_def.id)
	_check_ids(problems, "expedição", expeditions.map(func(def: ExpeditionDef) -> StringName: return def.id))
	for expedition_def: ExpeditionDef in expeditions:
		if expedition_def.duration_s <= 0.0 or expedition_def.cost_money < 0 or expedition_def.after_milestone < 0:
			problems.append("expedição %s: duração positiva, custo e marco não negativos" % expedition_def.id)
		if expedition_def.empty_chance < 0.0 or expedition_def.lost_chance < 0.0 \
				or expedition_def.empty_chance + expedition_def.lost_chance >= 1.0:
			problems.append("expedição %s: as chances de voltar vazia e de naufragar somam menos que 1" % expedition_def.id)
	_check_ids(problems, "peça", exhibits.map(func(def: ExhibitDef) -> StringName: return def.id))
	for exhibit_def: ExhibitDef in exhibits:
		if exhibit_def.price < 0 or exhibit_def.beauty < 0.0 or exhibit_def.after_milestone < 0:
			problems.append("peça %s: preço, beleza e marco não negativos" % exhibit_def.id)
	_check_ids(problems, "política", policies.map(func(def: PolicyDef) -> StringName: return def.id))
	for policy_def: PolicyDef in policies:
		if policy_def.upkeep_per_min < 0 or policy_def.after_milestone < 0:
			problems.append("política %s: manutenção e marco não negativos" % policy_def.id)
		if policy_def.effect == PolicyDef.Effect.FIRE_RISK and (policy_def.amount < 0.0 or policy_def.amount >= 1.0):
			problems.append("política %s: o multiplicador do incêndio fica entre 0 e 1" % policy_def.id)
	_check_ids(problems, "manchete", headlines.map(func(def: HeadlineDef) -> StringName: return def.id))
	var news := 0
	for headline_def: HeadlineDef in headlines:
		if headline_def.weight <= 0 or headline_def.after_milestone < 0:
			problems.append("manchete %s: peso positivo, marco não negativo" % headline_def.id)
		if not headline_def.propaganda and headline_def.after_milestone == 0:
			news += 1
	if not headlines.is_empty() and news == 0:
		problems.append("manchetes: pelo menos uma de notícia sem marco (a primeira edição precisa de uma)")
	_check_ids(problems, "encomenda", missions.map(func(def: MissionDef) -> StringName: return def.id))
	for mission_def: MissionDef in missions:
		if good(mission_def.good) == null:
			problems.append("encomenda %s: bem desconhecido %s" % [mission_def.id, mission_def.good])
		elif trader() != null and not trader().buys.has(mission_def.good):
			problems.append("encomenda %s: o comerciante não compra %s (a entrega é a venda no posto)" % [mission_def.id, mission_def.good])
		if mission_def.tons <= 0 or mission_def.duration_s <= 0.0 or mission_def.bonus_fraction < 0.0 \
				or mission_def.weight <= 0 or mission_def.after_milestone < 0:
			problems.append("encomenda %s: toneladas, prazo e peso positivos" % mission_def.id)
	_check_ids(problems, "rival", rivals.map(func(def: RivalDef) -> StringName: return def.id))
	for rival_def: RivalDef in rivals:
		if ship(rival_def.ship) == null:
			problems.append("rival %s: navio desconhecido %s" % [rival_def.id, rival_def.ship])
		if rival_def.first_colony_s <= 0.0 or rival_def.colony_interval_s <= 0.0 or rival_def.max_islands < 1 or rival_def.growth_per_min <= 0.0:
			problems.append("rival %s: tempos, teto de ilhas e crescimento positivos" % rival_def.id)
	_check_ids(problems, "especialista", specialists.map(func(def: SpecialistDef) -> StringName: return def.id))
	for specialist_def: SpecialistDef in specialists:
		if specialist_def.amount <= 0.0 or specialist_def.hire_cost < 0 or specialist_def.salary_per_min < 0 \
				or specialist_def.weight <= 0 or specialist_def.after_milestone < 0:
			problems.append("especialista %s: efeito e peso positivos, custo, salário e marco não negativos" % specialist_def.id)
		if specialist_def.effect == SpecialistDef.Effect.UPKEEP and specialist_def.amount > 1.0:
			problems.append("especialista %s: corte de manutenção acima de 100%%" % specialist_def.id)
		if not buildings.any(func(def: BuildingDef) -> bool: return specialist_def.covers(def)):
			problems.append("especialista %s: nenhum prédio aceita" % specialist_def.id)
		for building_id: StringName in specialist_def.buildings:
			if building(building_id) == null:
				problems.append("especialista %s: prédio desconhecido %s" % [specialist_def.id, building_id])
	return problems


func _check_goal(problems: PackedStringArray, goal: GoalDef) -> void:
	if goal.hint != &"" and goal.hint != &"paved_road" and building(goal.hint) == null:
		problems.append("meta %s: dica aponta prédio desconhecido %s" % [goal.id, goal.hint])
	if goal.amount <= 0 or goal.reward_money < 0 or goal.after_milestone < 0:
		problems.append("meta %s: quantidade positiva, prêmio e marco não negativos" % goal.id)
	match goal.kind:
		GoalDef.Kind.BUILDING_COUNT:
			if building(goal.target) == null:
				problems.append("meta %s: prédio desconhecido %s" % [goal.id, goal.target])
		GoalDef.Kind.TIER_POPULATION:
			if tier(goal.target) == null:
				problems.append("meta %s: classe desconhecida %s" % [goal.id, goal.target])
		GoalDef.Kind.NEED_SUPPLIED:
			var tier_def := tier(goal.target)
			if tier_def == null or not (tier_def.basic_needs + tier_def.luxury_needs).any(
					func(need: NeedCategoryDef) -> bool: return need.id == goal.need and not need.goods.is_empty()):
				problems.append("meta %s: necessidade de bem desconhecida %s/%s" % [goal.id, goal.target, goal.need])


func _check_ids(problems: PackedStringArray, what: String, ids: Array) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for id: StringName in ids:
		if id == &"" or seen.has(id):
			problems.append("id de %s vazio ou repetido: '%s'" % [what, id])
		seen[id] = true
