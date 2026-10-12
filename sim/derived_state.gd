class_name DerivedState
extends RefCounted
## O que sai da geometria do mundo e só muda quando um comando muda prédios, estradas ou a
## pausa: acesso à estrada, cobertura dos serviços, módulos de cada fazenda, poluição nas
## casas, e os totais que os sistemas usam a cada tick (manutenção, demanda de trabalhadores,
## consumidores de cada bem). Também guarda as somas por grupo de casas (moradores por classe e
## imposto), refeitas quando o grupo é avaliado. Recalculado inteiro na mudança; fora do save.


class ProductionEntry:
	var record: BuildingRecord
	var def: BuildingDef
	var economy: IslandEconomy
	var has_road: bool
	var modules_ok: bool

var road_access: Dictionary[int, bool] = {}
## Casa → serviços (id do tipo) que a cobrem.
var coverage: Dictionary[int, Array] = {}
## Fazenda → módulos atribuídos a ela.
var module_count: Dictionary[int, int] = {}
## Módulo → fazenda dona dele (0 = solto).
var module_owner: Dictionary[int, int] = {}
## Casa → poluição somada, 0..1.
var pollution: Dictionary[int, float] = {}
## Prédio de serviço → casas cobertas.
var service_houses: Dictionary[int, Array] = {}
## Prédio de serviço → células de estrada alcançadas dentro do raio.
var service_reach: Dictionary[int, PackedInt32Array] = {}
var houses: Array[int] = []
var production: Array[int] = []
var production_entries: Array[ProductionEntry] = []
## ilha → bem → prédios com estrada que consomem o bem (ProductionEntry)
var consumers: Dictionary[int, Dictionary] = {}
var upkeep_per_min: float = 0.0
## ilha → classe → trabalhadores pedidos pelos prédios não pausados
var workforce_demand: Dictionary[int, Dictionary] = {}
## Casas em grupos alternados (índice na lista de casas % número de grupos).
var house_groups: Array[Array] = []
var group_income: PackedFloat64Array = PackedFloat64Array()
## grupo → ilha → classe → moradores
var group_residents: Array[Dictionary] = []


func rebuild(world: WorldState, data: GameData, config: GameConfig) -> void:
	road_access.clear()
	coverage.clear()
	module_count.clear()
	module_owner.clear()
	pollution.clear()
	service_houses.clear()
	service_reach.clear()
	houses.clear()
	production.clear()
	production_entries.clear()
	consumers.clear()
	workforce_demand.clear()
	upkeep_per_min = 0.0
	var services: Array[int] = []
	var farms: Array[int] = []
	var polluters: Array[int] = []
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := data.building(record.def_id)
		road_access[building_id] = RoadNetwork.has_access(world.island(record.island_id), record, def)
		match def.kind:
			BuildingDef.Kind.RESIDENCE:
				houses.append(building_id)
				coverage[building_id] = []
				pollution[building_id] = 0.0
			BuildingDef.Kind.PRODUCTION:
				production.append(building_id)
				if def.modules_required > 0:
					farms.append(building_id)
			BuildingDef.Kind.SERVICE:
				services.append(building_id)
		if def.pollution_radius_cells > 0:
			polluters.append(building_id)
		upkeep_per_min += def.upkeep_per_min * (config.paused_upkeep_factor if record.paused else 1.0)
	var houses_at_road := _houses_by_front_cell(world, data)
	for service_id: int in services:
		_cover(world, data, config, service_id, houses_at_road)
	_assign_modules(world, data, farms)
	_spread_pollution(world, data, polluters)
	_index_production(world, data)
	_group_houses(world, config)


func _index_production(world: WorldState, data: GameData) -> void:
	for building_id: int in production:
		var entry := ProductionEntry.new()
		entry.record = world.building(building_id)
		entry.def = data.building(entry.record.def_id)
		entry.economy = world.economy(entry.record.island_id)
		entry.has_road = road_access[building_id]
		entry.modules_ok = module_count.get(building_id, 0) >= entry.def.modules_required
		production_entries.append(entry)
		var island := entry.record.island_id
		if not entry.record.paused:
			if not workforce_demand.has(island):
				workforce_demand[island] = {}
			var demand: Dictionary = workforce_demand[island]
			demand[entry.def.workforce_tier] = demand.get(entry.def.workforce_tier, 0.0) + entry.def.workers
		if entry.has_road:
			for input: StringName in entry.def.inputs:
				if not consumers.has(island):
					consumers[island] = {}
				var by_good: Dictionary = consumers[island]
				if not by_good.has(input):
					by_good[input] = []
				var list: Array = by_good[input]
				list.append(entry)


func _group_houses(world: WorldState, config: GameConfig) -> void:
	var groups := maxi(1, config.house_update_groups)
	house_groups.clear()
	group_residents.clear()
	group_income.resize(groups)
	for group: int in groups:
		house_groups.append([])
		group_residents.append({})
	for index: int in houses.size():
		house_groups[index % groups].append(houses[index])
	for group: int in groups:
		recount_group(world, group)


## Refaz as somas de um grupo a partir das casas dele (em ordem fixa: a soma volta igual).
func recount_group(world: WorldState, group: int) -> void:
	var income := 0.0
	var residents: Dictionary = {}
	for house_id: int in house_groups[group]:
		var house := world.building(house_id)
		income += house.tax_per_min
		if not residents.has(house.island_id):
			residents[house.island_id] = {}
		var by_tier: Dictionary = residents[house.island_id]
		by_tier[house.tier] = by_tier.get(house.tier, 0.0) + house.residents
	group_income[group] = income
	group_residents[group] = residents


func income_per_min() -> float:
	var total := 0.0
	for value: float in group_income:
		total += value
	return total


## Moradores de cada classe numa ilha, somando os grupos.
func residents_by_tier(island_id: int) -> Dictionary[StringName, float]:
	var totals: Dictionary[StringName, float] = {}
	for group: Dictionary in group_residents:
		var by_tier: Dictionary = group.get(island_id, {})
		for tier: StringName in by_tier:
			var count: float = by_tier[tier]
			totals[tier] = totals.get(tier, 0.0) + count
	return totals


func has_road(building_id: int) -> bool:
	return road_access.get(building_id, false)


func covered_by(house_id: int, service_def: StringName) -> bool:
	var services: Array = coverage.get(house_id, [])
	return services.has(service_def)


## Célula da frente de cada casa → casas que encostam nela, por ilha ("ilha:índice").
func _houses_by_front_cell(world: WorldState, data: GameData) -> Dictionary[String, Array]:
	var map: Dictionary[String, Array] = {}
	for house_id: int in houses:
		var house := world.building(house_id)
		var grid := world.island(house.island_id)
		for cell: Vector2i in Footprint.front_cells(house.origin, data.building(house.def_id).size, house.rotation):
			if grid.in_bounds(cell):
				var key := "%d:%d" % [house.island_id, grid.index(cell)]
				if not map.has(key):
					map[key] = []
				var list: Array = map[key]
				if not list.has(house_id):
					list.append(house_id)
	return map


## Cobertura de um serviço: estrada alcançada dentro do raio e as casas que encostam nela.
func _cover(world: WorldState, data: GameData, config: GameConfig, service_id: int, houses_at_road: Dictionary[String, Array]) -> void:
	var record := world.building(service_id)
	var def := data.building(record.def_id)
	var grid := world.island(record.island_id)
	var front := Footprint.front_cells(record.origin, def.size, record.rotation)
	var reach := ServiceReach.road_cells(grid, front, ServiceReach.radius_of(def, config))
	service_reach[service_id] = reach
	var covered: Array[int] = []
	for index: int in reach:
		var touching: Array = houses_at_road.get("%d:%d" % [record.island_id, index], [])
		for house_id: int in touching:
			if not covered.has(house_id):
				covered.append(house_id)
				var services: Array = coverage[house_id]
				if not services.has(def.id):
					services.append(def.id)
	covered.sort()
	service_houses[service_id] = covered


## Cada módulo serve a uma fazenda só: a de menor id que o tem no raio e ainda precisa dele.
func _assign_modules(world: WorldState, data: GameData, farms: Array[int]) -> void:
	for farm_id: int in farms:
		var farm := world.building(farm_id)
		var def := data.building(farm.def_id)
		var reach := Footprint.rect(farm.origin, def.size, farm.rotation).grow(def.module_radius_cells)
		var count := 0
		for building_id: int in world.building_ids():
			if count >= def.modules_required:
				break
			var candidate := world.building(building_id)
			if candidate.def_id != def.module_id or candidate.island_id != farm.island_id or module_owner.get(building_id, 0) != 0:
				continue
			var module_def := data.building(candidate.def_id)
			if reach.encloses(Footprint.rect(candidate.origin, module_def.size, candidate.rotation)):
				module_owner[building_id] = farm_id
				count += 1
		module_count[farm_id] = count


## Poluição de cada fonte cai linear com a distância até o raio; a soma por casa vai até 1.
func _spread_pollution(world: WorldState, data: GameData, polluters: Array[int]) -> void:
	for source_id: int in polluters:
		var source := world.building(source_id)
		var def := data.building(source.def_id)
		var area := Footprint.rect(source.origin, def.size, source.rotation)
		for house_id: int in houses:
			var house := world.building(house_id)
			if house.island_id != source.island_id:
				continue
			var house_area := Footprint.rect(house.origin, data.building(house.def_id).size, house.rotation)
			var gap := _rect_gap(area, house_area)
			if gap <= def.pollution_radius_cells:
				var falloff := 1.0 - float(gap) / float(def.pollution_radius_cells + 1)
				pollution[house_id] = minf(1.0, pollution[house_id] + def.pollution_strength * falloff)


static func _rect_gap(a: Rect2i, b: Rect2i) -> int:
	var dx := maxi(0, maxi(a.position.x - b.end.x, b.position.x - a.end.x))
	var dy := maxi(0, maxi(a.position.y - b.end.y, b.position.y - a.end.y))
	return maxi(dx, dy)
