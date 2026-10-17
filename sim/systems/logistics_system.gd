class_name LogisticsSystem
extends RefCounted
## Carroças (seção 6). Em casa, a carroça sai quando o prédio tem 1 t de saída ou precisa de
## entrada que o estoque tem: leva a saída e traz a entrada na mesma viagem. No armazém espera
## uma rampa livre (fila por ordem de chegada), descarrega e carrega à razão de
## cart_seconds_per_ton, e volta. A carga só entra no estoque ao descarregar na rampa.
## Estrada cortada: a carroça procura outro caminho; sem caminho, espera onde está.


static func run(world: WorldState, config: GameConfig, derived: DerivedState, dt: float) -> void:
	if not derived.carts_checked:
		_revalidate(world, derived)
		derived.carts_checked = true
	var step := config.cart_speed_cells_per_s * dt
	var at_ramp: Dictionary[int, int] = {}
	var queued: Array[Cart] = []
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		var cart := world.cart(entry.record.id)
		cart.previous_position = cart.position
		match cart.state:
			Cart.State.HOME:
				_plan(world, config, derived, entry, cart)
			Cart.State.OUTBOUND:
				if not cart.blocked:
					cart.position = minf(cart.position + step * _road_factor(world, config, entry, cart), cart.path.size() - 1)
					if cart.position >= cart.path.size() - 1:
						cart.state = Cart.State.QUEUED
						cart.queued_at = world.tick
			Cart.State.AT_RAMP:
				cart.timer -= dt
				if cart.timer <= 0.0:
					_leave_ramp(config, derived, entry, cart)
			Cart.State.INBOUND:
				if not cart.blocked:
					cart.position = maxf(cart.position - step * _road_factor(world, config, entry, cart), 0.0)
					if cart.position <= 0.0:
						_arrive_home(entry, cart)
		if cart.state == Cart.State.AT_RAMP:
			at_ramp[cart.warehouse_id] = at_ramp.get(cart.warehouse_id, 0) + 1
		elif cart.state == Cart.State.QUEUED:
			queued.append(cart)
	_serve_queue(world, config, derived, queued, at_ramp)


## Velocidade relativa na célula em que a carroça está: o paralelepípedo (Fase 8) soma o bônus, e o passo
## diagonal (Fase 17), √2 mais longo, anda na mesma proporção mais devagar em índice de caminho.
static func _road_factor(world: WorldState, config: GameConfig, entry: DerivedState.ProductionEntry, cart: Cart) -> float:
	var at := clampi(floori(cart.position), 0, cart.path.size() - 1)
	var cell := cart.path[at]
	var grid := world.island(entry.record.island_id)
	var factor := 1.0 + config.paved_road_speed_bonus if grid.roads[cell] == IslandGrid.Road.PAVED else 1.0
	if at + 1 < cart.path.size():
		factor /= RoadRouter.step_length(grid, cell, cart.path[at + 1])
	return factor


## Decide a viagem da carroça parada em casa.
static func _plan(world: WorldState, config: GameConfig, derived: DerivedState, entry: DerivedState.ProductionEntry, cart: Cart) -> void:
	if entry.warehouse_id == 0 or entry.record.paused:
		return
	var economy := entry.economy
	var room := float(config.cart_capacity_t) - cart.tons()
	if entry.record.output_buffer >= 1.0 and room > 0.0:
		var taken := minf(entry.record.output_buffer, room)
		entry.record.output_buffer -= taken
		cart.cargo[entry.def.output] = cart.cargo.get(entry.def.output, 0.0) + taken
	cart.wanted.clear()
	var free := float(config.cart_capacity_t)
	var asked := true
	while asked and free >= 1.0:
		asked = false
		for input: StringName in entry.def.inputs:
			if free < 1.0:
				break
			var held: float = entry.record.input_buffer.get(input, 0.0)
			var already: float = cart.wanted.get(input, 0.0)
			if held + already + 1.0 <= config.building_buffer_t + 0.000001 and economy.amount(input) >= already + 1.0:
				cart.wanted[input] = already + 1.0
				free -= 1.0
				asked = true
	if cart.tons() <= 0.0 and cart.wanted.is_empty():
		return
	var grid := world.island(entry.record.island_id)
	var target := derived.warehouse_target(entry.warehouse_id, entry.access_cell, grid)
	var route := derived.router(entry.record.island_id).path(entry.access_cell, target)
	if route.is_empty():
		return
	cart.warehouse_id = entry.warehouse_id
	cart.path = route
	cart.position = 0.0
	cart.previous_position = 0.0
	cart.blocked = false
	cart.state = Cart.State.OUTBOUND


## Fila das rampas: quem chegou antes (e, no empate, o prédio de menor id) entra primeiro.
static func _serve_queue(world: WorldState, config: GameConfig, derived: DerivedState, queued: Array[Cart], at_ramp: Dictionary[int, int]) -> void:
	if queued.is_empty():
		return
	queued.sort_custom(func(a: Cart, b: Cart) -> bool:
		return a.queued_at < b.queued_at or (a.queued_at == b.queued_at and a.home_id < b.home_id))
	for cart: Cart in queued:
		var busy: int = at_ramp.get(cart.warehouse_id, 0)
		if busy >= derived.ramps.get(cart.warehouse_id, 0):
			continue
		at_ramp[cart.warehouse_id] = busy + 1
		var economy := world.economy(world.building(cart.home_id).island_id)
		var loading := 0.0
		for good: StringName in cart.wanted:
			loading += minf(cart.wanted[good], economy.amount(good))
		cart.timer = (cart.tons() + loading) * config.cart_seconds_per_ton
		cart.state = Cart.State.AT_RAMP


## Descarrega no estoque (o que couber), carrega a entrada pedida e volta para casa.
static func _leave_ramp(config: GameConfig, derived: DerivedState, entry: DerivedState.ProductionEntry, cart: Cart) -> void:
	var economy := entry.economy
	var capacity: float = derived.capacity.get(entry.record.island_id, float(config.island_storage_capacity_t))
	for good: StringName in cart.cargo.keys():
		var left: float = cart.cargo[good] - economy.add(good, cart.cargo[good], capacity)
		if left > 0.000001:
			cart.cargo[good] = left
		else:
			cart.cargo.erase(good)
	var free := float(config.cart_capacity_t) - cart.tons()
	for good: StringName in cart.wanted:
		var got := economy.take(good, minf(cart.wanted[good], free))
		if got > 0.0:
			cart.cargo[good] = cart.cargo.get(good, 0.0) + got
			free -= got
	cart.wanted.clear()
	_head_home(derived, entry, cart)


static func _head_home(derived: DerivedState, entry: DerivedState.ProductionEntry, cart: Cart) -> void:
	var current := cart.path[roundi(cart.position)] if not cart.path.is_empty() else -1
	var route := PackedInt32Array()
	if entry.access_cell >= 0 and current >= 0:
		route = derived.router(entry.record.island_id).path(entry.access_cell, current)
	cart.state = Cart.State.INBOUND
	if route.is_empty():
		cart.blocked = true
		return
	cart.path = route
	cart.position = route.size() - 1
	cart.previous_position = cart.position
	cart.blocked = false


## Em casa: a entrada vai para o buffer do prédio; saída que não coube no estoque fica na
## carroça e sai de novo na próxima viagem.
static func _arrive_home(entry: DerivedState.ProductionEntry, cart: Cart) -> void:
	for good: StringName in cart.cargo.keys():
		if entry.def.inputs.has(good):
			entry.record.input_buffer[good] = entry.record.input_buffer.get(good, 0.0) + cart.cargo[good]
			cart.cargo.erase(good)
	cart.state = Cart.State.HOME
	cart.position = 0.0
	cart.previous_position = 0.0
	cart.warehouse_id = 0


## Depois que estradas ou prédios mudam: confere se a rota e o armazém de cada carroça na rua
## ainda valem; senão refaz a rota de onde ela está, ou a deixa esperando.
static func _revalidate(world: WorldState, derived: DerivedState) -> void:
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		var cart := world.cart(entry.record.id)
		if not cart.is_away():
			continue
		var grid := world.island(entry.record.island_id)
		var current := cart.path[roundi(cart.position)] if not cart.path.is_empty() else -1
		var warehouse_ok: bool = derived.warehouse_connected.get(cart.warehouse_id, false)
		if cart.state == Cart.State.INBOUND:
			if not _path_ok(grid, cart.path, 0, roundi(cart.position)) or cart.blocked:
				_head_home(derived, entry, cart)
			continue
		if warehouse_ok and not cart.blocked and _path_ok(grid, cart.path, roundi(cart.position), cart.path.size() - 1):
			continue
		var target_warehouse := cart.warehouse_id if warehouse_ok else 0
		if target_warehouse == 0 and current >= 0:
			target_warehouse = derived.fields[entry.record.island_id].owner[current]
		var route := PackedInt32Array()
		if target_warehouse != 0 and current >= 0:
			route = derived.router(entry.record.island_id).path(current, derived.warehouse_target(target_warehouse, current, grid))
		if route.is_empty():
			cart.blocked = true
			if cart.state != Cart.State.OUTBOUND:
				cart.state = Cart.State.OUTBOUND
			continue
		cart.warehouse_id = target_warehouse
		cart.path = route
		cart.position = 0.0
		cart.previous_position = 0.0
		cart.blocked = false
		cart.state = Cart.State.OUTBOUND


static func _path_ok(grid: IslandGrid, path: PackedInt32Array, from: int, to: int) -> bool:
	if path.is_empty():
		return false
	for index: int in range(clampi(from, 0, path.size() - 1), clampi(to, 0, path.size() - 1) + 1):
		if grid.roads[path[index]] == IslandGrid.Road.NONE:
			return false
	return true
