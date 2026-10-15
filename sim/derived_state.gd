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
	## Lenhador: árvores no raio (as outras produções ficam com -1) e se bastam.
	var trees: int = -1
	var trees_ok: bool = true
	## Armazém que atende o prédio (0 = nenhum a até o alcance logístico).
	var warehouse_id: int = 0
	## Célula de estrada da frente por onde a carroça sai (-1 = nenhuma).
	var access_cell: int = -1
	var warehouse_distance: int = -1
	## Fábrica (Fase 11): usinas da ilha que a alcançam; vazio = fora de qualquer raio.
	var power_plants: Array[ProductionEntry] = []
	## Se alguma dessas usinas produzia no tick (o ProductionSystem atualiza).
	var powered: bool = false
	## Especialista posto no prédio (Fase 11), ou null.
	var specialist: Specialist

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
## Ilhas com pelo menos uma casa (as outras não têm necessidade a calcular).
var islands_with_houses: Dictionary[int, bool] = {}
var production: Array[int] = []
## Muda a cada recálculo: a logística confere as rotas das carroças quando ele muda.
var version: int = 0
var carts_checked: bool = false
## Armazéns e entrepostos ligados por estrada a um entreposto, por ilha.
var warehouses: Dictionary[int, Array] = {}
var warehouse_connected: Dictionary[int, bool] = {}
var ramps: Dictionary[int, int] = {}
## Células de estrada na frente de cada armazém.
var warehouse_cells: Dictionary[int, PackedInt32Array] = {}
var fields: Dictionary[int, WarehouseField] = {}
## Estoque por bem de cada ilha (o maior nível de entreposto dela).
var capacity: Dictionary[int, float] = {}
## Vagas de navio por ilha (Fase 6): os entrepostos e os píeres ligados por estrada a um deles,
## em ordem de id.
var berths: Dictionary[int, Array] = {}
var _routers: Dictionary[int, RoadRouter] = {}
var _world: WorldState
var _config: GameConfig
## Tempo de cada etapa do último recálculo, em ms (para o benchmark).
var last_rebuild_ms: Dictionary[String, float] = {}
var _mark: int = 0
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
	last_rebuild_ms.clear()
	_mark = Time.get_ticks_usec()
	version += 1
	carts_checked = false
	_world = world
	_config = config
	_routers.clear()
	warehouses.clear()
	warehouse_connected.clear()
	ramps.clear()
	warehouse_cells.clear()
	fields.clear()
	capacity.clear()
	berths.clear()
	road_access.clear()
	coverage.clear()
	module_count.clear()
	module_owner.clear()
	pollution.clear()
	service_houses.clear()
	service_reach.clear()
	houses.clear()
	islands_with_houses.clear()
	production.clear()
	production_entries.clear()
	consumers.clear()
	workforce_demand.clear()
	upkeep_per_min = 0.0
	var services: Array[int] = []
	var farms: Array[int] = []
	var polluters: Array[int] = []
	var depots: Array[int] = []
	var piers: Array[int] = []
	var modules: Dictionary[StringName, Array] = {}
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := data.building(record.def_id)
		road_access[building_id] = RoadNetwork.has_access(world.island(record.island_id), record, def)
		match def.kind:
			BuildingDef.Kind.RESIDENCE:
				houses.append(building_id)
				islands_with_houses[record.island_id] = true
				coverage[building_id] = []
				pollution[building_id] = 0.0
			BuildingDef.Kind.PRODUCTION:
				production.append(building_id)
				if def.modules_required > 0:
					farms.append(building_id)
			BuildingDef.Kind.SERVICE:
				services.append(building_id)
			BuildingDef.Kind.WAREHOUSE:
				depots.append(building_id)
			BuildingDef.Kind.PIER:
				piers.append(building_id)
			BuildingDef.Kind.MODULE:
				if not modules.has(def.id):
					modules[def.id] = []
				var same: Array = modules[def.id]
				same.append(building_id)
		if def.pollution_radius_cells > 0:
			polluters.append(building_id)
		upkeep_per_min += def.upkeep_per_min * (config.paused_upkeep_factor if record.paused else 1.0) \
				* upkeep_factor(world.specialists_state.at(building_id))
	for ship: Ship in world.ships.values():
		if ship.owner == Ship.Owner.PLAYER:
			upkeep_per_min += data.ship(ship.def_id).upkeep_per_min
	upkeep_per_min += world.specialists_state.salaries_per_min()
	_lap("prédios")
	var houses_at_road := _houses_by_front_cell(world, data)
	for service_id: int in services:
		_cover(world, data, config, service_id, houses_at_road)
	_lap("serviços")
	_assign_modules(world, data, farms, modules)
	_spread_pollution(world, data, polluters)
	_lap("módulos e poluição")
	_index_warehouses(world, data, config, depots, piers)
	_lap("armazéns")
	_index_production(world, data)
	_assign_warehouses(world, config)
	_lap("produção")
	_group_houses(world, config)
	_lap("grupos de casas")


func _lap(step: String) -> void:
	var now := Time.get_ticks_usec()
	last_rebuild_ms[step] = (now - _mark) / 1000.0
	_mark = now


## Armazéns ligados a um entreposto (mesma rede de estrada), rampas, estoque da ilha e o campo
## de distância de cada ilha.
func _index_warehouses(world: WorldState, data: GameData, config: GameConfig, candidates: Array[int], piers: Array[int]) -> void:
	var labels_by_island: Dictionary[int, PackedInt32Array] = {}
	var posts_by_island: Dictionary[int, Dictionary] = {}
	for building_id: int in candidates:
		var record := world.building(building_id)
		var def := data.building(record.def_id)
		var grid := world.island(record.island_id)
		var cells := PackedInt32Array()
		for index: int in Footprint.front_indices(grid.size, record.origin, def.size, record.rotation):
			if grid.roads[index] != IslandGrid.Road.NONE:
				cells.append(index)
		warehouse_cells[building_id] = cells
		ramps[building_id] = def.level(record.level).ramps
		if not labels_by_island.has(record.island_id):
			labels_by_island[record.island_id] = RoadNetwork.components(grid)
			posts_by_island[record.island_id] = {}
		if def.is_trading_post:
			var island_capacity: float = capacity.get(record.island_id, 0.0)
			capacity[record.island_id] = maxf(island_capacity, def.level(record.level).storage_capacity_t)
			var posts: Dictionary = posts_by_island[record.island_id]
			var labels := labels_by_island[record.island_id]
			for index: int in cells:
				posts[labels[index]] = true
	for building_id: int in candidates:
		var record := world.building(building_id)
		var posts: Dictionary = posts_by_island[record.island_id]
		var labels := labels_by_island[record.island_id]
		var connected := false
		for index: int in warehouse_cells[building_id]:
			if posts.has(labels[index]):
				connected = true
		warehouse_connected[building_id] = connected
		if connected:
			if not warehouses.has(record.island_id):
				warehouses[record.island_id] = []
			var list: Array = warehouses[record.island_id]
			list.append(building_id)
	_index_berths(world, data, candidates, piers, labels_by_island, posts_by_island)
	for island_id: int in world.islands.size():
		if not capacity.has(island_id):
			capacity[island_id] = float(config.island_storage_capacity_t)
		var sources: Array[Vector2i] = []
		var list: Array = warehouses.get(island_id, [])
		for warehouse_id: int in list:
			for index: int in warehouse_cells[warehouse_id]:
				sources.append(Vector2i(index, warehouse_id))
		fields[island_id] = WarehouseField.new(world.island(island_id), sources)


## Vagas de navio: todo entreposto, e o píer cuja frente encosta numa estrada da rede de um
## entreposto da ilha.
func _index_berths(world: WorldState, data: GameData, depots: Array[int], piers: Array[int],
		labels_by_island: Dictionary[int, PackedInt32Array], posts_by_island: Dictionary[int, Dictionary]) -> void:
	for building_id: int in depots:
		var record := world.building(building_id)
		if data.building(record.def_id).is_trading_post:
			_add_berth(record.island_id, building_id)
	for building_id: int in piers:
		var record := world.building(building_id)
		if not posts_by_island.has(record.island_id):
			continue
		var def := data.building(record.def_id)
		var grid := world.island(record.island_id)
		var labels := labels_by_island[record.island_id]
		var posts: Dictionary = posts_by_island[record.island_id]
		for cell: Vector2i in Footprint.front_cells(record.origin, def.size, record.rotation):
			if grid.has_road(cell) and posts.has(labels[grid.index(cell)]):
				_add_berth(record.island_id, building_id)
				break
	for list: Array in berths.values():
		list.sort()


func _add_berth(island_id: int, building_id: int) -> void:
	if not berths.has(island_id):
		berths[island_id] = []
	var list: Array = berths[island_id]
	list.append(building_id)


## Cada prédio de produção fica com o armazém mais próximo pela estrada, se estiver no alcance.
func _assign_warehouses(world: WorldState, config: GameConfig) -> void:
	for entry: ProductionEntry in production_entries:
		var grid := world.island(entry.record.island_id)
		var roads := grid.roads
		var field := fields[entry.record.island_id]
		var front := Footprint.front_indices(grid.size, entry.record.origin, entry.def.size, entry.record.rotation)
		var best := -1
		for index: int in front:
			if roads[index] == IslandGrid.Road.NONE:
				continue
			if field.distance[index] >= 0 and (best == -1 or field.distance[index] < field.distance[best]):
				best = index
		if best == -1:
			for index: int in front:
				if roads[index] != IslandGrid.Road.NONE:
					entry.access_cell = index
					break
			continue
		entry.access_cell = best
		entry.warehouse_distance = field.distance[best]
		if field.distance[best] <= config.logistics_range_cells:
			entry.warehouse_id = field.owner[best]


func router(island_id: int) -> RoadRouter:
	if not _routers.has(island_id):
		_routers[island_id] = RoadRouter.new(_world.island(island_id), _config.paved_road_speed_bonus)
	return _routers[island_id]


## Fração da manutenção do prédio que sobra com o especialista dele (Fase 11).
static func upkeep_factor(specialist: Specialist) -> float:
	if specialist == null or specialist.def.effect != SpecialistDef.Effect.UPKEEP:
		return 1.0
	return 1.0 - specialist.def.amount


func entry_of(building_id: int) -> ProductionEntry:
	for entry: ProductionEntry in production_entries:
		if entry.record.id == building_id:
			return entry
	return null


## A célula de estrada do armazém mais perto (em linha reta) de uma célula, para destino da rota.
func warehouse_target(warehouse_id: int, near: int, grid: IslandGrid) -> int:
	var cells: PackedInt32Array = warehouse_cells.get(warehouse_id, PackedInt32Array())
	var best := -1
	var best_gap := 0
	var origin := grid.cell_at(near)
	for index: int in cells:
		var gap := (grid.cell_at(index) - origin).abs()
		if best == -1 or gap.x + gap.y < best_gap:
			best = index
			best_gap = gap.x + gap.y
	return best


func _index_production(world: WorldState, data: GameData) -> void:
	for building_id: int in production:
		var entry := ProductionEntry.new()
		entry.record = world.building(building_id)
		entry.def = data.building(entry.record.def_id)
		entry.economy = world.economy(entry.record.island_id)
		entry.has_road = road_access[building_id]
		entry.specialist = world.specialists_state.at(building_id)
		entry.modules_ok = module_count.get(building_id, 0) >= entry.def.modules_required
		var grid := world.island(entry.record.island_id)
		if entry.def.terrain == BuildingDef.Terrain.TREES and not grid.flat:
			var area := Footprint.rect(entry.record.origin, entry.def.size, entry.record.rotation)
			entry.trees = grid.trees_in(area.grow(_config.lumberjack_radius_cells))
			entry.trees_ok = entry.trees >= _config.lumberjack_min_trees
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
	_wire_power()


## Liga cada fábrica às usinas da mesma ilha cujo raio a alcança (folga entre os retângulos).
func _wire_power() -> void:
	var plants: Array[ProductionEntry] = []
	for entry: ProductionEntry in production_entries:
		if entry.def.is_power_plant():
			plants.append(entry)
	if plants.is_empty():
		return
	for entry: ProductionEntry in production_entries:
		if not entry.def.is_electrifiable():
			continue
		var area := Footprint.rect(entry.record.origin, entry.def.size, entry.record.rotation)
		for plant: ProductionEntry in plants:
			if plant.record.island_id != entry.record.island_id:
				continue
			var reach := Footprint.rect(plant.record.origin, plant.def.size, plant.record.rotation)
			if _rect_gap(reach, area) <= plant.def.power_radius_cells:
				entry.power_plants.append(plant)


## Se a ilha tem usina (o painel da fábrica só fala de eletricidade com uma).
func has_power_plant(island_id: int) -> bool:
	for entry: ProductionEntry in production_entries:
		if entry.record.island_id == island_id and entry.def.is_power_plant():
			return true
	return false


## Fábricas que a usina alcança (painel da usina).
func powered_by(plant_id: int) -> Array[ProductionEntry]:
	var result: Array[ProductionEntry] = []
	for entry: ProductionEntry in production_entries:
		for plant: ProductionEntry in entry.power_plants:
			if plant.record.id == plant_id:
				result.append(entry)
				break
	return result


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


## Ids dos serviços (a multidão procura o mais perto).
func services_list() -> Array[int]:
	var ids: Array[int] = []
	for service_id: int in service_houses:
		ids.append(service_id)
	return ids


## Ids dos armazéns e entrepostos de todas as ilhas.
func warehouses_list() -> Array[int]:
	var ids: Array[int] = []
	for list: Array in warehouses.values():
		for building_id: Variant in list:
			ids.append(building_id)
	return ids


func has_road(building_id: int) -> bool:
	return road_access.get(building_id, false)


func covered_by(house_id: int, service_def: StringName) -> bool:
	var services: Array = coverage.get(house_id, [])
	return services.has(service_def)


## Chave de uma célula de uma ilha nos mapas por célula.
static func _cell_key(island_id: int, index: int) -> int:
	return (island_id << 32) | index


## Célula da frente de cada casa → casas que encostam nela.
func _houses_by_front_cell(world: WorldState, data: GameData) -> Dictionary[int, Array]:
	var map: Dictionary[int, Array] = {}
	for house_id: int in houses:
		var house := world.building(house_id)
		var grid := world.island(house.island_id)
		for index: int in Footprint.front_indices(grid.size, house.origin, data.building(house.def_id).size, house.rotation):
			var key := _cell_key(house.island_id, index)
			if not map.has(key):
				map[key] = []
			var list: Array = map[key]
			if not list.has(house_id):
				list.append(house_id)
	return map


## Cobertura de um serviço: estrada alcançada dentro do raio e as casas que encostam nela.
func _cover(world: WorldState, data: GameData, config: GameConfig, service_id: int, houses_at_road: Dictionary[int, Array]) -> void:
	var record := world.building(service_id)
	var def := data.building(record.def_id)
	var grid := world.island(record.island_id)
	var front := Footprint.front_cells(record.origin, def.size, record.rotation)
	var reach := ServiceReach.road_cells(grid, front, ServiceReach.radius_of(def, config))
	service_reach[service_id] = reach
	var covered: Array[int] = []
	for index: int in reach:
		var touching: Array = houses_at_road.get(_cell_key(record.island_id, index), [])
		for house_id: int in touching:
			if not covered.has(house_id):
				covered.append(house_id)
				var services: Array = coverage[house_id]
				if not services.has(def.id):
					services.append(def.id)
	covered.sort()
	service_houses[service_id] = covered


## Cada módulo serve a uma fazenda só: a de menor id que o tem no raio e ainda precisa dele.
func _assign_modules(world: WorldState, data: GameData, farms: Array[int], modules: Dictionary[StringName, Array]) -> void:
	for farm_id: int in farms:
		var farm := world.building(farm_id)
		var def := data.building(farm.def_id)
		var reach := Footprint.rect(farm.origin, def.size, farm.rotation).grow(def.module_radius_cells)
		var count := 0
		var candidates: Array = modules.get(def.module_id, [])
		for building_id: int in candidates:
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
