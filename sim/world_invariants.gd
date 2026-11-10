class_name WorldInvariants
extends RefCounted
## Fase 386: o que toda partida tem de cumprir em qualquer tick. `check` devolve a lista do que está errado (vazia
## quando está tudo certo), cada linha um texto curto para o relatório do robô e dos testes. Só lê o mundo.
##
## Fica de fora de propósito o estoque acima da capacidade: demolir o entreposto maior baixa a capacidade e o que já
## estava guardado fica (o jogo não joga carga fora).

const EPSILON := 0.0001


static func check(world: WorldState, data: GameData) -> PackedStringArray:
	prepare(data)
	var problems := PackedStringArray()
	if not is_finite(world.money):
		problems.append("dinheiro não é número: %s" % world.money)
	if world.tick < 0:
		problems.append("tick negativo: %d" % world.tick)
	if world.economies.size() != world.islands.size():
		problems.append("%d ilhas e %d economias" % [world.islands.size(), world.economies.size()])
	for island_id: int in world.economies.size():
		_check_stock(problems, island_id, world.economies[island_id])
	_check_buildings(problems, world, data)
	_check_occupancy(problems, world)
	_check_carts(problems, world)
	_check_ships(problems, world, data)
	_check_states(problems, world, data)
	return problems


static func _bad(value: float) -> bool:
	return not is_finite(value) or value < -EPSILON


static func _check_stock(problems: PackedStringArray, island_id: int, economy: IslandEconomy) -> void:
	for good: StringName in economy.stock:
		if _bad(economy.stock[good]):
			problems.append("ilha %d: estoque de %s = %s" % [island_id, good, economy.stock[good]])


static func _check_buildings(problems: PackedStringArray, world: WorldState, data: GameData) -> void:
	for id: int in world.buildings:
		var record := world.buildings[id]
		var name := "prédio %d (%s)" % [id, record.def_id]
		if record.id != id:
			problems.append("%s guardado com o id %d" % [name, record.id])
		var def := data.building(record.def_id)
		if def == null:
			problems.append("%s: tipo desconhecido" % name)
			continue
		if record.island_id < 0 or record.island_id >= world.islands.size():
			problems.append("%s: ilha %d não existe" % [name, record.island_id])
			continue
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		if not world.islands[record.island_id].contains_rect(area):
			problems.append("%s: fora da ilha em %s" % [name, area])
		if record.is_house():
			if data.tier(record.tier) == null:
				problems.append("%s: classe %s desconhecida" % [name, record.tier])
			if _bad(record.residents):
				problems.append("%s: moradores = %s" % [name, record.residents])
			if not is_finite(record.happiness) or record.happiness < -EPSILON or record.happiness > 100.0 + EPSILON:
				problems.append("%s: felicidade = %s" % [name, record.happiness])
			if _bad(record.tax_per_min):
				problems.append("%s: imposto = %s" % [name, record.tax_per_min])
		if _bad(record.output_buffer):
			problems.append("%s: estoque de saída = %s" % [name, record.output_buffer])
		for good: StringName in record.input_buffer:
			if _bad(record.input_buffer[good]):
				problems.append("%s: entrada de %s = %s" % [name, good, record.input_buffer[good]])
		if not is_finite(record.progress) or record.progress < -EPSILON or record.progress > 1.0 + EPSILON:
			problems.append("%s: progresso = %s" % [name, record.progress])
		if not is_finite(record.productivity) or record.productivity < -EPSILON:
			problems.append("%s: produtividade = %s" % [name, record.productivity])


## A ocupação tem de bater com os prédios, nos dois sentidos: cada célula de um prédio marca o id dele, e cada célula
## marcada pertence a um prédio que existe e a cobre.
static func _check_occupancy(problems: PackedStringArray, world: WorldState) -> void:
	var expected: Array[PackedInt32Array] = []
	for grid: IslandGrid in world.islands:
		var empty := PackedInt32Array()
		empty.resize(grid.occupancy.size())
		expected.append(empty)
	for record: BuildingRecord in world.buildings.values():
		if record.island_id < 0 or record.island_id >= world.islands.size():
			continue
		var def_size: Vector2i = _sizes.get(record.def_id, Vector2i.ZERO)
		if def_size == Vector2i.ZERO:
			continue
		var grid := world.islands[record.island_id]
		var area := Footprint.rect(record.origin, def_size, record.rotation)
		var cells := expected[record.island_id]
		for y: int in range(area.position.y, area.end.y):
			for x: int in range(area.position.x, area.end.x):
				if x < 0 or y < 0 or x >= grid.size.x or y >= grid.size.y:
					continue
				var index := y * grid.size.x + x
				if cells[index] != 0:
					problems.append("ilha %d: prédios %d e %d na mesma célula (%d, %d)" % [record.island_id, cells[index],
							record.id, x, y])
				cells[index] = record.id
		expected[record.island_id] = cells
	for island_id: int in world.islands.size():
		var grid := world.islands[island_id]
		var cells := expected[island_id]
		var wrong := 0
		var first := -1
		for index: int in grid.occupancy.size():
			if grid.occupancy[index] != cells[index]:
				wrong += 1
				if first < 0:
					first = index
		if wrong > 0:
			var cell := grid.cell_at(first)
			problems.append("ilha %d: %d células da ocupação não batem com os prédios (a primeira em %s: %d, devia ser %d)"
					% [island_id, wrong, cell, grid.occupancy[first], cells[first]])


static var _sizes: Dictionary[StringName, Vector2i] = {}
static var _sizes_data: GameData


static func _check_carts(problems: PackedStringArray, world: WorldState) -> void:
	for home_id: int in world.carts:
		var cart := world.carts[home_id]
		var name := "carroça do prédio %d" % home_id
		if cart.home_id != home_id:
			problems.append("%s guardada com a casa %d" % [name, cart.home_id])
		var home := world.building(home_id)
		if home == null:
			problems.append("%s: o prédio não existe" % name)
			continue
		for good: StringName in cart.cargo:
			if _bad(cart.cargo[good]):
				problems.append("%s: carga de %s = %s" % [name, good, cart.cargo[good]])
		if not is_finite(cart.position) or cart.position < -EPSILON:
			problems.append("%s: posição = %s" % [name, cart.position])
		elif cart.is_away() and not cart.path.is_empty() and cart.position > float(cart.path.size() - 1) + EPSILON:
			problems.append("%s: posição %s além do caminho de %d células" % [name, cart.position, cart.path.size()])
		var grid := world.islands[home.island_id] if home.island_id >= 0 and home.island_id < world.islands.size() else null
		if grid != null:
			for cell: int in cart.path:
				if cell < 0 or cell >= grid.occupancy.size():
					problems.append("%s: célula %d do caminho fora da ilha" % [name, cell])
					break
		if cart.warehouse_id != 0 and cart.is_away() and world.building(cart.warehouse_id) == null:
			problems.append("%s: indo a um armazém que não existe (%d)" % [name, cart.warehouse_id])


static func _check_ships(problems: PackedStringArray, world: WorldState, data: GameData) -> void:
	for id: int in world.ships:
		var ship := world.ships[id]
		var name := "navio %d (%s)" % [id, ship.def_id]
		if ship.id != id:
			problems.append("%s guardado com o id %d" % [name, ship.id])
		if data.ship(ship.def_id) == null:
			problems.append("%s: tipo desconhecido" % name)
		if ship.route_id != 0 and not world.routes.has(ship.route_id):
			problems.append("%s: na rota %d, que não existe" % [name, ship.route_id])
		if ship.slot_goods.size() != ship.slot_tons.size():
			problems.append("%s: %d porões com bem e %d com toneladas" % [name, ship.slot_goods.size(), ship.slot_tons.size()])
		for tons: float in ship.slot_tons:
			if _bad(tons):
				problems.append("%s: porão com %s t" % [name, tons])
		if not is_finite(ship.hp):
			problems.append("%s: casco = %s" % [name, ship.hp])
		if ship.is_placed() and not (is_finite(ship.position.x) and is_finite(ship.position.y)):
			problems.append("%s: posição = %s" % [name, ship.position])
	for route_id: int in world.routes:
		for stop: TradeRoute.Stop in world.routes[route_id].stops:
			if not TradeRoute.valid_target(stop.target, world.islands.size()):
				problems.append("rota %d: parada na ilha %d, que não existe" % [route_id, stop.target])
	for trip: ExpeditionsState.Trip in world.expeditions_state.trips:
		if trip.ship != null and world.ships.has(trip.ship.id) and world.ships[trip.ship.id] == trip.ship:
			problems.append("navio %d em expedição e no mapa ao mesmo tempo" % trip.ship.id)


static func _check_states(problems: PackedStringArray, world: WorldState, data: GameData) -> void:
	for specialist: Specialist in world.specialists_state.specialists:
		if specialist.building_id != 0 and world.building(specialist.building_id) == null:
			problems.append("especialista %d num prédio que não existe (%d)" % [specialist.id, specialist.building_id])
	for building_id: int in world.risks_state.fires:
		if world.building(building_id) == null:
			problems.append("fogo num prédio que não existe (%d)" % building_id)
	for building_id: int in world.risks_state.outbreaks:
		if world.building(building_id) == null:
			problems.append("doença num prédio que não existe (%d)" % building_id)
	for building_id: int in world.shipyard_state.orders:
		var record := world.building(building_id)
		if record == null:
			problems.append("encomenda de navio num estaleiro que não existe (%d)" % building_id)
		elif data.building(record.def_id) != null and not data.building(record.def_id).is_shipyard():
			problems.append("encomenda de navio no prédio %d, que não é estaleiro" % building_id)
	for rival: RivalState in world.rivals_state.rivals:
		for island_id: int in rival.islands:
			if island_id <= 0 or island_id >= world.islands.size():
				problems.append("rival %s na ilha %d, que não existe" % [rival.def_id, island_id])
			elif world.has_trading_post(island_id, data):
				problems.append("rival %s na ilha %d, que tem entreposto do jogador" % [rival.def_id, island_id])


## O tamanho de cada tipo, guardado uma vez por GameData (a ocupação não procura a definição por prédio).
static func prepare(data: GameData) -> void:
	if _sizes_data == data:
		return
	_sizes_data = data
	_sizes.clear()
	for def: BuildingDef in data.buildings:
		_sizes[def.id] = def.size
