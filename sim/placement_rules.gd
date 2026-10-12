class_name PlacementRules
extends RefCounted
## Validação de construção. Devolve &"" quando pode, ou a chave de tradução do motivo.
## O terreno ainda é plano: a altura entra na Fase 5. Árvores, jazidas e rios valem como
## presentes até lá; o litoral já é a borda da ilha.

const OK := &""
const OUT_OF_ISLAND := &"REASON_OUT_OF_ISLAND"
const OCCUPIED := &"REASON_OCCUPIED"
const ON_ROAD := &"REASON_ON_ROAD"
const UNKNOWN_BUILDING := &"REASON_UNKNOWN_BUILDING"
const INVALID_ROTATION := &"REASON_INVALID_ROTATION"
const NEEDS_COAST := &"REASON_NEEDS_COAST"
const NO_FERTILITY := &"REASON_NO_FERTILITY"
const LOCKED := &"REASON_LOCKED"
const NO_MONEY := &"REASON_NO_MONEY"
const NO_MATERIALS := &"REASON_NO_MATERIALS"


static func check_area(grid: IslandGrid, area: Rect2i) -> StringName:
	if not grid.contains_rect(area):
		return OUT_OF_ISLAND
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if grid.building_at(cell) != 0:
				return OCCUPIED
			if grid.has_road(cell):
				return ON_ROAD
	return OK


static func check_building(grid: IslandGrid, def: BuildingDef, origin: Vector2i, rotation: int) -> StringName:
	if def == null:
		return UNKNOWN_BUILDING
	if rotation < 0 or rotation > 3:
		return INVALID_ROTATION
	return check_area(grid, Footprint.rect(origin, def.size, rotation))


## Estrada só vai em célula da ilha sem prédio. Célula que já é estrada passa (não duplica).
static func check_road_cell(grid: IslandGrid, cell: Vector2i) -> StringName:
	if not grid.in_bounds(cell):
		return OUT_OF_ISLAND
	if grid.building_at(cell) != 0:
		return OCCUPIED
	return OK


## Litoral = encostar na borda da ilha; fertilidade = cultura no perfil da ilha.
static func check_terrain(grid: IslandGrid, profile: IslandProfileDef, def: BuildingDef, origin: Vector2i, rotation: int) -> StringName:
	if def.terrain == BuildingDef.Terrain.COAST and not touches_coast(grid, Footprint.rect(origin, def.size, rotation)):
		return NEEDS_COAST
	if def.fertility != &"" and (profile == null or not profile.fertilities.has(def.fertility)):
		return NO_FERTILITY
	return OK


static func touches_coast(grid: IslandGrid, area: Rect2i) -> bool:
	return area.position.x == 0 or area.position.y == 0 or area.end.x == grid.size.x or area.end.y == grid.size.y


static func check_unlock(world: WorldState, def: BuildingDef) -> StringName:
	if def.unlock_tier != &"" and world.population(def.unlock_tier) < def.unlock_residents:
		return LOCKED
	return OK


## O saldo pode ficar negativo até o mínimo configurado; materiais precisam estar no estoque.
static func check_cost(world: WorldState, economy: IslandEconomy, config: GameConfig, money: int, materials: Dictionary[StringName, int]) -> StringName:
	if world.money - money < config.min_balance_to_build:
		return NO_MONEY
	if not economy.has_materials(materials):
		return NO_MATERIALS
	return OK
