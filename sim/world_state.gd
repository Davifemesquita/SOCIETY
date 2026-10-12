class_name WorldState
extends RefCounted
## Estado completo do mundo: ilhas, economia e prédios. Só a simulação o altera.

enum TaxLevel { LOW, NORMAL, HIGH }

var islands: Array[IslandGrid] = []
var economies: Array[IslandEconomy] = []
var buildings: Dictionary[int, BuildingRecord] = {}
var next_building_id: int = 1
var money: float = 0.0
## Ticks de simulação desde o começo da partida (escolhe o grupo de casas da vez).
var tick: int = 0
## Nível de imposto por classe; classe ausente = normal.
var tax_levels: Dictionary[StringName, int] = {}

# runtime: recalculado a cada tick, fora do save
var income_per_min: float = 0.0
var upkeep_per_min: float = 0.0


func island(island_id: int) -> IslandGrid:
	return islands[island_id] if island_id >= 0 and island_id < islands.size() else null


func economy(island_id: int) -> IslandEconomy:
	return economies[island_id] if island_id >= 0 and island_id < economies.size() else null


func building(building_id: int) -> BuildingRecord:
	return buildings.get(building_id)


## Ids em ordem crescente, para varreduras determinísticas.
func building_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(buildings.keys())
	ids.sort()
	return ids


func tax_level(tier: StringName) -> int:
	return tax_levels.get(tier, TaxLevel.NORMAL)


## Moradores de uma classe em todas as ilhas (o que libera prédios).
func population(tier: StringName) -> int:
	var total := 0.0
	for record: BuildingRecord in buildings.values():
		if record.tier == tier:
			total += record.residents
	return floori(total)


## A ocupação não é salva: sai dos prédios. Estradas viram a lista de índices ocupados.
func to_dict() -> Dictionary:
	var island_list: Array[Dictionary] = []
	for index: int in islands.size():
		var grid := islands[index]
		var road_indices := PackedInt32Array()
		for i: int in grid.roads.size():
			if grid.roads[i] != IslandGrid.Road.NONE:
				road_indices.append(i)
		island_list.append({"size": grid.size, "roads": road_indices, "economy": economies[index].to_dict()})
	var building_list: Array[Dictionary] = []
	for building_id: int in building_ids():
		building_list.append(buildings[building_id].to_dict())
	return {"islands": island_list, "buildings": building_list, "next_building_id": next_building_id,
			"money": money, "tax_levels": tax_levels.duplicate(), "tick": tick}


## Reconstrói o mundo de um save. Devolve null se o conteúdo for inconsistente.
static func from_dict(data: Dictionary, game_data: GameData) -> WorldState:
	var world := WorldState.new()
	var raw_islands: Variant = data.get("islands")
	var raw_buildings: Variant = data.get("buildings")
	var raw_next: Variant = data.get("next_building_id")
	var raw_money: Variant = data.get("money")
	var raw_tax: Variant = data.get("tax_levels")
	var raw_tick: Variant = data.get("tick")
	if not (raw_islands is Array and raw_buildings is Array and raw_next is int and raw_money is float \
			and raw_tax is Dictionary and raw_tick is int):
		return null
	var island_list: Array = raw_islands
	for raw_island: Variant in island_list:
		if not world._restore_island(raw_island, game_data):
			return null
	var building_list: Array = raw_buildings
	for raw_building: Variant in building_list:
		if not raw_building is Dictionary:
			return null
		var building_data: Dictionary = raw_building
		var record := BuildingRecord.from_dict(building_data)
		if record == null or not world._restore_building(record, game_data):
			return null
	world.next_building_id = raw_next
	world.money = raw_money
	world.tick = raw_tick
	var tax_data: Dictionary = raw_tax
	for tier: Variant in tax_data:
		var level: Variant = tax_data[tier]
		if not (tier is StringName and level is int):
			return null
		var tier_id: StringName = tier
		if game_data.tier(tier_id) == null:
			return null
		var level_value: int = level
		if level_value < TaxLevel.LOW or level_value > TaxLevel.HIGH:
			return null
		world.tax_levels[tier_id] = level_value
	if not world.buildings.is_empty() and world.next_building_id <= world.building_ids().back():
		return null
	return world


func _restore_island(raw: Variant, game_data: GameData) -> bool:
	if not raw is Dictionary:
		return false
	var data: Dictionary = raw
	var raw_size: Variant = data.get("size")
	var raw_roads: Variant = data.get("roads")
	var raw_economy: Variant = data.get("economy")
	if not (raw_size is Vector2i and raw_roads is PackedInt32Array and raw_economy is Dictionary):
		return false
	var grid_size: Vector2i = raw_size
	if grid_size.x <= 0 or grid_size.y <= 0 or grid_size.x * grid_size.y > 4_000_000:
		return false
	var grid := IslandGrid.new(grid_size)
	var road_indices: PackedInt32Array = raw_roads
	for i: int in road_indices:
		if i < 0 or i >= grid.roads.size():
			return false
		grid.roads[i] = IslandGrid.Road.DIRT
	var economy_data: Dictionary = raw_economy
	var island_economy := IslandEconomy.from_dict(economy_data)
	if island_economy == null or game_data.profile(island_economy.profile_id) == null:
		return false
	islands.append(grid)
	economies.append(island_economy)
	return true


func _restore_building(record: BuildingRecord, game_data: GameData) -> bool:
	var def := game_data.building(record.def_id)
	var grid := island(record.island_id)
	if def == null or grid == null or buildings.has(record.id) or record.id <= 0:
		return false
	if (def.kind == BuildingDef.Kind.RESIDENCE) != record.is_house():
		return false
	if record.is_house() and game_data.tier(record.tier) == null:
		return false
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	if PlacementRules.check_area(grid, area) != &"":
		return false
	grid.fill_building(area, record.id)
	buildings[record.id] = record
	return true
