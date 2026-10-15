class_name AutoPlayer
extends RefCounted
## Jogador-robô da Fase 10 (balanceamento e critério das 3 horas): joga uma partida de verdade na
## ilha plana — paga cada prédio em moedas e materiais, espera o desbloqueio, usa carroças e armazéns
## — seguindo uma ordem de construção como a de um jogador. As casas crescem quando as que existem
## enchem; cada fábrica só entra quando há mão de obra livre para ela; o upgrade das casas é travado
## para manter os trabalhadores de cada classe (como na ProgressionDemo). Guarda o pior saldo e um
## diário do que construiu e de quanto esperou.

const ISLAND := Simulation.MAIN_ISLAND
## A estrada principal corre em y = 6, de ponta a ponta, na frente do entreposto (x 0 a 5, no litoral
## norte). As outras ruas de produção ficam a cada STREET_STEP células para baixo; as casas, nas ruas
## RESIDENTIAL; as fazendas, nas ruas FARM. Avenidas verticais ligam tudo a cada AVENUE_STEP.
const MAIN_STREET := 6
const PRODUCTION_STREETS: Array[int] = [6, 22, 38, 170, 186, 202, 218]
const RESIDENTIAL_STREETS: Array[int] = [54, 70, 86, 100]
const FARM_STREETS: Array[int] = [110, 125, 140, 155]
const AVENUE_STEP := 60
## Armazém a cada tantas células numa rua (o alcance da carroça é de 40 por estrada).
const WAREHOUSE_STEP := 30
const SERVICE_STEP := 48
## Folga de dinheiro que o robô não gasta (um jogador não constrói até o último tostão).
const RESERVE := 1500.0
## As casas crescem quando a ocupação média passa disto.
const HOUSE_FILL := 0.7
const HOUSES_PER_ROUND := 4
## Fábrica só entra com esta fração dos trabalhadores dela livres na classe.
const WORKFORCE_NEEDED := 0.75
const WORKFORCE_MARGIN := 1.15
const ENGINEER_HOUSES := 4
## Depois de pôr um produtor na frente, espera tanto antes de julgar outra falta (s de jogo).
const SHORTAGE_PAUSE_S := 45.0
## Obra urgente (contra uma falta) gasta até esta folga acima do limite do saldo negativo.
const URGENT_MARGIN := 2000.0
## Pausa a fábrica com o estoque do produto acima desta fração e volta abaixo desta outra.
const REST_ABOVE := 0.95
const RESUME_BELOW := 0.6

## Ordem de construção: [prédio, quantos]. "coast" vai no litoral; "farm" com os módulos.
const ORDER: Array = [
	[&"lumberjack", 2], [&"sawmill", 1], [&"fishery", 2],
	[&"sheep_farm", 2], [&"weavery", 1], [&"lumberjack", 1], [&"sawmill", 1], [&"fishery", 1],
	[&"pig_farm", 2], [&"rendering_works", 2], [&"soap_factory", 1],
	[&"clay_pit", 1], [&"brickworks", 2], [&"fishery", 2], [&"sheep_farm", 2], [&"weavery", 1],
	[&"coal_mine", 2], [&"iron_mine", 1], [&"furnace", 2], [&"steel_beam_works", 1],
	[&"sewing_machine_factory", 1], [&"pig_farm", 1], [&"rendering_works", 1], [&"soap_factory", 1],
	[&"sand_pit", 1], [&"glassworks", 1], [&"cannery", 1], [&"fishery", 2], [&"furnace", 1],
	[&"window_works", 1], [&"sheep_farm", 2], [&"weavery", 1], [&"fishery", 2],
]
const COAST: Array[StringName] = [&"fishery", &"sand_pit", &"clay_pit"]
const RESIDENTIAL_SERVICES: Array[StringName] = [&"market", &"school", &"university"]

var simulation: Simulation
var houses: Array[int] = []
## Pior saldo visto e quando (segundos de jogo).
var lowest_money: float = INF
var lowest_at: float = 0.0
var seconds: float = 0.0
## Diário: [segundos de jogo, texto], para a planilha e para ajustar o balanceamento.
var log: Array = []

var _queue: Array[StringName] = []
var _street_cursor: Dictionary[int, int] = {}
var _residential_cursor: Dictionary[String, int] = {}
var _services: Dictionary[String, bool] = {}
var _roads_built: Dictionary[int, int] = {}
var _avenues: Dictionary[int, int] = {}
var _warehouses: Dictionary[String, bool] = {}
var _coast_cursor: int = 10
var _farm_cursor: Dictionary[int, int] = {}
var _blocked_reason: StringName = &""
var _next_fix_at: float = 0.0
var _urgent: Dictionary[StringName, bool] = {}


static func create(config: GameConfig = null) -> AutoPlayer:
	var player := AutoPlayer.new()
	var game_config := config if config != null else GameConfig.get_default()
	player.simulation = Simulation.new(game_config, GameData.get_default())
	for item: Array in ORDER:
		var count: int = item[1]
		for i: int in count:
			player._queue.append(item[0])
	return player


## Joga seconds de jogo, decidindo a cada decision_s.
func play(duration_s: float, decision_s: float = 10.0) -> void:
	var dt := simulation.config.tick_interval()
	var end := seconds + duration_s
	while seconds < end:
		decide()
		var ticks := roundi(decision_s / dt)
		for i: int in ticks:
			simulation.tick(0)
			var money := simulation.world.money
			if money < lowest_money:
				lowest_money = money
				lowest_at = seconds + i * dt
		seconds += decision_s


## Uma rodada de decisões: o entreposto, as casas, a próxima fábrica e as travas de upgrade.
func decide() -> void:
	var world := simulation.world
	if not world.has_trading_post(ISLAND, simulation.data):
		_build(&"trading_post", Vector2i(0, 0), 2)
		_road(Vector2i(0, MAIN_STREET), Vector2i(30, MAIN_STREET))
		_roads_built[MAIN_STREET] = 30
		return
	_fix_shortage()
	_rest_idle_factories()
	_maintain_services()
	_grow_houses()
	_next_production()
	_hold_workforce()


func houses_of(tier: StringName) -> int:
	var count := 0
	for house_id: int in houses:
		if simulation.world.building(house_id).tier == tier:
			count += 1
	return count


func next_in_queue() -> StringName:
	return _queue[0] if not _queue.is_empty() else &""


func blocked_reason() -> StringName:
	return _blocked_reason


func summary() -> String:
	var parts: Array[String] = []
	for tier: TierDef in simulation.data.tiers:
		parts.append("%s %d" % [tier.id, simulation.world.population(tier.id)])
	return "%.0f min | %s | $%.0f (pior %.0f aos %.0f min) | fila %d (%s) | parado: %s" % [seconds / 60.0, ", ".join(parts),
			simulation.world.money, lowest_money, lowest_at / 60.0, _queue.size(), _queue[0] if not _queue.is_empty() else &"",
			_blocked_reason]


# --- casas e travas -------------------------------------------------------------------------

func _grow_houses() -> void:
	var residents := 0.0
	var capacity := 0.0
	for house_id: int in houses:
		var record := simulation.world.building(house_id)
		residents += record.residents
		capacity += simulation.data.tier(record.tier).residents_per_house
	var full := houses.is_empty() or residents >= capacity * HOUSE_FILL
	# falta gente para a próxima fábrica: casa nova nasce camponesa e as outras classes vêm do upgrade,
	# então faltando operário ou artesão também se constrói (antes o robô esperava parado, com o caixa
	# cheio, uma subida que não vinha)
	var short := _workforce_short()
	# casa nova só com quem já mora bem servido (ou faltando gente para a próxima fábrica)
	if not short and (not full or not _basic_needs_met()):
		return
	for i: int in HOUSES_PER_ROUND:
		if not _can_spend(50.0):
			return
		if not _place_house():
			return


## Todas as necessidades básicas de bem das classes que têm moradores estão atendidas.
func _basic_needs_met() -> bool:
	var economy := simulation.world.economy(ISLAND)
	for tier: TierDef in simulation.data.tiers:
		if simulation.world.population(tier.id) <= 0:
			continue
		for need: NeedCategoryDef in tier.basic_needs:
			if not need.goods.is_empty() and economy.supply_of(tier.id, need.id) < simulation.config.need_met_threshold:
				return false
	return true


## O que um jogador faz quando algo falta: põe o produtor na frente da fila. Bem de necessidade
## básica abaixo do atendimento, ou entrada que deixa fábricas paradas. Um por vez, com uma pausa
## para o efeito aparecer.
func _fix_shortage() -> void:
	if seconds < _next_fix_at:
		return
	var good := _short_good()
	if good == &"":
		return
	var producer := _producer_of(good)
	if producer == &"" or _queue.slice(0, 2).has(producer):
		return
	_queue.push_front(producer)
	_urgent[producer] = true
	_next_fix_at = seconds + SHORTAGE_PAUSE_S
	log.append([seconds, "falta %s: %s na frente" % [good, producer]])


func _short_good() -> StringName:
	var world := simulation.world
	var economy := world.economy(ISLAND)
	# material de construção que trava a fila há um tempo
	if _blocked_reason == PlacementRules.NO_MATERIALS and not _queue.is_empty():
		var waiting := simulation.data.building(_queue[0])
		for material: StringName in waiting.cost_materials:
			if economy.amount(material) < waiting.cost_materials[material]:
				return _root_shortage(material)
	for tier: TierDef in simulation.data.tiers:
		if world.population(tier.id) <= 0:
			continue
		for need: NeedCategoryDef in tier.basic_needs:
			if need.goods.is_empty() or economy.supply_of(tier.id, need.id) >= simulation.config.need_met_threshold:
				continue
			for good: StringName in need.goods:
				var producer := _producer_of(good)
				if producer != &"" and PlacementRules.check_unlock(world, simulation.data.building(producer)) == PlacementRules.OK:
					return _root_shortage(good)
	for record: BuildingRecord in world.buildings.values():
		if record.state == BuildingRecord.State.NO_INPUT:
			for input: StringName in simulation.def_of(record).inputs:
				if economy.amount(input) < 2.0:
					return _root_shortage(input)
	return &""


## Se o bem que falta para por falta de entrada, a falta de verdade é a entrada.
func _root_shortage(good: StringName) -> StringName:
	var economy := simulation.world.economy(ISLAND)
	var def := simulation.data.building(_producer_of(good))
	for input: StringName in def.inputs:
		if economy.amount(input) < 2.0:
			var waiting := 0
			for record: BuildingRecord in simulation.world.buildings.values():
				if record.def_id == def.id and record.state == BuildingRecord.State.NO_INPUT:
					waiting += 1
			if waiting > 0:
				return _root_shortage(input)
	return good


func _producer_of(good: StringName) -> StringName:
	for def: BuildingDef in simulation.data.buildings:
		if def.is_production() and def.output == good and not simulation.data.trader().sells.has(def.inputs[0] if not def.inputs.is_empty() else &""):
			return def.id
	return &""


## Falta gente para a próxima fábrica da fila (as casas crescem mesmo sem estarem cheias).
func _short_tier() -> StringName:
	return simulation.data.building(_queue[0]).workforce_tier if not _queue.is_empty() else &""


func _workforce_short() -> bool:
	if _queue.is_empty():
		return false
	var def := simulation.data.building(_queue[0])
	if not def.is_production():
		return false
	return _free_workforce(def.workforce_tier) < def.workers * WORKFORCE_NEEDED


func _free_workforce(tier: StringName) -> float:
	var demand := 0.0
	for record: BuildingRecord in simulation.world.buildings.values():
		var def := simulation.def_of(record)
		if def.is_production() and def.workforce_tier == tier:
			demand += def.workers
	return simulation.world.population(tier) - demand


## Trava o upgrade das primeiras casas de cada classe até a mão de obra que as fábricas pedem.
func _hold_workforce() -> void:
	var data := simulation.data
	var needed: Dictionary[StringName, float] = {}
	for record: BuildingRecord in simulation.world.buildings.values():
		var def := simulation.def_of(record)
		if def.is_production():
			needed[def.workforce_tier] = needed.get(def.workforce_tier, 0.0) + def.workers
	if not _queue.is_empty():
		var next := data.building(_queue[0])
		if next.is_production():
			needed[next.workforce_tier] = needed.get(next.workforce_tier, 0.0) + next.workers
	var quota: Dictionary[StringName, int] = {}
	for tier: TierDef in data.tiers:
		var workers: float = needed.get(tier.id, 0.0)
		quota[tier.id] = ceili(workers * WORKFORCE_MARGIN / tier.residents_per_house)
	var engineers: int = quota.get(&"engineers", 0)
	quota[&"engineers"] = maxi(engineers, ENGINEER_HOUSES)
	var held: Dictionary[StringName, int] = {}
	for house_id: int in houses:
		var house := simulation.world.building(house_id)
		var count: int = held.get(house.tier, 0)
		var limit: int = quota.get(house.tier, 0)
		house.upgrade_blocked = count < limit
		held[house.tier] = count + 1


# --- fábricas -------------------------------------------------------------------------------

func _next_production() -> void:
	if _queue.is_empty():
		_blocked_reason = &""
		return
	var def_id := _queue[0]
	var def := simulation.data.building(def_id)
	if def.is_production() and _free_workforce(def.workforce_tier) < def.workers * WORKFORCE_NEEDED:
		_blocked_reason = &"WORKFORCE"
		return
	var urgent := _urgent.has(def_id)
	if not (_can_spend_urgent(def.cost_money) if urgent else _can_spend(def.cost_money)):
		_blocked_reason = &"RESERVE"
		return
	var reason := simulation.affordability(def)
	if reason != PlacementRules.OK:
		_blocked_reason = reason
		return
	var placed := false
	if COAST.has(def_id):
		placed = _place_coast(def)
	elif def.kind == BuildingDef.Kind.SERVICE:
		placed = _place_service(def)
	elif def.modules_required > 0:
		placed = _place_farm(def)
	else:
		placed = _place_on_street(def)
	if not placed:
		_blocked_reason = &"FULL"
	if placed:
		_queue.pop_front()
		_urgent.erase(def_id)
		_blocked_reason = &""
		log.append([seconds, "construiu %s" % def_id])


func _can_spend(cost: float) -> bool:
	return simulation.world.money - cost >= RESERVE


## Obra que resolve uma falta pode ir até perto do limite do saldo negativo.
func _can_spend_urgent(cost: float) -> bool:
	var floor_money := simulation.config.min_balance_for(simulation.world.difficulty) + URGENT_MARGIN
	return simulation.world.money - cost >= floor_money


## Fábrica com o estoque do que ela faz quase cheio para (pausada paga metade da manutenção) e volta
## quando o estoque baixa: o que um jogador faz para não pagar por produção que ninguém usa.
func _rest_idle_factories() -> void:
	var economy := simulation.world.economy(ISLAND)
	var capacity := simulation.storage_capacity(ISLAND)
	for record: BuildingRecord in simulation.world.buildings.values():
		var def := simulation.def_of(record)
		if not def.is_production():
			continue
		var stock := economy.amount(def.output) / capacity
		if not record.paused and stock >= REST_ABOVE:
			simulation.execute(SetPausedCommand.new(record.id, true))
		elif record.paused and stock <= RESUME_BELOW:
			simulation.execute(SetPausedCommand.new(record.id, false))


## Litoral norte: o prédio encostado na borda (y = 0), com uma estradinha até a rua principal.
func _place_coast(def: BuildingDef) -> bool:
	var x := _coast_cursor
	var origin := Vector2i(x, 0)
	if not _try(def.id, origin, 2):
		return false
	_coast_cursor += def.size.x + 1
	var front := x + def.size.x / 2
	_road(Vector2i(front, def.size.y), Vector2i(front, MAIN_STREET - 1))
	_extend_street(MAIN_STREET, x + def.size.x)
	return true


## Fábricas nas ruas de produção, embaixo da rua, com um armazém a cada WAREHOUSE_STEP células.
func _place_on_street(def: BuildingDef) -> bool:
	for street: int in PRODUCTION_STREETS:
		var x: int = _street_cursor.get(street, 12 if street == MAIN_STREET else 4)
		if x + def.size.x >= simulation.world.island(ISLAND).size.x - 4:
			continue
		x = _skip_reserved(x, def.size.x)
		_ensure_street(street, x + def.size.x)
		if not _ensure_warehouse(street, x):
			return false
		if _try(def.id, Vector2i(x, street + 1), 0):
			_street_cursor[street] = x + def.size.x + 1
			return true
		_street_cursor[street] = x + 1
	return false


## Fazenda numa rua de fazendas, com os campos ou pastos no raio, todos pagos.
func _place_farm(def: BuildingDef) -> bool:
	for street: int in FARM_STREETS:
		var cursor: int = _farm_cursor.get(street, 6)
		var x := _skip_reserved(cursor, 4)
		if x + 14 >= simulation.world.island(ISLAND).size.x - 4:
			continue
		_ensure_street(street, x + 14)
		if not _ensure_warehouse(street, x):
			return false
		var origin := Vector2i(x, street + 1)
		if not _try(def.id, origin, 0):
			_farm_cursor[street] = x + 2
			continue
		_farm_cursor[street] = x + 16
		var module := simulation.data.building(def.module_id)
		var placed := 0
		var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
		for y: int in range(street + 1, reach.end.y - module.size.y + 1, module.size.y):
			for cell_x: int in range(reach.position.x, reach.end.x - module.size.x + 1, module.size.x):
				var slot_start := (cell_x / WAREHOUSE_STEP) * WAREHOUSE_STEP
				var touches_slot := cell_x < slot_start + 6 or cell_x + module.size.x > slot_start + WAREHOUSE_STEP
				if placed < def.modules_required and not touches_slot and _try(def.module_id, Vector2i(cell_x, y), 0):
					placed += 1
		return true
	return false


## Serviços entram junto com as casas (ver _ensure_services): fora disso, a fila só os pula.
func _place_service(_def: BuildingDef) -> bool:
	return true


## Casas dos dois lados das ruas residenciais, em grupos de SERVICE_STEP células: o grupo ganha o
## mercado antes da primeira casa, a escola quando há operários e a universidade quando há
## engenheiros (o raio é de 25 células por estrada, e as ruas residenciais não se ligam entre si).
func _place_house() -> bool:
	var width := simulation.world.island(ISLAND).size.x
	for street: int in RESIDENTIAL_STREETS:
		for side: int in 2:
			var key := "%d/%d" % [street, side]
			var x: int = _residential_cursor.get(key, 2)
			while x + 3 < width - 2:
				if side == 1 and _in_service_slot(x):
					x += 1
					continue
				if not _ensure_services(street, x):
					return false
				_ensure_residential(street, x + 3)
				var origin := Vector2i(x, street - 3) if side == 0 else Vector2i(x, street + 1)
				var result := simulation.execute(PlaceBuildingCommand.new(ISLAND, &"house", origin, 2 if side == 0 else 0))
				if result.ok():
					houses.append(result.placed[0])
					_residential_cursor[key] = x + 3
					return true
				if result.reason in [PlacementRules.NO_MONEY, PlacementRules.NO_MATERIALS]:
					return false
				x += 1
			_residential_cursor[key] = x
	return false


## Os serviços do grupo da casa em x (embaixo da rua, no começo do grupo); falso se o mercado ainda
## não deu para pagar (a casa espera).
func _ensure_services(street: int, x: int) -> bool:
	var cluster := maxi(0, (x - 4) / SERVICE_STEP)
	var start := 10 + cluster * SERVICE_STEP
	var world := simulation.world
	for index: int in RESIDENTIAL_SERVICES.size():
		var service := RESIDENTIAL_SERVICES[index]
		var key := "%s/%d/%d" % [service, street, cluster]
		if _services.has(key):
			continue
		var wanted := service == &"market" \
				or (service == &"school" and world.population(&"workers") > 0) \
				or (service == &"university" and world.population(&"engineers") > 0)
		if not wanted:
			continue
		var def := simulation.data.building(service)
		if not _can_spend(def.cost_money) or simulation.affordability(def) != PlacementRules.OK:
			if service == &"market":
				return false
			continue
		_ensure_residential(street, start + index * 7 + def.size.x)
		if _try(service, Vector2i(start + index * 7, street + 1), 0):
			_services[key] = true
			log.append([seconds, "%s no grupo %d da rua %d" % [service, cluster, street]])
	return true


## Todo grupo que já tem casa ganha os serviços que a classe dele pede agora (escola quando chegam
## os operários, universidade com os engenheiros), não só quando entra casa nova.
func _maintain_services() -> void:
	for key: String in _residential_cursor:
		var parts := key.split("/")
		var street := parts[0].to_int()
		var reached: int = _residential_cursor[key]
		for x: int in range(2, reached, SERVICE_STEP):
			_ensure_services(street, x)


func _in_service_slot(x: int) -> bool:
	var cluster := maxi(0, (x - 4) / SERVICE_STEP)
	var start := 10 + cluster * SERVICE_STEP
	return x + 3 > start and x < start + 22


# --- ruas e armazéns ------------------------------------------------------------------------

## A rua de produção chega até x (paga só o trecho novo), ligada pela avenida da esquerda.
func _ensure_street(street: int, to_x: int) -> void:
	if street != MAIN_STREET:
		_ensure_avenue(0, street)
	_extend_street(street, to_x)


func _extend_street(street: int, to_x: int) -> void:
	var built: int = _roads_built.get(street, -1)
	if to_x <= built:
		return
	_road(Vector2i(maxi(built, 0), street), Vector2i(to_x + 1, street))
	_roads_built[street] = to_x + 1


func _ensure_avenue(x: int, to_y: int) -> void:
	var built: int = _avenues.get(x, MAIN_STREET)
	if to_y <= built:
		return
	_road(Vector2i(x, built), Vector2i(x, to_y))
	_avenues[x] = to_y


## Rua das casas: não precisa chegar ao entreposto (o consumo não usa carroça).
func _ensure_residential(street: int, to_x: int) -> void:
	_extend_street(street, to_x)


## O armazém do trecho da rua existe (ou acabou de ser construído); falso enquanto não dá para pagar.
func _ensure_warehouse(street: int, x: int) -> bool:
	var slot := x / WAREHOUSE_STEP
	var key := "%d/%d" % [street, slot]
	if _warehouses.has(key) or (street == MAIN_STREET and slot == 0):
		return true
	_ensure_street(street, slot * WAREHOUSE_STEP + WAREHOUSE_STEP)
	for at: int in range(slot * WAREHOUSE_STEP + 1, slot * WAREHOUSE_STEP + WAREHOUSE_STEP - 4):
		if _occupied_by_warehouse(Vector2i(at, street + 1)):
			_warehouses[key] = true
			return true
		var result := simulation.execute(PlaceBuildingCommand.new(ISLAND, &"warehouse", Vector2i(at, street + 1), 0))
		if result.ok():
			_warehouses[key] = true
			log.append([seconds, "armazém em %d/%d" % [street, at]])
			return true
		if result.reason in [PlacementRules.NO_MONEY, PlacementRules.NO_MATERIALS]:
			break
	_blocked_reason = &"WAREHOUSE"
	return false


func _occupied_by_warehouse(cell: Vector2i) -> bool:
	var id := simulation.world.island(ISLAND).building_at(cell)
	return id != 0 and simulation.def_of(simulation.world.building(id)).is_warehouse()


## Pula o lugar dos armazéns e das avenidas.
func _skip_reserved(x: int, width: int) -> int:
	var cursor := x
	while true:
		var slot_start := (cursor / WAREHOUSE_STEP) * WAREHOUSE_STEP
		var in_warehouse := cursor < slot_start + 6
		var crosses_next := cursor + width > slot_start + WAREHOUSE_STEP
		if in_warehouse:
			cursor = slot_start + 6
		elif crosses_next:
			cursor = slot_start + WAREHOUSE_STEP + 6
		else:
			return cursor
	return cursor


func _try(def_id: StringName, origin: Vector2i, rotation: int) -> bool:
	var result := simulation.execute(PlaceBuildingCommand.new(ISLAND, def_id, origin, rotation))
	if not result.ok() and result.reason not in [PlacementRules.NO_MONEY, PlacementRules.NO_MATERIALS, PlacementRules.LOCKED,
			PlacementRules.OCCUPIED, PlacementRules.ON_ROAD]:
		push_warning("AutoPlayer: %s em %s recusado: %s" % [def_id, origin, result.reason])
	return result.ok()


func _road(from: Vector2i, to: Vector2i) -> void:
	simulation.execute(BuildRoadCommand.new(ISLAND, RoadPath.l_path(from, to)))


func _build(def_id: StringName, origin: Vector2i, rotation: int) -> void:
	_try(def_id, origin, rotation)
