class_name SimFixture
extends RefCounted
## Montagem de cenários de teste da simulação: ilha pequena, estradas, prédios, casas com
## moradores e estoque. Constrói sem custo; os testes de custo desligam free_build.
## Por padrão usa o transporte instantâneo (sem carroça nem entreposto): os testes da economia
## medem a economia. Os de logística pedem logistics = true.

const ISLAND := Simulation.MAIN_ISLAND


static func simulation(size: Vector2i = Vector2i(120, 40), capacity: int = 50, logistics: bool = false) -> Simulation:
	var config := GameConfig.new()
	config.main_island_size_cells = size
	config.island_storage_capacity_t = capacity
	config.starting_materials = {}
	config.starting_ship = &""
	config.instant_logistics = not logistics
	var sim := Simulation.new(config, GameData.get_default())
	sim.free_build = true
	return sim


static func place(sim: Simulation, def_id: StringName, origin: Vector2i, rotation: int = 0) -> int:
	var result := sim.execute(PlaceBuildingCommand.new(ISLAND, def_id, origin, rotation))
	assert(result.ok(), "não construiu %s em %s: %s" % [def_id, origin, result.reason])
	return result.placed[0]


static func road(sim: Simulation, from: Vector2i, to: Vector2i) -> void:
	var result := sim.execute(BuildRoadCommand.new(ISLAND, RoadPath.l_path(from, to)))
	assert(result.ok(), "estrada recusada: %s" % result.reason)


## Casa de frente para uma estrada horizontal em street_y (casa acima dela, rotação 2).
static func house(sim: Simulation, x: int, street_y: int, tier: StringName, residents: float) -> int:
	var house_id := place(sim, &"house", Vector2i(x, street_y - 3), 2)
	var record := sim.world.building(house_id)
	record.tier = tier
	record.residents = residents
	return house_id


## Fazenda de frente para a estrada em street_y (abaixo dela), com os módulos no raio.
static func farm(sim: Simulation, def_id: StringName, x: int, street_y: int) -> int:
	var farm_id := place(sim, def_id, Vector2i(x, street_y + 1), 0)
	var def := sim.data.building(def_id)
	var reach := Footprint.rect(Vector2i(x, street_y + 1), def.size, 0).grow(def.module_radius_cells)
	var module := sim.data.building(def.module_id)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - module.size.y + 1):
		for x_cell: int in range(reach.position.x, reach.end.x - module.size.x + 1):
			if placed >= def.modules_required:
				return farm_id
			var result := sim.execute(PlaceBuildingCommand.new(ISLAND, def.module_id, Vector2i(x_cell, y), 0))
			if result.ok():
				placed += 1
	assert(placed >= def.modules_required, "faltou lugar para os módulos de %s" % def_id)
	return farm_id


## Começa com todas as médias de atendimento em 100%, como numa ilha que já vinha abastecida.
static func warm_supply(sim: Simulation) -> void:
	var economy := sim.world.economy(ISLAND)
	for tier: TierDef in sim.data.tiers:
		for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
			economy.set_supply(tier.id, need.id, 1.0)
	for good: GoodDef in sim.data.goods:
		if good.consumption_per_resident_t_min > 0.0:
			economy.good_supply[good.id] = 1.0


static func residents(sim: Simulation) -> float:
	var total := 0.0
	for house_id: int in sim.derived_state().houses:
		total += sim.world.building(house_id).residents
	return total


## Ilha com logística: entreposto no litoral norte (x 0..5, frente para a estrada em y = 6) e
## a estrada principal em y = 6 de ponta a ponta. Prédios ficam abaixo dela (origem y = 7).
static func port(sim: Simulation) -> int:
	var post := place(sim, &"trading_post", Vector2i(0, 0), 2)
	road(sim, Vector2i(0, 6), Vector2i(sim.world.island(ISLAND).size.x - 1, 6))
	return post


## Casa acima da estrada principal (y = 6), fora da área do entreposto.
static func house_on_main_road(sim: Simulation, x: int, tier: StringName, residents: float) -> int:
	return house(sim, x, 6, tier, residents)


static func cart(sim: Simulation, building_id: int) -> Cart:
	return sim.world.cart(building_id)


static func give(sim: Simulation, good: StringName, tons: float) -> void:
	sim.world.economy(ISLAND).stock[good] = tons


static func stock(sim: Simulation, good: StringName) -> float:
	return sim.world.economy(ISLAND).amount(good)


## Só a parte da produção (força de trabalho, ciclo, estoque), com as casas paradas.
static func run_production(sim: Simulation, seconds: float) -> void:
	var dt := sim.config.tick_interval()
	for i: int in roundi(seconds / dt):
		var derived := sim.derived_state()
		WorkforceSystem.run(sim.world, derived)
		ProductionSystem.run(sim.config, derived, dt, sim.world.events_state, sim.world.risks_state)
		if sim.config.instant_logistics:
			DirectTransferSystem.run(sim.world, sim.config, derived)
		else:
			LogisticsSystem.run(sim.world, sim.config, derived, dt)
		sim.world.tick += 1


static func run(sim: Simulation, seconds: float) -> void:
	sim.run_ticks(roundi(seconds / sim.config.tick_interval()))


## Duas ilhas planas no mar (Fase 6): a principal na origem e a segunda gap_m a leste, as duas do
## mesmo tamanho, cada uma com entreposto no litoral norte (x 0..5) e a estrada principal em
## y = 6. Com carroças, sem navio inicial; constrói sem custo.
static func two_islands(size: Vector2i = Vector2i(60, 30), gap_m: float = 200.0) -> Simulation:
	var config := GameConfig.new()
	config.starting_materials = {}
	config.starting_ship = &""
	config.instant_logistics = false
	var data := GameData.get_default()
	var world := WorldState.new()
	world.money = 50000.0
	for index: int in 2:
		var grid := IslandGrid.new(size)
		grid.origin_m = Vector2(index * (size.x * config.cell_size_m + gap_m), 0.0)
		world.islands.append(grid)
		var economy := IslandEconomy.new()
		economy.profile_id = &"test_island"
		world.economies.append(economy)
	var sim := Simulation.new(config, data, world)
	sim.free_build = true
	for index: int in 2:
		var result := sim.execute(PlaceBuildingCommand.new(index, &"trading_post", Vector2i(0, 0), 2))
		assert(result.ok(), "entreposto recusado: %s" % result.reason)
		sim.execute(BuildRoadCommand.new(index, RoadPath.l_path(Vector2i(0, 6), Vector2i(size.x - 1, 6))))
	return sim


## Compra um navio (sem custo) ancorado na ilha e devolve o id.
static func ship(sim: Simulation, island: int = ISLAND) -> int:
	var result := sim.execute(BuyShipCommand.new(island))
	assert(result.ok(), "navio recusado: %s" % result.reason)
	return result.created_id


## Rota com as paradas dadas: cada parada é [ilha, [[bem, carregar?, toneladas], ...]].
static func route(sim: Simulation, stops: Array) -> int:
	var route_id := sim.execute(CreateRouteCommand.new()).created_id
	var list: Array[TradeRoute.Stop] = []
	for raw: Array in stops:
		var target: int = raw[0]
		var stop := TradeRoute.Stop.new(target)
		var orders: Array = raw[1]
		for order: Array in orders:
			var good: StringName = order[0]
			var loading: bool = order[1]
			var tons: int = order[2]
			stop.orders.append(TradeRoute.Order.new(good, loading, tons))
		list.append(stop)
	var result := sim.execute(EditRouteCommand.new(route_id, list))
	assert(result.ok(), "rota recusada: %s" % result.reason)
	return route_id


## Roda até a condição valer ou o tempo acabar; devolve os segundos de jogo que passaram.
static func run_until(sim: Simulation, condition: Callable, max_seconds: float) -> float:
	var dt := sim.config.tick_interval()
	var elapsed := 0.0
	while elapsed < max_seconds:
		if condition.call():
			return elapsed
		sim.tick(0)
		elapsed += dt
	return elapsed
