class_name ProgressionDemo
extends RefCounted
## Partida roteirizada da Fase 8 (critério: chegar à quinta classe). Monta na ilha plana uma
## cidade com as cadeias que levam do camponês ao investidor e faz o papel do jogador: a cada
## conferência trava o upgrade de casas suficientes em cada classe para manter a mão de obra que
## as fábricas pedem, e deixa as outras subirem. Constrói sem custo e sem desbloqueio; os bens,
## os materiais de upgrade e as necessidades são todos produzidos na partida. Usada pelo teste
## do critério e pela captura.

const ISLAND := Simulation.MAIN_ISLAND
## Ruas das casas, com os serviços a cada CLUSTER_SPACING células (o raio é de 25 por estrada).
const RESIDENTIAL_STREETS: Array[int] = [120, 136]
const CLUSTER_SPACING := 50
const CLUSTER_START := 18
## Casas de engenheiro mantidas como engenheiro (o resto sobe a investidor).
const ENGINEER_HOUSES := 4
## Folga de mão de obra: casas a mais em cada classe além das que as fábricas pedem.
const WORKFORCE_MARGIN := 1.15

## Prédios das cadeias, por rua (y da rua → lista de [prédio, quantos]). Acima da rua 4 fica o
## litoral (a borda da ilha plana).
const COAST := [[&"fishery", 8], [&"sand_pit", 1]]
const ROWS := {
	4: [[&"lumberjack", 4], [&"sawmill", 2], [&"weavery", 7], [&"clay_pit", 1], [&"brickworks", 2]],
	20: [[&"furnace", 4], [&"steel_beam_works", 1], [&"iron_mine", 2], [&"coal_mine", 3]],
	36: [[&"soap_factory", 3], [&"rendering_works", 5], [&"cannery", 2], [&"sewing_machine_factory", 2],
			[&"glassworks", 1], [&"window_works", 1]],
}
## Fazendas com os módulos (rua → [fazenda, quantas]).
const FARMS := {160: [[&"sheep_farm", 7]], 190: [[&"pig_farm", 5]]}
const SERVICES: Array[StringName] = [&"market", &"school", &"university"]

var simulation: Simulation
var houses: Array[int] = []


static func build(house_count: int = 210) -> ProgressionDemo:
	var config := GameConfig.new()
	config.main_island_size_cells = Vector2i(250, 250)
	config.starting_materials = {}
	config.starting_ship = &""
	config.instant_logistics = true
	var demo := ProgressionDemo.new()
	demo.simulation = Simulation.new(config, GameData.get_default())
	demo.simulation.free_build = true
	demo._lay_out(house_count)
	demo.manage()
	return demo


## O "jogador": trava o upgrade das primeiras casas de cada classe (por id) até a cota dela e
## destrava o resto. As cotas saem dos trabalhadores que as fábricas pedem.
func manage() -> void:
	var data := simulation.data
	var quota := quotas()
	var held: Dictionary[StringName, int] = {}
	for house_id: int in houses:
		var house := simulation.world.building(house_id)
		var count: int = held.get(house.tier, 0)
		var limit: int = quota.get(house.tier, 0)
		var keep := count < limit
		held[house.tier] = count + 1
		if house.upgrade_blocked != keep:
			house.upgrade_blocked = keep
	assert(data.tiers.size() == 5)


## Casas que cada classe mantém: as que a mão de obra pede (com folga); os engenheiros, um número
## fixo; os investidores, nenhuma trava (são o topo).
func quotas() -> Dictionary[StringName, int]:
	var data := simulation.data
	var workers: Dictionary[StringName, int] = {}
	for record: BuildingRecord in simulation.world.buildings.values():
		var def := data.building(record.def_id)
		if def.is_production():
			workers[def.workforce_tier] = workers.get(def.workforce_tier, 0) + def.workers
	var result: Dictionary[StringName, int] = {}
	for tier: TierDef in data.tiers:
		var needed: int = workers.get(tier.id, 0)
		result[tier.id] = ceili(needed * WORKFORCE_MARGIN / tier.residents_per_house)
	var engineers: int = result.get(&"engineers", 0)
	result[&"engineers"] = maxi(engineers, ENGINEER_HOUSES)
	return result


## Roda a partida por seconds de jogo, com o jogador conferindo as casas a cada check_s.
func run(seconds: float, check_s: float = 30.0) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		var chunk := minf(check_s, seconds - elapsed)
		simulation.run_ticks(roundi(chunk / simulation.config.tick_interval()))
		elapsed += chunk
		manage()


## Roda até haver uma casa da classe dada (ou o tempo acabar); devolve os segundos de jogo.
func run_until_tier(tier: StringName, max_seconds: float, check_s: float = 30.0) -> float:
	var elapsed := 0.0
	while elapsed < max_seconds:
		if houses_of(tier) > 0:
			return elapsed
		run(check_s, check_s)
		elapsed += check_s
	return elapsed


func houses_of(tier: StringName) -> int:
	var count := 0
	for house_id: int in houses:
		if simulation.world.building(house_id).tier == tier:
			count += 1
	return count


func _lay_out(house_count: int) -> void:
	var size := simulation.world.island(ISLAND).size
	# avenida que liga todas as ruas (os serviços medem por estrada)
	_road(Vector2i(1, 4), Vector2i(1, size.y - 10))
	for street_y: int in ROWS:
		_road(Vector2i(1, street_y), Vector2i(size.x - 2, street_y))
		var items: Array = ROWS[street_y]
		_row(street_y, items)
	_coast(4)
	for street_y: int in FARMS:
		_road(Vector2i(1, street_y), Vector2i(size.x - 2, street_y))
		var x := 4
		var farms: Array = FARMS[street_y]
		for item: Array in farms:
			var farm_id: StringName = item[0]
			var count: int = item[1]
			for i: int in count:
				_farm(farm_id, x, street_y)
				x += 18
	_residential(house_count)


## Prédios de litoral encostados na borda norte (y = 0), de frente para a rua; o que for mais
## raso que a rua ganha um trecho de estrada até ela.
func _coast(street_y: int) -> void:
	var x := 3
	for item: Array in COAST:
		var item_id: StringName = item[0]
		var def := simulation.data.building(item_id)
		var count: int = item[1]
		for i: int in count:
			_place(def.id, Vector2i(x, 0), 2)
			if def.size.y < street_y:
				_road(Vector2i(x, def.size.y), Vector2i(x + def.size.x - 1, def.size.y))
			x += def.size.x + 1


func _row(street_y: int, items: Array) -> void:
	var x := 3
	for item: Array in items:
		var item_id: StringName = item[0]
		var def := simulation.data.building(item_id)
		var count: int = item[1]
		for i: int in count:
			_place(def.id, Vector2i(x, street_y + 1), 0)
			x += def.size.x + 1


func _residential(house_count: int) -> void:
	for street: int in RESIDENTIAL_STREETS:
		_residential_street(street, house_count)


## Casas dos dois lados da rua; embaixo dela, um grupo de serviços a cada CLUSTER_SPACING.
func _residential_street(street: int, house_count: int) -> void:
	var size := simulation.world.island(ISLAND).size
	_road(Vector2i(1, street), Vector2i(size.x - 2, street))
	var blocked: Array[Vector2i] = []
	var cluster := CLUSTER_START
	while cluster < size.x - 20:
		var x := cluster
		for service: StringName in SERVICES:
			var def := simulation.data.building(service)
			_place(service, Vector2i(x, street + 1), 0)
			blocked.append(Vector2i(x, x + def.size.x))
			x += def.size.x
		cluster += CLUSTER_SPACING
	for side: int in 2:
		var x := 3
		while x + 3 < size.x - 2 and houses.size() < house_count:
			var free := true
			for span: Vector2i in blocked:
				if side == 1 and x + 3 > span.x and x < span.y:
					free = false
					x = span.y
					break
			if not free:
				continue
			var origin := Vector2i(x, street - 3) if side == 0 else Vector2i(x, street + 1)
			var result := simulation.execute(PlaceBuildingCommand.new(ISLAND, &"house", origin, 2 if side == 0 else 0))
			if result.ok():
				houses.append(result.placed[0])
			x += 3


func _farm(def_id: StringName, x: int, street_y: int) -> void:
	var def := simulation.data.building(def_id)
	var origin := Vector2i(x, street_y + 1)
	_place(def_id, origin, 0)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var module := simulation.data.building(def.module_id)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - module.size.y + 1, module.size.y):
		for cell_x: int in range(reach.position.x, reach.end.x - module.size.x + 1, module.size.x):
			if placed >= def.modules_required:
				return
			if simulation.execute(PlaceBuildingCommand.new(ISLAND, def.module_id, Vector2i(cell_x, y), 0)).ok():
				placed += 1
	assert(placed >= def.modules_required, "faltou lugar para os módulos de %s" % def_id)


func _place(def_id: StringName, origin: Vector2i, rotation: int) -> void:
	var result := simulation.execute(PlaceBuildingCommand.new(ISLAND, def_id, origin, rotation))
	assert(result.ok(), "não construiu %s em %s: %s" % [def_id, origin, result.reason])


func _road(from: Vector2i, to: Vector2i) -> void:
	simulation.execute(BuildRoadCommand.new(ISLAND, RoadPath.l_path(from, to)))
