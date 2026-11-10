class_name TerrainAutoPlayer
extends AutoPlayer
## Fase 387: o jogador-robô no jogo de verdade. O AutoPlayer da Fase 10 joga numa ilha plana desenhada para ele (ruas a cada
## tantas células, a borda inteira de litoral) e com eventos, rivais e riscos desligados. Este joga a ilha principal de um
## arquipélago do gerador com tudo ligado, como o jogo novo do menu: acha cada lote pelo SiteFinder perto do centro da vila e
## liga a frente à estrada que já existe por uma busca em largura pelas células onde cabe estrada. As decisões (fila de obras,
## faltas, mão de obra, travas de subida) são as do AutoPlayer; só o lugar muda.
##
## Guarda o que um jogador sentiria: onde não coube (`full`), as carroças presas e os navios parados (`stuck`) e os
## invariantes quebrados (`broken`, da Fase 386).

## Raio da busca de lote em volta do centro (células).
const SEARCH_RADIUS := 130
## Comprimento máximo da estrada que liga um prédio novo à rede (células). O relevo em patamares obriga a estrada a
## contornar barrancos: com 70, nenhum dos lotes de tecelagem da semente 1840 chegava, embora a terra seja toda ligada.
const LINK_MAX := 220
## Lotes que cabem mas não têm estrada até a rede antes de desistir.
const MAX_UNLINKED := 400
## Prédio sem lugar não é procurado de novo antes disto (s de jogo): a busca que falha varre a ilha inteira.
const RETRY_AFTER_S := 120.0
## Árvores no raio do lenhador novo, em múltiplos do mínimo (o corte e as obras vizinhas derrubam parte delas).
const TREES_MARGIN := 3
## Casas por mercado (o raio de serviço é por estrada; mais casas por mercado deixam as de longe sem atendimento).
const HOUSES_PER_MARKET := 14
## Fábricas por armazém novo, fora do alcance do entreposto.
const WAREHOUSE_REACH := 30
## Carroça bloqueada ou navio com rota parado por mais que isto é "preso" (s de jogo).
const STUCK_AFTER_S := 180.0

var hub := Vector2i(-1, -1)
## Prédio → vezes que não coube (sem lote ou sem estrada até ele).
var full: Dictionary[StringName, int] = {}
## Texto → primeira vez (s de jogo) em que algo ficou preso além de STUCK_AFTER_S.
var stuck: Dictionary[String, float] = {}
## Invariantes quebrados: texto → primeira vez (s de jogo).
var broken: Dictionary[String, float] = {}
var _markets: Array[Vector2i] = []
var _houses_at_market: Dictionary[int, int] = {}
var _blocked_since: Dictionary[String, float] = {}
## Prédio sem armazém → quando tentar de novo (s de jogo): o armazém perto em linha reta pode ficar longe pela estrada.
var _warehouse_for: Dictionary[int, float] = {}
var _failed_until: Dictionary[StringName, float] = {}
var _near_water: Dictionary[int, PackedByteArray] = {}
## Distância de cada célula (índice da grade) até a rede de estradas pelas células onde a estrada cabe (-1: não chega)
## e o passo seguinte rumo à rede; refeitas quando o mundo muda (`_field_dirty`).
var _field_depth := PackedInt32Array()
var _field_next := PackedInt32Array()
var _field_dirty := true


static func on_archipelago(seed_value: int, all_systems: bool = true, version: int = -1) -> TerrainAutoPlayer:
	var player := TerrainAutoPlayer.new()
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(seed_value, config, data, -1, -1, version)
	player.simulation = Simulation.new(config, data, world)
	if all_systems:
		world.events_state.enabled = true
		world.risks_state.enabled = true
		world.rivals_state.start(data, config)
	for item: Array in ORDER:
		var count: int = item[1]
		for i: int in count:
			player._queue.append(item[0])
	return player


## Uma rodada: as decisões do AutoPlayer e a conferência do que ficou preso e dos invariantes.
func decide() -> void:
	if hub.x < 0:
		_found_town()
		return
	# casa perdida no fogo sai da lista (o AutoPlayer da ilha plana joga sem riscos)
	houses = houses.filter(func(id: int) -> bool: return simulation.world.buildings.has(id))
	_field_dirty = true
	super.decide()
	_ensure_warehouses()
	_watch()


func _found_town() -> void:
	var grid := simulation.world.island(ISLAND)
	var site := SiteFinder.find(simulation, &"trading_post", ISLAND, grid.size / 2, grid.size.x)
	if site.is_empty():
		_note_full(&"trading_post")
		return
	var origin: Vector2i = site[0]
	var rotation: int = site[1]
	var def := simulation.data.building(&"trading_post")
	if not simulation.execute(PlaceBuildingCommand.new(ISLAND, &"trading_post", origin, rotation)).ok():
		_note_full(&"trading_post")
		return
	var front := Footprint.front_cells(origin, def.size, rotation)
	hub = front[front.size() / 2]
	simulation.execute(BuildRoadCommand.new(ISLAND, front))
	log.append([seconds, "entreposto em %s" % origin])


# --- lugares --------------------------------------------------------------------------------

func _place_coast(def: BuildingDef) -> bool:
	return _place_near(def.id, hub) >= 0


func _place_on_street(def: BuildingDef) -> bool:
	var id := _place_near(def.id, hub)
	if id < 0:
		return false
	return true


func _place_farm(def: BuildingDef) -> bool:
	var farm_id := _place_near(def.id, hub)
	if farm_id < 0:
		return false
	var record := simulation.world.building(farm_id)
	var placed := 0
	for spot: Array in _module_spots(def, record.origin, record.rotation):
		var module_origin: Vector2i = spot[0]
		var module_rotation: int = spot[1]
		if simulation.execute(PlaceBuildingCommand.new(ISLAND, def.module_id, module_origin, module_rotation)).ok():
			placed += 1
	if placed < def.modules_required:
		_note_full(def.module_id)
	return true


## Os lotes dos campos ou pastos da fazenda em origin, sem se sobreporem, até os que ela pede (vazio se não cabem todos).
func _module_spots(def: BuildingDef, origin: Vector2i, rotation: int) -> Array:
	var grid := simulation.world.island(ISLAND)
	var module := simulation.data.building(def.module_id)
	var profile := simulation.data.profile(simulation.world.economy(ISLAND).profile_id)
	var farm := Footprint.rect(origin, def.size, rotation)
	var reach := farm.grow(def.module_radius_cells)
	var taken: Array[Rect2i] = [farm]
	var spots: Array = []
	for y: int in range(reach.position.y, reach.end.y - module.size.y + 1):
		for x: int in range(reach.position.x, reach.end.x - module.size.x + 1):
			var area := Rect2i(Vector2i(x, y), module.size)
			var free := true
			for other: Rect2i in taken:
				if other.intersects(area):
					free = false
					break
			if not free or PlacementRules.check_building(grid, module, area.position, 0) != PlacementRules.OK 					or PlacementRules.check_terrain(grid, profile, module, area.position, 0, simulation.config) != PlacementRules.OK:
				continue
			taken.append(area)
			spots.append([area.position, 0])
			if spots.size() >= def.modules_required:
				return spots
	return []


func _place_house() -> bool:
	if _markets.is_empty() or _houses_at_market.get(_markets.size() - 1, 0) >= HOUSES_PER_MARKET:
		var def := simulation.data.building(&"market")
		if not _can_spend(def.cost_money) or simulation.affordability(def) != PlacementRules.OK:
			return false
		var market_id := _place_near(&"market", hub if _markets.is_empty() else _markets[-1])
		if market_id < 0:
			return false
		var record := simulation.world.building(market_id)
		_markets.append(record.origin)
		log.append([seconds, "mercado em %s" % record.origin])
	var index := _markets.size() - 1
	var result := _place_near(&"house", _markets[index])
	if result < 0:
		return false
	houses.append(result)
	_houses_at_market[index] = _houses_at_market.get(index, 0) + 1
	return true


## Escola e universidade perto de cada mercado quando a classe delas chega.
func _maintain_services() -> void:
	var world := simulation.world
	for index: int in _markets.size():
		for service: StringName in [&"school", &"university"] as Array[StringName]:
			var key := "%s/%d" % [service, index]
			if _services.has(key):
				continue
			var tier := &"workers" if service == &"school" else &"engineers"
			if world.population(tier) <= 0:
				continue
			var def := simulation.data.building(service)
			if not _can_spend(def.cost_money) or simulation.affordability(def) != PlacementRules.OK:
				continue
			if _place_near(service, _markets[index]) >= 0:
				_services[key] = true


## Constrói o prédio no lote livre mais perto de near de onde a estrada chega à rede (o relevo em patamares deixa lote
## bom preso atrás de um barranco) e liga a frente; devolve o id, ou -1.
func _place_near(def_id: StringName, near: Vector2i) -> int:
	if _failed_until.get(def_id, -1.0) > seconds:
		return -1
	var site := _site(def_id, near)
	if site.is_empty():
		_note_full(def_id)
		_failed_until[def_id] = seconds + RETRY_AFTER_S
		return -1
	var origin: Vector2i = site[0]
	var rotation: int = site[1]
	var link: Array[Vector2i] = site[2]
	var result := simulation.execute(PlaceBuildingCommand.new(ISLAND, def_id, origin, rotation))
	if not result.ok():
		if result.reason not in [PlacementRules.NO_MONEY, PlacementRules.NO_MATERIALS, PlacementRules.LOCKED]:
			_note_full(def_id)
		return -1
	_field_dirty = true
	if not (link.size() == 1 and simulation.world.island(ISLAND).has_road(link[0])):
		simulation.execute(BuildRoadCommand.new(ISLAND, link))
	return result.placed[0]


## [origem, rotação, estrada até a rede] do lote mais perto de near em que o prédio cabe pelo terreno e a estrada chega,
## ou vazio. A ordem dos lotes é a do SiteFinder (anéis em volta de near).
func _site(def_id: StringName, near: Vector2i) -> Array:
	var grid := simulation.world.island(ISLAND)
	var def := simulation.data.building(def_id)
	var profile := simulation.data.profile(simulation.world.economy(ISLAND).profile_id)
	var tries := 0
	var needs_water := def.terrain in [BuildingDef.Terrain.COAST, BuildingDef.Terrain.RIVER_OR_COAST]
	var reach := def.size.x + def.size.y
	if needs_water and not _near_water.has(reach):
		_near_water[reach] = SiteFinder._near_water(grid, reach)
	var water: PackedByteArray = _near_water.get(reach, PackedByteArray()) if needs_water else PackedByteArray()
	for radius: int in SEARCH_RADIUS + 1:
		for origin: Vector2i in SiteFinder._ring(near, radius):
			if not grid.in_bounds(origin) or not grid.is_land(origin):
				continue
			if def.deposit != &"" and grid.deposit_at(origin) != def.deposit:
				continue
			if needs_water and water[grid.index(origin)] == 0:
				continue
			if grid.building_at(origin) != 0:
				continue
			for rotation: int in 4:
				if not SiteFinder._fits(grid, profile, def, origin, rotation, simulation.config):
					continue
				if def.modules_required > 0 and _module_spots(def, origin, rotation).is_empty():
					continue
				# o lenhador cabe em qualquer chão, mas sem mata no raio fica parado: a regra não recusa o lote
				if def.terrain == BuildingDef.Terrain.TREES:
					var area := Footprint.rect(origin, def.size, rotation).grow(simulation.config.lumberjack_radius_cells)
					if grid.trees_in(area) < simulation.config.lumberjack_min_trees * TREES_MARGIN:
						continue
				var link := _road_link(Footprint.front_cells(origin, def.size, rotation), Footprint.rect(origin, def.size, rotation))
				if not link.is_empty():
					return [origin, rotation, link]
				tries += 1
				if tries >= MAX_UNLINKED:
					return []
	return []


## Caminho de estrada da frente do lote até a rede (a primeira célula com estrada), vazio se não chega em LINK_MAX.
## Primeiro pelo mapa de distâncias da rede inteira (uma busca para todos os lotes); se o caminho dele passa pelo lote,
## por uma busca em largura só deste lote, que desvia dele.
func _road_link(front: Array[Vector2i], lot: Rect2i) -> Array[Vector2i]:
	var grid := simulation.world.island(ISLAND)
	_ensure_field()
	var best := -1
	for cell: Vector2i in front:
		if not grid.in_bounds(cell):
			continue
		var depth := _field_depth[grid.index(cell)]
		if depth >= 0 and depth <= LINK_MAX and (best < 0 or depth < _field_depth[best]):
			best = grid.index(cell)
	if best < 0:
		return []
	var path: Array[Vector2i] = []
	var at := best
	while true:
		var cell := grid.cell_at(at)
		if lot.has_point(cell):
			return _road_link_local(front, lot)
		path.append(cell)
		if _field_depth[at] == 0:
			break
		at = _field_next[at]
	return path


## Mapa de distâncias até a rede: busca em largura saindo de todas as células com estrada pelas células onde a estrada
## cabe (sem prédio, sem barranco, fora do mar).
func _ensure_field() -> void:
	if not _field_dirty and not _field_depth.is_empty():
		return
	_field_dirty = false
	var grid := simulation.world.island(ISLAND)
	var count := grid.size.x * grid.size.y
	_field_depth.resize(count)
	_field_depth.fill(-1)
	_field_next.resize(count)
	_field_next.fill(-1)
	var queue := PackedInt32Array()
	for i: int in count:
		if grid.has_road(grid.cell_at(i)):
			_field_depth[i] = 0
			_field_next[i] = i
			queue.append(i)
	var head := 0
	var width := grid.size.x
	while head < queue.size():
		var at := queue[head]
		head += 1
		var depth := _field_depth[at]
		if depth >= LINK_MAX:
			continue
		var cell := grid.cell_at(at)
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if not grid.in_bounds(next):
				continue
			var j := next.y * width + next.x
			if _field_depth[j] >= 0:
				continue
			if PlacementRules.check_road_cell(grid, next, simulation.config) != PlacementRules.OK:
				continue
			_field_depth[j] = depth + 1
			_field_next[j] = at
			queue.append(j)


## A busca em largura de um lote só, que não passa por ele.
func _road_link_local(front: Array[Vector2i], lot: Rect2i) -> Array[Vector2i]:
	var grid := simulation.world.island(ISLAND)
	var came: Dictionary[Vector2i, Vector2i] = {}
	var depth: Dictionary[Vector2i, int] = {}
	var queue: Array[Vector2i] = []
	for cell: Vector2i in front:
		if grid.has_road(cell):
			return [cell]
		if PlacementRules.check_road_cell(grid, cell, simulation.config) == PlacementRules.OK:
			came[cell] = cell
			depth[cell] = 0
			queue.append(cell)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		if grid.has_road(cell):
			var path: Array[Vector2i] = [cell]
			while came[path[-1]] != path[-1]:
				path.append(came[path[-1]])
			return path
		if depth[cell] >= LINK_MAX:
			continue
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if came.has(next) or lot.has_point(next) or not grid.in_bounds(next):
				continue
			if not grid.has_road(next) and PlacementRules.check_road_cell(grid, next, simulation.config) != PlacementRules.OK:
				continue
			came[next] = cell
			depth[next] = depth[cell] + 1
			queue.append(next)
	return []


## Prédio parado sem armazém ao alcance: um armazém no lote livre mais perto dele (de novo depois de RETRY_AFTER_S se
## ele continuar sem).
func _ensure_warehouses() -> void:
	for record: BuildingRecord in simulation.world.buildings.values():
		if record.state != BuildingRecord.State.NO_WAREHOUSE or _warehouse_for.get(record.id, -1.0) > seconds:
			continue
		var def := simulation.data.building(&"warehouse")
		if not _can_spend(def.cost_money) or simulation.affordability(def) != PlacementRules.OK:
			return
		if _warehouse_on_road(record) >= 0 or _place_near(&"warehouse", record.origin) >= 0:
			_warehouse_for[record.id] = seconds + RETRY_AFTER_S
			log.append([seconds, "armazém perto do prédio %d" % record.id])
			return


## Armazém num lote cuja frente encosta numa estrada que fica a até WAREHOUSE_REACH células do prédio pela rede (o
## alcance da carroça conta pela estrada: o lote perto em linha reta ficava do outro lado do barranco); devolve o id, ou -1.
func _warehouse_on_road(record: BuildingRecord) -> int:
	var grid := simulation.world.island(ISLAND)
	var building := simulation.def_of(record)
	var reached: Dictionary[Vector2i, int] = {}
	var queue: Array[Vector2i] = []
	for cell: Vector2i in Footprint.front_cells(record.origin, building.size, record.rotation):
		if grid.in_bounds(cell) and grid.has_road(cell):
			reached[cell] = 0
			queue.append(cell)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		if reached[cell] >= WAREHOUSE_REACH:
			continue
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if grid.in_bounds(next) and grid.has_road(next) and not reached.has(next):
				reached[next] = reached[cell] + 1
				queue.append(next)
	if reached.is_empty():
		return -1
	var def := simulation.data.building(&"warehouse")
	var profile := simulation.data.profile(simulation.world.economy(ISLAND).profile_id)
	for radius: int in WAREHOUSE_REACH + 1:
		for origin: Vector2i in SiteFinder._ring(record.origin, radius):
			if not grid.in_bounds(origin) or grid.building_at(origin) != 0:
				continue
			for rotation: int in 4:
				if not SiteFinder._fits(grid, profile, def, origin, rotation, simulation.config):
					continue
				var link: Array[Vector2i] = []
				for cell: Vector2i in Footprint.front_cells(origin, def.size, rotation):
					if reached.has(cell):
						link = [cell]
						break
					if link.is_empty() and grid.in_bounds(cell) 							and PlacementRules.check_road_cell(grid, cell, simulation.config) == PlacementRules.OK:
						for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
							if reached.has(cell + step):
								link = [cell, cell + step]
								break
				if link.is_empty():
					continue
				var result := simulation.execute(PlaceBuildingCommand.new(ISLAND, &"warehouse", origin, rotation))
				if not result.ok():
					return -1
				_field_dirty = true
				if link.size() > 1:
					simulation.execute(BuildRoadCommand.new(ISLAND, [link[0]] as Array[Vector2i]))
				return result.placed[0]
	return -1

func _note_full(def_id: StringName) -> void:
	full[def_id] = full.get(def_id, 0) + 1


## As necessidades básicas atendidas, menos as que ainda não dá para atender: a do sabão dos operários pede a fábrica de
## sebo, que só libera com 80 operários. O AutoPlayer da ilha plana, com essa necessidade em zero, nunca erguia casa
## nova; as casas de camponeses ficavam todas travadas pela mão de obra e os operários paravam abaixo dos 80 (sementes
## 1840 e 2024). Um jogador ergueria mais casas.
func _basic_needs_met() -> bool:
	var economy := simulation.world.economy(ISLAND)
	for tier: TierDef in simulation.data.tiers:
		if simulation.world.population(tier.id) <= 0:
			continue
		for need: NeedCategoryDef in tier.basic_needs:
			if need.goods.is_empty() or not _need_reachable(need):
				continue
			if economy.supply_of(tier.id, need.id) < simulation.config.need_met_threshold:
				return false
	return true


## Algum bem da necessidade tem a cadeia inteira liberada (o produtor e o produtor de cada entrada, para trás).
func _need_reachable(need: NeedCategoryDef) -> bool:
	for good: StringName in need.goods:
		if _chain_unlocked(good, 0):
			return true
	return false


func _chain_unlocked(good: StringName, depth: int) -> bool:
	var producer := _producer_of(good)
	if producer == &"" or depth > 6:
		return false
	var def := simulation.data.building(producer)
	if PlacementRules.check_unlock(simulation.world, def) != PlacementRules.OK:
		return false
	for input: StringName in def.inputs:
		if not simulation.data.trader().sells.has(input) and not _chain_unlocked(input, depth + 1):
			return false
	return true


# --- o que ficou preso ---------------------------------------------------------------------

func _watch() -> void:
	var world := simulation.world
	for problem: String in WorldInvariants.check(world, simulation.data):
		if not broken.has(problem):
			broken[problem] = seconds
	var now: Dictionary[String, bool] = {}
	for home_id: int in world.carts:
		if world.carts[home_id].blocked:
			now["carroça do prédio %d (%s) bloqueada" % [home_id, world.building(home_id).def_id]] = true
	for ship: Ship in world.player_ships():
		if ship.route_id != 0 and ship.state == Ship.State.IDLE:
			now["navio %d com rota e parado" % ship.id] = true
	for record: BuildingRecord in world.buildings.values():
		if record.state in [BuildingRecord.State.NO_ROAD, BuildingRecord.State.NO_WAREHOUSE, BuildingRecord.State.NO_TREES]:
			now["prédio %d (%s): %s" % [record.id, record.def_id, BuildingRecord.State.keys()[record.state]]] = true
	for key: String in _blocked_since.keys():
		if not now.has(key):
			_blocked_since.erase(key)
	for key: String in now:
		if not _blocked_since.has(key):
			_blocked_since[key] = seconds
		elif seconds - _blocked_since[key] >= STUCK_AFTER_S and not stuck.has(key):
			stuck[key] = seconds


func report() -> String:
	var lines: Array[String] = [summary()]
	lines.append("não coube: %s" % (str(full) if not full.is_empty() else "nada"))
	var still := stuck.keys().filter(func(key: String) -> bool: return _blocked_since.has(key))
	lines.append("preso mais de %.0f min (%d, %d ainda no fim):" % [STUCK_AFTER_S / 60.0, stuck.size(), still.size()])
	for key: String in stuck:
		lines.append("  %.0f min: %s%s" % [stuck[key] / 60.0, key, " (ainda)" if _blocked_since.has(key) else ""])
	lines.append("invariantes quebrados (%d):" % broken.size())
	for key: String in broken:
		lines.append("  %.0f min: %s" % [broken[key] / 60.0, key])
	return "\n".join(lines)
