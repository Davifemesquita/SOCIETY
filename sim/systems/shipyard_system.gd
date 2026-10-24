class_name ShipyardSystem
extends RefCounted
## Estaleiros, logo depois da produção: o estaleiro com encomenda trabalha na velocidade da força de
## trabalho dele (como uma fábrica) e, sem estrada ou sem armazém, para com o motivo de sempre. Sem
## encomenda fica parado (IDLE). A encomenda anda dt × velocidade / build_time_s do navio; pronta, o
## navio aparece no porto da ilha (devolvido para a Simulation pôr no mar e avisar as vistas).


## Avança as encomendas e devolve os navios entregues neste tick.
static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, dt: float) -> Array[int]:
	var built: Array[int] = []
	var smoothing := 1.0 - exp(-dt / config.productivity_smoothing_seconds)
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		if not entry.shipyard:
			continue
		var record := entry.record
		var previous := record.state
		var speed := _speed(world, config, entry)
		record.productivity = lerpf(record.productivity, speed, smoothing)
		if record.state != previous:
			EventBus.building_state_changed.emit(record.id)
		var item := world.shipyard_state.order(record.id)
		if item == null or speed <= 0.0:
			continue
		item.progress += dt * speed / data.ship(item.def_id).build_time_s
		if item.progress >= 1.0 - 0.000001:
			built.append(deliver(world, data, record))
	return built


## Velocidade do estaleiro agora (0..1) e o estado que ela mostra.
static func _speed(world: WorldState, config: GameConfig, entry: DerivedState.ProductionEntry) -> float:
	var record := entry.record
	if world.risks_state.is_burning(record.id):
		record.state = BuildingRecord.State.ON_FIRE
		return 0.0
	if record.paused:
		record.state = BuildingRecord.State.PAUSED
		return 0.0
	if not entry.has_road:
		record.state = BuildingRecord.State.NO_ROAD
		return 0.0
	if entry.warehouse_id == 0 and not config.instant_logistics:
		record.state = BuildingRecord.State.NO_WAREHOUSE
		return 0.0
	if world.shipyard_state.order(record.id) == null:
		record.state = BuildingRecord.State.IDLE
		return 0.0
	var speed := entry.economy.workforce(entry.def.workforce_tier)
	record.state = BuildingRecord.State.PRODUCING if speed > 0.0 else BuildingRecord.State.NO_WORKERS
	return speed


## Entrega a encomenda do estaleiro: o navio novo ancorado na ilha dele. Devolve o id do navio.
static func deliver(world: WorldState, data: GameData, record: BuildingRecord) -> int:
	var item := world.shipyard_state.order(record.id)
	world.shipyard_state.orders.erase(record.id)
	world.shipyard_state.ships_built += 1
	var ship := Ship.new(world.next_ship_id, data.ship(item.def_id))
	world.next_ship_id += 1
	ship.at = record.island_id
	world.ships[ship.id] = ship
	return ship.id


## Há estaleiro nesta ilha (o reparo no porto dela é mais rápido).
static func island_has_shipyard(world: WorldState, data: GameData, island_id: int) -> bool:
	for record: BuildingRecord in world.buildings.values():
		if record.island_id == island_id and data.building(record.def_id).is_shipyard():
			return true
	return false


## Preço de um navio no estaleiro: a fração do preço do entreposto, arredondada para cima.
static func cost_money(def: ShipDef, config: GameConfig) -> int:
	return ceili(def.cost_money * config.shipyard_cost_factor)


static func cost_materials(def: ShipDef, config: GameConfig) -> Dictionary[StringName, int]:
	var materials: Dictionary[StringName, int] = {}
	for material: StringName in def.cost_materials:
		materials[material] = ceili(def.cost_materials[material] * config.shipyard_cost_factor)
	return materials
