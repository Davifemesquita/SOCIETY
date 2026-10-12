class_name WorldState
extends RefCounted
## Estado completo do mundo: ilhas e prédios. Só a simulação o altera, por comandos.

var islands: Array[IslandGrid] = []
var buildings: Dictionary[int, BuildingRecord] = {}
var next_building_id: int = 1


func island(island_id: int) -> IslandGrid:
	return islands[island_id] if island_id >= 0 and island_id < islands.size() else null


func building(building_id: int) -> BuildingRecord:
	return buildings.get(building_id)


## Ids em ordem crescente, para varreduras determinísticas.
func building_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(buildings.keys())
	ids.sort()
	return ids


## A ocupação não é salva: sai dos prédios. Estradas viram a lista de índices ocupados.
func to_dict() -> Dictionary:
	var island_list: Array[Dictionary] = []
	for grid: IslandGrid in islands:
		var road_indices := PackedInt32Array()
		for i: int in grid.roads.size():
			if grid.roads[i] != IslandGrid.Road.NONE:
				road_indices.append(i)
		island_list.append({"size": grid.size, "roads": road_indices})
	var building_list: Array[Dictionary] = []
	for building_id: int in building_ids():
		building_list.append(buildings[building_id].to_dict())
	return {"islands": island_list, "buildings": building_list, "next_building_id": next_building_id}


## Reconstrói o mundo de um save. Devolve null se o conteúdo for inconsistente.
static func from_dict(data: Dictionary, catalog: BuildingCatalog) -> WorldState:
	var world := WorldState.new()
	var raw_islands: Variant = data.get("islands")
	var raw_buildings: Variant = data.get("buildings")
	var raw_next: Variant = data.get("next_building_id")
	if not (raw_islands is Array and raw_buildings is Array and raw_next is int):
		return null
	var island_list: Array = raw_islands
	for raw_island: Variant in island_list:
		var grid := _island_from(raw_island)
		if grid == null:
			return null
		world.islands.append(grid)
	var building_list: Array = raw_buildings
	for raw_building: Variant in building_list:
		if not raw_building is Dictionary:
			return null
		var building_data: Dictionary = raw_building
		var record := BuildingRecord.from_dict(building_data)
		if record == null or not world._restore_building(record, catalog):
			return null
	world.next_building_id = raw_next
	if not world.buildings.is_empty() and world.next_building_id <= world.building_ids().back():
		return null
	return world


static func _island_from(raw: Variant) -> IslandGrid:
	if not raw is Dictionary:
		return null
	var data: Dictionary = raw
	var raw_size: Variant = data.get("size")
	var raw_roads: Variant = data.get("roads")
	if not (raw_size is Vector2i and raw_roads is PackedInt32Array):
		return null
	var grid_size: Vector2i = raw_size
	if grid_size.x <= 0 or grid_size.y <= 0 or grid_size.x * grid_size.y > 4_000_000:
		return null
	var grid := IslandGrid.new(grid_size)
	var road_indices: PackedInt32Array = raw_roads
	for i: int in road_indices:
		if i < 0 or i >= grid.roads.size():
			return null
		grid.roads[i] = IslandGrid.Road.DIRT
	return grid


func _restore_building(record: BuildingRecord, catalog: BuildingCatalog) -> bool:
	var def := catalog.find(record.def_id)
	var grid := island(record.island_id)
	if def == null or grid == null or buildings.has(record.id) or record.id <= 0:
		return false
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	if PlacementRules.check_area(grid, area) != &"":
		return false
	grid.fill_building(area, record.id)
	buildings[record.id] = record
	return true
