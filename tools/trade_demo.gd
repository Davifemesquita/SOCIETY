class_name TradeDemo
extends RefCounted
## Duas ilhas ligadas por uma rota (Fase 6), usada pelo critério da fase, pela captura e pelo
## benchmark. Entreposto no litoral de verdade das duas (SiteFinder); na colônia, uma rua que
## entra pela frente do entreposto com cava de argila, olaria, casas de operários, mercado e
## escola (assentados sem olhar o relevo, como a cidade do benchmark: o que se mede aqui é o
## navio); o estoque da colônia começa com comida, roupa e sabão para a hora inteira. A rota
## carrega os tijolos na colônia e descarrega na principal. Constrói sem custo.

const STREET_CELLS := 44
const WORKER_HOUSES := 4
const COLONY_SUPPLIES: Dictionary[StringName, float] = {&"fish": 45.0, &"woolen_clothes": 40.0, &"soap": 30.0}


## Devolve os ids: "main_post", "colony_post", "clay_pit", "brickworks", "houses", "route", "ship".
static func build(sim: Simulation, colony: int = 1) -> Dictionary:
	var was_free := sim.free_build
	var was_ignoring := sim.ignore_terrain
	sim.free_build = true
	var ids := {}
	var main_post := post(sim, Simulation.MAIN_ISLAND)
	ids["main_post"] = main_post
	for level: int in 2:
		sim.execute(UpgradeBuildingCommand.new(main_post))
	var colony_post := post(sim, colony)
	ids["colony_post"] = colony_post
	var record := sim.world.building(colony_post)
	var def := sim.data.building(&"trading_post")
	var front := Footprint.front_direction(record.rotation)
	var start := Footprint.entrance_cell(record.origin, def.size, record.rotation)
	sim.ignore_terrain = true
	var street: Array[Vector2i] = RoadPath.l_path(start, start + front * (STREET_CELLS - 1))
	sim.execute(BuildRoadCommand.new(colony, street))
	var side := Vector2i(-front.y, front.x)
	var along := [2, 2]
	ids["clay_pit"] = _beside(sim, colony, start, front, side, along, 0, &"clay_pit")
	ids["brickworks"] = _beside(sim, colony, start, front, side, along, 0, &"brickworks")
	ids["market"] = _beside(sim, colony, start, front, side, along, 0, &"market")
	var houses: Array[int] = []
	for i: int in WORKER_HOUSES:
		var house := _beside(sim, colony, start, front, side, along, 1, &"house")
		var home := sim.world.building(house)
		home.tier = &"workers"
		home.residents = float(sim.data.tier(&"workers").residents_per_house)
		home.upgrade_blocked = true
		houses.append(house)
	ids["houses"] = houses
	ids["school"] = _beside(sim, colony, start, front, side, along, 1, &"school")
	sim.ignore_terrain = was_ignoring
	var economy := sim.world.economy(colony)
	for good: StringName in COLONY_SUPPLIES:
		economy.stock[good] = COLONY_SUPPLIES[good]
	for tier: TierDef in sim.data.tiers:
		for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
			economy.set_supply(tier.id, need.id, 1.0)
	var route := brick_route(sim, colony)
	ids["route"] = route
	var bought := sim.execute(BuyShipCommand.new(Simulation.MAIN_ISLAND))
	ids["ship"] = bought.created_id
	sim.execute(SetShipRouteCommand.new(bought.created_id, route))
	sim.free_build = was_free
	return ids


## Rota de tijolos: carrega 50 t na colônia e descarrega 50 t na principal.
static func brick_route(sim: Simulation, colony: int) -> int:
	var route_id := sim.execute(CreateRouteCommand.new()).created_id
	var load_stop := TradeRoute.Stop.new(colony)
	load_stop.orders.append(TradeRoute.Order.new(&"bricks", true, 50))
	var unload_stop := TradeRoute.Stop.new(Simulation.MAIN_ISLAND)
	unload_stop.orders.append(TradeRoute.Order.new(&"bricks", false, 50))
	var stops: Array[TradeRoute.Stop] = [load_stop, unload_stop]
	sim.execute(EditRouteCommand.new(route_id, stops))
	return route_id


## Entreposto no litoral mais perto do meio da borda norte da ilha.
static func post(sim: Simulation, island_id: int) -> int:
	var grid := sim.world.island(island_id)
	var site := SiteFinder.find(sim, &"trading_post", island_id, Vector2i(grid.size.x / 2, 0))
	assert(not site.is_empty(), "sem lugar de entreposto na ilha %d" % island_id)
	var origin: Vector2i = site[0]
	var rotation: int = site[1]
	var result := sim.execute(PlaceBuildingCommand.new(island_id, &"trading_post", origin, rotation))
	assert(result.ok(), "entreposto recusado na ilha %d: %s" % [island_id, result.reason])
	return result.placed[0]


## Prédio encostado na rua, do lado side (0 = side, 1 = −side), com a frente para ela; along guarda
## onde cada lado parou.
static func _beside(sim: Simulation, island_id: int, start: Vector2i, front: Vector2i, side: Vector2i, along: Array,
		which: int, def_id: StringName) -> int:
	var def := sim.data.building(def_id)
	var normal := side if which == 0 else -side
	var rotation := 0
	for candidate: int in 4:
		if Footprint.front_direction(candidate) == -normal:
			rotation = candidate
	var rotated := Footprint.rotated_size(def.size, rotation)
	var width := rotated.x if front.x != 0 else rotated.y
	var depth := rotated.y if front.x != 0 else rotated.x
	var t: int = along[which]
	var first := start + front * t + normal
	var last := start + front * (t + width - 1) + normal * depth
	var origin := Vector2i(mini(first.x, last.x), mini(first.y, last.y))
	along[which] = t + width
	var result := sim.execute(PlaceBuildingCommand.new(island_id, def_id, origin, rotation))
	assert(result.ok(), "%s recusado na rua da colônia: %s" % [def_id, result.reason])
	return result.placed[0] if result.ok() else 0
