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


## Lista definições inválidas ou referências quebradas. Vazia quando está tudo certo.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	_check_ids(problems, "bem", goods.map(func(def: GoodDef) -> StringName: return def.id))
	_check_ids(problems, "classe", tiers.map(func(def: TierDef) -> StringName: return def.id))
	_check_ids(problems, "prédio", buildings.map(func(def: BuildingDef) -> StringName: return def.id))
	for def: BuildingDef in buildings:
		if def.size.x <= 0 or def.size.y <= 0:
			problems.append("%s: tamanho deve ser positivo" % def.id)
		for material: StringName in def.cost_materials:
			if good(material) == null:
				problems.append("%s: material desconhecido %s" % [def.id, material])
		if def.unlock_tier != &"" and tier(def.unlock_tier) == null:
			problems.append("%s: classe de desbloqueio desconhecida" % def.id)
		if def.is_production():
			if def.cycle_s <= 0.0 or good(def.output) == null:
				problems.append("%s: produção sem ciclo ou sem saída válida" % def.id)
			if tier(def.workforce_tier) == null:
				problems.append("%s: classe de trabalho desconhecida" % def.id)
			for input: StringName in def.inputs:
				if good(input) == null:
					problems.append("%s: entrada desconhecida %s" % [def.id, input])
			if def.modules_required > 0 and building(def.module_id) == null:
				problems.append("%s: módulo desconhecido %s" % [def.id, def.module_id])
	for tier_def: TierDef in tiers:
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
	return problems


func _check_ids(problems: PackedStringArray, what: String, ids: Array) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for id: StringName in ids:
		if id == &"" or seen.has(id):
			problems.append("id de %s vazio ou repetido: '%s'" % [what, id])
		seen[id] = true
