class_name PlacementRules
extends RefCounted
## Validação de construção. Devolve &"" quando pode, ou a chave de tradução do motivo.
## Terreno (Fase 5): área plana (até max_build_height_delta_m), toda em terra; litoral e rio
## pelo chão da grade; mina sobre a jazida do bem dela. Na ilha plana de antes (testes e saves
## antigos) árvores, jazidas e rios valem como presentes e o litoral é a borda.

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
const NEEDS_TRADING_POST := &"REASON_NEEDS_TRADING_POST"
const ON_WATER := &"REASON_ON_WATER"
const NOT_FLAT := &"REASON_NOT_FLAT"
const NEEDS_DEPOSIT := &"REASON_NEEDS_DEPOSIT"
const NEEDS_RIVER_OR_COAST := &"REASON_NEEDS_RIVER_OR_COAST"
const TOO_STEEP := &"REASON_TOO_STEEP"
const NEEDS_SHIP := &"REASON_NEEDS_SHIP"
const ISLAND_LOCKED := &"REASON_ISLAND_LOCKED"
const TROPICAL_LOCKED := &"REASON_TROPICAL_LOCKED"
const SHIP_LIMIT := &"REASON_SHIP_LIMIT"
## Folga do ponto flutuante na diferença de altura.
const _HEIGHT_EPSILON := 0.0001


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


## Estrada só vai em célula da ilha sem prédio, fora do mar e sem barranco. Célula que já é
## estrada passa (não duplica); sobre o rio, a estrada é ponte.
static func check_road_cell(grid: IslandGrid, cell: Vector2i, config: GameConfig = null) -> StringName:
	if not grid.in_bounds(cell):
		return OUT_OF_ISLAND
	if grid.building_at(cell) != 0:
		return OCCUPIED
	if grid.flat:
		return OK
	var ground := grid.ground_at(cell)
	if ground == IslandGrid.Ground.SEA:
		return ON_WATER
	var max_relief := config.max_road_relief_m if config != null else GameConfig.get_default().max_road_relief_m
	if ground == IslandGrid.Ground.LAND and grid.area_relief(Rect2i(cell, Vector2i.ONE)) > max_relief + _HEIGHT_EPSILON:
		return TOO_STEEP
	return OK


## Terreno do prédio: plano e em terra, litoral, rio ou jazida quando pedidos, e a fertilidade
## no perfil da ilha.
static func check_terrain(grid: IslandGrid, profile: IslandProfileDef, def: BuildingDef, origin: Vector2i, rotation: int,
		config: GameConfig = null) -> StringName:
	var area := Footprint.rect(origin, def.size, rotation)
	if grid.flat:
		if def.terrain == BuildingDef.Terrain.COAST and not touches_coast(grid, area):
			return NEEDS_COAST
	else:
		if not grid.area_is_land(area):
			return ON_WATER
		var max_delta := config.max_build_height_delta_m if config != null else GameConfig.get_default().max_build_height_delta_m
		if grid.area_relief(area) > max_delta + _HEIGHT_EPSILON:
			return NOT_FLAT
		match def.terrain:
			BuildingDef.Terrain.COAST:
				if not grid.area_touches(area, IslandGrid.Ground.SEA):
					return NEEDS_COAST
			BuildingDef.Terrain.RIVER_OR_COAST:
				if not (grid.area_touches(area, IslandGrid.Ground.SEA) or grid.area_touches(area, IslandGrid.Ground.RIVER)):
					return NEEDS_RIVER_OR_COAST
			BuildingDef.Terrain.DEPOSIT:
				if def.deposit != &"" and not grid.area_on_deposit(area, def.deposit):
					return NEEDS_DEPOSIT
	if def.fertility != &"" and (profile == null or not profile.fertilities.has(def.fertility)):
		return NO_FERTILITY
	return OK


## Ilha plana: litoral é encostar na borda.
static func touches_coast(grid: IslandGrid, area: Rect2i) -> bool:
	return area.position.x == 0 or area.position.y == 0 or area.end.x == grid.size.x or area.end.y == grid.size.y


## Sem entreposto na ilha, só o entreposto pode ser construído.
static func check_trading_post(world: WorldState, data: GameData, island_id: int, def: BuildingDef) -> StringName:
	if def != null and not def.is_trading_post and not world.has_trading_post(island_id, data):
		return NEEDS_TRADING_POST
	return OK


## Entreposto numa ilha ainda sem entreposto, que não é o primeiro do jogo: colonização (seção 7).
static func founds_colony(world: WorldState, data: GameData, island_id: int, def: BuildingDef) -> bool:
	return def != null and def.is_trading_post and world.any_trading_post(data) and not world.has_trading_post(island_id, data)


## Colonizar: o marco de população libera a ilha, um navio do jogador ancorado nela traz os
## materiais e o caixa paga o resto.
static func check_colony(world: WorldState, data: GameData, config: GameConfig, island_id: int, def: BuildingDef) -> StringName:
	if world.colonized_islands(data).size() >= MilestoneSystem.island_limit(world, config):
		return ISLAND_LOCKED
	if world.is_tropical(island_id, data) and world.milestones_reached < config.tropical_milestone:
		return TROPICAL_LOCKED
	if world.money - def.cost_money < config.min_balance_for(world.difficulty):
		return NO_MONEY
	if colony_ship(world, island_id, def.cost_materials) != null:
		return OK
	for ship: Ship in world.player_ships():
		if ship.at == island_id and ship.state != Ship.State.SAILING:
			return NO_MATERIALS
	return NEEDS_SHIP


## O primeiro navio do jogador ancorado na ilha com os materiais a bordo, ou null.
static func colony_ship(world: WorldState, island_id: int, materials: Dictionary[StringName, int]) -> Ship:
	for ship: Ship in world.player_ships():
		if ship.at != island_id or ship.state == Ship.State.SAILING:
			continue
		var enough := true
		for material: StringName in materials:
			if ship.tons_of(material) + 0.000001 < materials[material]:
				enough = false
		if enough:
			return ship
	return null


## Comprar navio: o marco libera mais um, e o estoque da ilha e o caixa pagam.
static func check_ship_purchase(world: WorldState, data: GameData, config: GameConfig, island_id: int, def: ShipDef) -> StringName:
	if def == null:
		return UNKNOWN_BUILDING
	if not world.has_trading_post(island_id, data):
		return NEEDS_TRADING_POST
	if world.player_ships().size() >= MilestoneSystem.ship_limit(world, config):
		return SHIP_LIMIT
	return check_cost(world, world.economy(island_id), config, def.cost_money, def.cost_materials)


static func check_unlock(world: WorldState, def: BuildingDef) -> StringName:
	if def.unlock_tier != &"" and world.population(def.unlock_tier) < def.unlock_residents:
		return LOCKED
	return OK


## O saldo pode ficar negativo até o mínimo configurado; materiais precisam estar no estoque.
static func check_cost(world: WorldState, economy: IslandEconomy, config: GameConfig, money: int, materials: Dictionary[StringName, int]) -> StringName:
	if world.money - money < config.min_balance_for(world.difficulty):
		return NO_MONEY
	if not economy.has_materials(materials):
		return NO_MATERIALS
	return OK
