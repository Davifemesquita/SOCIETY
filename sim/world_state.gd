class_name WorldState
extends RefCounted
## Estado completo do mundo: ilhas, economia e prédios. Só a simulação o altera.

enum TaxLevel { LOW, NORMAL, HIGH }

var islands: Array[IslandGrid] = []
var economies: Array[IslandEconomy] = []
var buildings: Dictionary[int, BuildingRecord] = {}
## Carroça de cada prédio de produção, pelo id do prédio.
var carts: Dictionary[int, Cart] = {}
var next_building_id: int = 1
var money: float = 0.0
## Ticks de simulação desde o começo da partida (escolhe o grupo de casas da vez).
var tick: int = 0
## Nível de imposto por classe; classe ausente = normal.
var tax_levels: Dictionary[StringName, int] = {}
## Semente do arquipélago e a versão do gerador (0 = a ilha plana de antes da Fase 5).
var seed: int = 0
var terrain_version: int = 0
## O terreno refeito da semente não bateu com a assinatura do save (outra plataforma, outro
## ponto flutuante). Só aviso: a partida segue.
var terrain_mismatch: bool = false

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


func cart(building_id: int) -> Cart:
	return carts.get(building_id)


## Há entreposto nesta ilha (sem ele não se constrói nada nela).
func has_trading_post(island_id: int, data: GameData) -> bool:
	for record: BuildingRecord in buildings.values():
		if record.island_id == island_id and data.building(record.def_id).is_trading_post:
			return true
	return false


func any_trading_post(data: GameData) -> bool:
	for record: BuildingRecord in buildings.values():
		if data.building(record.def_id).is_trading_post:
			return true
	return false


## Altura do chão num ponto do mundo (x, z): o terreno da ilha que o contém, e o mar (0) fora
## delas e debaixo d'água. A câmera mira e anda nesta altura.
func surface_height(x_m: float, z_m: float) -> float:
	for grid: IslandGrid in islands:
		var rect := grid.world_rect()
		if x_m >= rect.position.x and z_m >= rect.position.y and x_m < rect.end.x and z_m < rect.end.y:
			return maxf(grid.height_at(x_m, z_m), 0.0)
	return 0.0


func tax_level(tier: StringName) -> int:
	return tax_levels.get(tier, TaxLevel.NORMAL)


## Moradores de uma classe em todas as ilhas (o que libera prédios).
func population(tier: StringName) -> int:
	var total := 0.0
	for record: BuildingRecord in buildings.values():
		if record.tier == tier:
			total += record.residents
	return floori(total)


## A ocupação não é salva: sai dos prédios. Estradas viram a lista de índices ocupados. O terreno
## gerado também não: sai da semente; vão só as árvores que a construção derrubou.
func to_dict() -> Dictionary:
	var island_list: Array[Dictionary] = []
	for index: int in islands.size():
		var grid := islands[index]
		var road_indices := PackedInt32Array()
		for i: int in grid.roads.size():
			if grid.roads[i] != IslandGrid.Road.NONE:
				road_indices.append(i)
		var cleared := PackedInt32Array()
		for i: int in grid.cleared_trees.size():
			if grid.cleared_trees[i] == 1:
				cleared.append(i)
		island_list.append({"size": grid.size, "roads": road_indices, "economy": economies[index].to_dict(),
				"cleared_trees": cleared, "fingerprint": grid.fingerprint})
	var building_list: Array[Dictionary] = []
	var cart_list: Array[Dictionary] = []
	for building_id: int in building_ids():
		building_list.append(buildings[building_id].to_dict())
		if carts.has(building_id):
			cart_list.append(carts[building_id].to_dict())
	return {"islands": island_list, "buildings": building_list, "next_building_id": next_building_id,
			"money": money, "tax_levels": tax_levels.duplicate(), "tick": tick, "carts": cart_list,
			"seed": seed, "terrain_version": terrain_version}


## Reconstrói o mundo de um save. Devolve null se o conteúdo for inconsistente. O terreno gerado
## sai de novo da semente (com o config do jogo, ou o dado).
static func from_dict(data: Dictionary, game_data: GameData, config: GameConfig = null) -> WorldState:
	var world := WorldState.new()
	var raw_seed: Variant = data.get("seed")
	var raw_version: Variant = data.get("terrain_version")
	if not (raw_seed is int and raw_version is int):
		return null
	world.seed = raw_seed
	world.terrain_version = raw_version
	if world.terrain_version != 0 and world.terrain_version != ArchipelagoGenerator.VERSION:
		return null
	var generated: Array[IslandGrid] = []
	if world.terrain_version != 0:
		var game_config := config if config != null else GameConfig.get_default()
		for spec: ArchipelagoGenerator.IslandSpec in ArchipelagoGenerator.layout(world.seed, game_config, game_data):
			generated.append(ArchipelagoGenerator.build_island(spec, game_config))
	var raw_islands: Variant = data.get("islands")
	var raw_buildings: Variant = data.get("buildings")
	var raw_next: Variant = data.get("next_building_id")
	var raw_money: Variant = data.get("money")
	var raw_tax: Variant = data.get("tax_levels")
	var raw_tick: Variant = data.get("tick")
	var raw_carts: Variant = data.get("carts")
	if not (raw_islands is Array and raw_buildings is Array and raw_next is int and raw_money is float \
			and raw_tax is Dictionary and raw_tick is int and raw_carts is Array):
		return null
	var island_list: Array = raw_islands
	if world.terrain_version != 0 and island_list.size() != generated.size():
		return null
	for index: int in island_list.size():
		if not world._restore_island(island_list[index], game_data, generated[index] if world.terrain_version != 0 else null):
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
	var cart_list: Array = raw_carts
	for raw_cart: Variant in cart_list:
		if not raw_cart is Dictionary:
			return null
		var cart_data: Dictionary = raw_cart
		var cart := Cart.from_dict(cart_data)
		if cart == null or world.carts.has(cart.home_id):
			return null
		var home := world.building(cart.home_id)
		if home == null or not game_data.building(home.def_id).is_production():
			return null
		world.carts[cart.home_id] = cart
	for building_id: int in world.building_ids():
		if game_data.building(world.buildings[building_id].def_id).is_production() and not world.carts.has(building_id):
			return null
	return world


## Ilha do save: a plana é criada do tamanho salvo; a gerada já vem pronta (da semente) e o save
## só confere o tamanho e põe as estradas e as árvores derrubadas.
func _restore_island(raw: Variant, game_data: GameData, generated: IslandGrid) -> bool:
	if not raw is Dictionary:
		return false
	var data: Dictionary = raw
	var raw_size: Variant = data.get("size")
	var raw_roads: Variant = data.get("roads")
	var raw_economy: Variant = data.get("economy")
	var raw_cleared: Variant = data.get("cleared_trees")
	if not (raw_size is Vector2i and raw_roads is PackedInt32Array and raw_economy is Dictionary and raw_cleared is PackedInt32Array):
		return false
	var grid_size: Vector2i = raw_size
	if grid_size.x <= 0 or grid_size.y <= 0 or grid_size.x * grid_size.y > 4_000_000:
		return false
	if generated != null and generated.size != grid_size:
		return false
	var grid := generated if generated != null else IslandGrid.new(grid_size)
	var road_indices: PackedInt32Array = raw_roads
	for i: int in road_indices:
		if i < 0 or i >= grid.roads.size():
			return false
		grid.roads[i] = IslandGrid.Road.DIRT
	var raw_fingerprint: Variant = data.get("fingerprint")
	if generated != null and raw_fingerprint is int and raw_fingerprint != generated.fingerprint:
		terrain_mismatch = true
		push_warning("WorldState: o terreno refeito da semente não bate com a assinatura do save")
	var cleared: PackedInt32Array = raw_cleared
	for i: int in cleared:
		if i < 0 or i >= grid.roads.size() or grid.trees.is_empty():
			return false
		grid.trees[i] = 0
		grid.cleared_trees[i] = 1
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
