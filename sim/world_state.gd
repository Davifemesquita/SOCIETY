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
## Navios (do jogador e o do comerciante) e rotas comerciais (Fase 6).
var ships: Dictionary[int, Ship] = {}
var next_ship_id: int = 1
var routes: Dictionary[int, TradeRoute] = {}
var next_route_id: int = 1
var trader := TraderState.new()
## Marcos de população já atingidos (seção 3).
var milestones_reached: int = 0
## Metas guiadas cumpridas (Fase 8): a próxima é GameData.goals[goals_done].
var goals_done: int = 0
## Save de antes das metas: na primeira conferência, as metas já cumpridas passam sem prêmio.
var goals_catch_up: bool = false
## Semente do arquipélago e a versão do gerador (0 = a ilha plana de antes da Fase 5).
var seed: int = 0
var terrain_version: int = 0
## O terreno refeito da semente não bateu com a assinatura do save (outra plataforma, outro
## ponto flutuante). Só aviso: a partida segue.
var terrain_mismatch: bool = false
## Dificuldade escolhida no jogo novo (0 fácil, 1 normal, 2 difícil): o limite do saldo negativo.
var difficulty: int = 1
## Série histórica das estatísticas (gráficos).
var history := StatisticsHistory.new()
## Eventos e encomendas (Fase 11); desligados em mundo novo da simulação.
var events_state := EventsState.new()
## Companhias rivais (Fase 11); desligadas em mundo novo da simulação.
var rivals_state := RivalsState.new()
## Especialistas contratados e a oferta do comerciante (Fase 11).
var specialists_state := SpecialistsState.new()
## Incêndio e doença (seção 8); desligados em mundo novo da simulação.
var risks_state := RisksState.new()
## Encomendas dos estaleiros.
var shipyard_state := ShipyardState.new()
## Peças do zoológico e do museu (Fase 67).
var exhibits_state := ExhibitsState.new()
## Expedições em andamento (Fase 69): o navio que viaja fica aqui, fora de ships.
var expeditions_state := ExpeditionsState.new()
## Objetivo da partida (Fase 12); partida livre em mundo novo.
var victory_state := VictoryState.new()
## Plantas (Fase 49): prédios desenhados, sem custo, que ainda não existem.
var plans: Dictionary[int, PlanRecord] = {}
var next_plan_id: int = 1

# runtime: recalculado a cada tick, fora do save
var income_per_min: float = 0.0
var upkeep_per_min: float = 0.0
## Renda dos acordos comerciais com rivais (Fase 11), já somada em income_per_min.
var treaty_income_per_min: float = 0.0
## Renda do turismo (Fase 68), já somada em income_per_min.
var tourism_per_min: float = 0.0


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


func ship(ship_id: int) -> Ship:
	return ships.get(ship_id)


## Ids dos navios em ordem crescente (o sistema dos navios anda nesta ordem).
func ship_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(ships.keys())
	ids.sort()
	return ids


## Navios do jogador (sem o do comerciante), em ordem de id.
func player_ships() -> Array[Ship]:
	var list: Array[Ship] = []
	for ship_id: int in ship_ids():
		if ships[ship_id].owner == Ship.Owner.PLAYER:
			list.append(ships[ship_id])
	return list


func route_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(routes.keys())
	ids.sort()
	return ids


## Ilhas que já têm entreposto.
func colonized_islands(data: GameData) -> Array[int]:
	var list: Array[int] = []
	for island_id: int in islands.size():
		if has_trading_post(island_id, data):
			list.append(island_id)
	return list


## O navio inicial com a carga do começo, ancorado na ilha principal (posto no mar pela
## simulação). Sem navio inicial na configuração, a carga vai direto para o estoque.
func add_starting_fleet(config: GameConfig, data: GameData) -> void:
	var def := data.ship(config.starting_ship)
	if def == null:
		for material: StringName in config.starting_materials:
			economies[0].stock[material] = float(config.starting_materials[material])
		return
	var first := Ship.new(next_ship_id, def)
	next_ship_id += 1
	first.at = 0
	for material: StringName in config.starting_materials:
		var tons := float(config.starting_materials[material])
		var loaded := first.load_good(material, tons, def.slot_capacity_t)
		if loaded < tons:
			economies[0].stock[material] = tons - loaded
	ships[first.id] = first


## Preço do comerciante nesta volta para o bem, com a feira (Fase 11) em andamento.
func trader_price(data: GameData, config: GameConfig, good: StringName) -> float:
	var unit := TraderState.price(seed, trader.tour, data.good(good), config.trader_price_variation)
	return unit * EventEffects.price(events_state, good) if not events_state.events.is_empty() else unit


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
		var paved_indices := PackedInt32Array()
		for i: int in grid.roads.size():
			if grid.roads[i] != IslandGrid.Road.NONE:
				road_indices.append(i)
			if grid.roads[i] == IslandGrid.Road.PAVED:
				paved_indices.append(i)
		var cleared := PackedInt32Array()
		for i: int in grid.cleared_trees.size():
			if grid.cleared_trees[i] == 1:
				cleared.append(i)
		var rail_indices := PackedInt32Array()
		for i: int in grid.rails.size():
			if grid.rails[i] != 0:
				rail_indices.append(i)
		island_list.append({"size": grid.size, "roads": road_indices, "paved": paved_indices, "economy": economies[index].to_dict(),
				"cleared_trees": cleared, "fingerprint": grid.fingerprint, "origin": grid.origin_m, "rails": rail_indices})
	var building_list: Array[Dictionary] = []
	var cart_list: Array[Dictionary] = []
	for building_id: int in building_ids():
		building_list.append(buildings[building_id].to_dict())
		if carts.has(building_id):
			cart_list.append(carts[building_id].to_dict())
	var ship_list: Array[Dictionary] = []
	for ship_id: int in ship_ids():
		ship_list.append(ships[ship_id].to_dict())
	var route_list: Array[Dictionary] = []
	for route_id: int in route_ids():
		route_list.append(routes[route_id].to_dict())
	var plan_ids: Array[int] = []
	plan_ids.assign(plans.keys())
	plan_ids.sort()
	var plan_list: Array[Dictionary] = []
	for plan_id: int in plan_ids:
		plan_list.append(plans[plan_id].to_dict())
	return {"islands": island_list, "buildings": building_list, "next_building_id": next_building_id,
			"money": money, "tax_levels": tax_levels.duplicate(), "tick": tick, "carts": cart_list,
			"seed": seed, "terrain_version": terrain_version, "ships": ship_list, "next_ship_id": next_ship_id,
			"routes": route_list, "next_route_id": next_route_id, "trader": trader.to_dict(),
			"milestones_reached": milestones_reached, "difficulty": difficulty, "history": history.to_dict(),
			"goals_done": goals_done, "goals_catch_up": goals_catch_up, "events": events_state.to_dict(),
			"rivals": rivals_state.to_dict(), "specialists": specialists_state.to_dict(),
			"risks": risks_state.to_dict(), "shipyard": shipyard_state.to_dict(),
			"victory": victory_state.to_dict(), "plans": plan_list, "next_plan_id": next_plan_id,
			"exhibits": exhibits_state.to_dict(), "expeditions": expeditions_state.to_dict()}


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
	# versão desconhecida (de um jogo mais novo, ou corrompida): recusado
	if world.terrain_version != 0 and world.terrain_version not in ArchipelagoGenerator.VERSIONS:
		return null
	var raw_islands: Variant = data.get("islands")
	if not raw_islands is Array:
		return null
	var saved_islands: Array = raw_islands
	var generated: Array[IslandGrid] = []
	if world.terrain_version != 0:
		# o tamanho do arquipélago é o número de ilhas do save
		var game_config := config if config != null else GameConfig.get_default()
		var tropical := tropical_count(saved_islands, game_data)
		var temperate := saved_islands.size() - tropical
		if tropical < 0 or temperate < 1 or temperate > game_config.island_sizes_cells.size() \
				or tropical > game_config.tropical_island_sizes_cells.size():
			return null
		var specs := ArchipelagoGenerator.layout(world.seed, game_config, game_data, temperate)
		specs.append_array(ArchipelagoGenerator.tropical_layout(world.seed, game_config, game_data, specs.size(), tropical))
		for spec: ArchipelagoGenerator.IslandSpec in specs:
			generated.append(ArchipelagoGenerator.build_island(spec, game_config, world.terrain_version))
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
	if not world._restore_fleet(data, game_data):
		return null
	var raw_difficulty: Variant = data.get("difficulty")
	var raw_history: Variant = data.get("history")
	if not (raw_difficulty is int and raw_history is Dictionary):
		return null
	world.difficulty = raw_difficulty
	if world.difficulty < 0 or world.difficulty > 2:
		return null
	var history_data: Dictionary = raw_history
	var loaded_history := StatisticsHistory.from_dict(history_data)
	if loaded_history == null:
		return null
	world.history = loaded_history
	var raw_goals: Variant = data.get("goals_done")
	var raw_catch_up: Variant = data.get("goals_catch_up")
	if not (raw_goals is int and raw_catch_up is bool):
		return null
	world.goals_done = raw_goals
	world.goals_catch_up = raw_catch_up
	if world.goals_done < 0 or world.goals_done > game_data.goals.size():
		return null
	var raw_events: Variant = data.get("events")
	if not raw_events is Dictionary:
		return null
	var events_data: Dictionary = raw_events
	var loaded_events := EventsState.from_dict(events_data, game_data, world.islands.size())
	if loaded_events == null:
		return null
	world.events_state = loaded_events
	var raw_rivals: Variant = data.get("rivals")
	if not raw_rivals is Dictionary:
		return null
	var rivals_data: Dictionary = raw_rivals
	var loaded_rivals := RivalsState.from_dict(rivals_data, game_data, world.islands.size())
	if loaded_rivals == null:
		return null
	for rival: RivalState in loaded_rivals.rivals:
		for ship_id: int in [rival.ship_id] + rival.warships:
			if ship_id != 0 and (not world.ships.has(ship_id) or world.ships[ship_id].owner != Ship.Owner.RIVAL):
				return null
		for island_id: int in rival.islands:
			if world.has_trading_post(island_id, game_data):
				return null
	world.rivals_state = loaded_rivals
	var raw_specialists: Variant = data.get("specialists")
	if not raw_specialists is Dictionary:
		return null
	var specialists_data: Dictionary = raw_specialists
	var loaded_specialists := SpecialistsState.from_dict(specialists_data, game_data)
	if loaded_specialists == null:
		return null
	for item: Specialist in loaded_specialists.specialists:
		if item.building_id != 0:
			var record := world.building(item.building_id)
			if record == null or not item.def.covers(game_data.building(record.def_id)):
				return null
	world.specialists_state = loaded_specialists
	var raw_risks: Variant = data.get("risks")
	if not raw_risks is Dictionary:
		return null
	var risks_data: Dictionary = raw_risks
	var loaded_risks := RisksState.from_dict(risks_data, world, game_data)
	if loaded_risks == null:
		return null
	world.risks_state = loaded_risks
	var raw_shipyard: Variant = data.get("shipyard")
	if not raw_shipyard is Dictionary:
		return null
	var shipyard_data: Dictionary = raw_shipyard
	var loaded_shipyard := ShipyardState.from_dict(shipyard_data, world, game_data)
	if loaded_shipyard == null:
		return null
	world.shipyard_state = loaded_shipyard
	var raw_victory: Variant = data.get("victory")
	if not raw_victory is Dictionary:
		return null
	var victory_data: Dictionary = raw_victory
	var loaded_victory := VictoryState.from_dict(victory_data, game_data)
	if loaded_victory == null:
		return null
	world.victory_state = loaded_victory
	var raw_plans: Variant = data.get("plans")
	var raw_next_plan: Variant = data.get("next_plan_id")
	if not (raw_plans is Array and raw_next_plan is int):
		return null
	world.next_plan_id = raw_next_plan
	var plan_list: Array = raw_plans
	for raw_plan: Variant in plan_list:
		if not raw_plan is Dictionary:
			return null
		var plan_data: Dictionary = raw_plan
		var plan := PlanRecord.from_dict(plan_data, game_data, world.islands.size())
		if plan == null or world.plans.has(plan.id) or plan.id >= world.next_plan_id:
			return null
		world.plans[plan.id] = plan
	# as peças de coleção (Fase 67) não existem nos saves de antes: sem a chave, nenhuma comprada
	var raw_exhibits: Variant = data.get("exhibits", {"placed": {}})
	if not raw_exhibits is Dictionary:
		return null
	var exhibits_data: Dictionary = raw_exhibits
	var loaded_exhibits := ExhibitsState.from_dict(exhibits_data, game_data)
	if loaded_exhibits == null:
		return null
	# a peça posta fica num zoológico ou museu do tipo dela, sem passar das vagas
	var used: Dictionary[int, int] = {}
	for exhibit_id: StringName in loaded_exhibits.placed:
		var building_id: int = loaded_exhibits.placed[exhibit_id]
		if building_id == 0:
			continue
		var record := world.building(building_id)
		var hall_def: BuildingDef = null
		if record != null:
			hall_def = game_data.building(record.def_id)
		if hall_def == null or not hall_def.is_exhibit_hall() or hall_def.exhibit_kind != game_data.exhibit(exhibit_id).kind:
			return null
		used[building_id] = used.get(building_id, 0) + 1
		if used[building_id] > hall_def.exhibit_slots:
			return null
	world.exhibits_state = loaded_exhibits
	# as expedições (Fase 69) não existem nos saves de antes: sem a chave, nenhuma em andamento
	var raw_expeditions: Variant = data.get("expeditions", {"trips": [], "count": 0})
	if not raw_expeditions is Dictionary:
		return null
	var expeditions_data: Dictionary = raw_expeditions
	var loaded_expeditions := ExpeditionsState.from_dict(expeditions_data, game_data, world.islands.size())
	if loaded_expeditions == null:
		return null
	# o navio em viagem é da companhia, não está no mapa e tem id já dado
	for trip: ExpeditionsState.Trip in loaded_expeditions.trips:
		if trip.ship.owner != Ship.Owner.PLAYER or world.ships.has(trip.ship.id) or trip.ship.id >= world.next_ship_id:
			return null
	world.expeditions_state = loaded_expeditions
	return world


## Quantas ilhas do save são tropicais (pelo perfil da economia). Elas vêm depois das temperadas:
## tropical antes de temperada devolve -1 (save inconsistente).
static func tropical_count(saved_islands: Array, game_data: GameData) -> int:
	var count := 0
	for raw: Variant in saved_islands:
		var tropical := false
		if raw is Dictionary:
			var island_data: Dictionary = raw
			var raw_economy: Variant = island_data.get("economy")
			if raw_economy is Dictionary:
				var economy_data: Dictionary = raw_economy
				var raw_profile: Variant = economy_data.get("profile")
				if raw_profile is StringName:
					var profile_id: StringName = raw_profile
					var profile := game_data.profile(profile_id)
					tropical = profile != null and profile.is_tropical()
		if tropical:
			count += 1
		elif count > 0:
			return -1
	return count


## Ilha de clima tropical (Fase 11)?
func is_tropical(island_id: int, data: GameData) -> bool:
	var island_economy := economy(island_id)
	if island_economy == null:
		return false
	var profile := data.profile(island_economy.profile_id)
	return profile != null and profile.is_tropical()


## Navios, rotas, comerciante e marcos (Fase 6). Navio que aponta para rota, ilha ou cais que não
## existe recusa o save inteiro.
func _restore_fleet(data: Dictionary, game_data: GameData) -> bool:
	var raw_ships: Variant = data.get("ships")
	var raw_next_ship: Variant = data.get("next_ship_id")
	var raw_routes: Variant = data.get("routes")
	var raw_next_route: Variant = data.get("next_route_id")
	var raw_trader: Variant = data.get("trader")
	var raw_milestones: Variant = data.get("milestones_reached")
	if not (raw_ships is Array and raw_next_ship is int and raw_routes is Array and raw_next_route is int \
			and raw_trader is Dictionary and raw_milestones is int):
		return false
	next_ship_id = raw_next_ship
	next_route_id = raw_next_route
	milestones_reached = raw_milestones
	if milestones_reached < 0:
		return false
	var route_list: Array = raw_routes
	for raw_route: Variant in route_list:
		if not raw_route is Dictionary:
			return false
		var route_data: Dictionary = raw_route
		var route := TradeRoute.from_dict(route_data, islands.size(), game_data)
		if route == null or routes.has(route.id) or route.id >= next_route_id:
			return false
		routes[route.id] = route
	var ship_list: Array = raw_ships
	for raw_ship: Variant in ship_list:
		if not raw_ship is Dictionary:
			return false
		var ship_data: Dictionary = raw_ship
		var loaded := Ship.from_dict(ship_data, game_data)
		if loaded == null or ships.has(loaded.id) or loaded.id >= next_ship_id:
			return false
		if loaded.route_id != 0 and not routes.has(loaded.route_id):
			return false
		for place: int in [loaded.at, loaded.destination]:
			if place != Ship.NOWHERE and not TradeRoute.valid_target(place, islands.size()):
				return false
		if loaded.berth_id != 0 and building(loaded.berth_id) == null:
			return false
		ships[loaded.id] = loaded
	var trader_data: Dictionary = raw_trader
	var loaded_trader := TraderState.from_dict(trader_data, islands.size())
	if loaded_trader == null:
		return false
	if loaded_trader.ship_id != 0 and (not ships.has(loaded_trader.ship_id) or ships[loaded_trader.ship_id].owner != Ship.Owner.TRADER):
		return false
	trader = loaded_trader
	return true


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
	# a ilha plana guarda o lugar no mundo (desde a Fase 6 pode haver mais de uma; antes, era a origem)
	var raw_origin: Variant = data.get("origin")
	if generated == null and raw_origin is Vector2:
		grid.origin_m = raw_origin
	var road_indices: PackedInt32Array = raw_roads
	for i: int in road_indices:
		if i < 0 or i >= grid.roads.size():
			return false
		grid.roads[i] = IslandGrid.Road.DIRT
	# paralelepípedo (Fase 8): um subconjunto das estradas
	var raw_paved: Variant = data.get("paved")
	if not raw_paved is PackedInt32Array:
		return false
	var paved_indices: PackedInt32Array = raw_paved
	for i: int in paved_indices:
		if i < 0 or i >= grid.roads.size() or grid.roads[i] != IslandGrid.Road.DIRT:
			return false
		grid.roads[i] = IslandGrid.Road.PAVED
	# a ferrovia (Fase 70) não existe nos saves de antes; trilho não divide célula com estrada
	var raw_rails: Variant = data.get("rails", PackedInt32Array())
	if not raw_rails is PackedInt32Array:
		return false
	var rail_indices: PackedInt32Array = raw_rails
	for i: int in rail_indices:
		if i < 0 or i >= grid.rails.size() or grid.roads[i] != IslandGrid.Road.NONE:
			return false
		grid.rails[i] = 1
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
	# a política (Fase 66) só numa prefeitura e só uma que existe
	if record.policy != &"" and (not def.is_town_hall() or game_data.policy(record.policy) == null):
		return false
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	if PlacementRules.check_area(grid, area) != &"":
		return false
	grid.fill_building(area, record.id)
	buildings[record.id] = record
	return true
