class_name Statistics
extends RefCounted
## Retrato da economia de uma ilha para a tela de estatísticas: por bem, produção atual e
## potencial, consumo (das casas e dos prédios) e estoque, em t/min; população e finanças.
## "Atual" usa a produtividade média de cada prédio, não o estado do instante: o estado
## pisca "sem entrada" no tick em que um ciclo acaba e o próximo começa no tick seguinte.

class GoodLine:
	var good: StringName
	var produced: float = 0.0
	var potential: float = 0.0
	var consumed_by_houses: float = 0.0
	var consumed_by_buildings: float = 0.0
	var stock: float = 0.0

	func consumed() -> float:
		return consumed_by_houses + consumed_by_buildings

var goods: Array[GoodLine] = []
var population: Dictionary[StringName, int] = {}
var income_per_min: float = 0.0
var upkeep_per_min: float = 0.0


static func compute(world: WorldState, data: GameData, derived: DerivedState, island_id: int) -> Statistics:
	var report := Statistics.new()
	var economy := world.economy(island_id)
	var lines: Dictionary[StringName, GoodLine] = {}
	for good_def: GoodDef in data.goods:
		var line := GoodLine.new()
		line.good = good_def.id
		line.stock = economy.amount(good_def.id)
		line.consumed_by_houses = economy.needs_consumption_per_min.get(good_def.id, 0.0)
		lines[good_def.id] = line
		report.goods.append(line)
	for building_id: int in derived.production:
		var record := world.building(building_id)
		if record.island_id != island_id:
			continue
		var def := data.building(record.def_id)
		var rate := def.output_per_min()
		lines[def.output].potential += rate
		var running := rate * record.productivity
		lines[def.output].produced += running
		for input: StringName in def.inputs:
			lines[input].consumed_by_buildings += running
	var people: Dictionary[StringName, float] = {}
	for house_id: int in derived.houses:
		var house := world.building(house_id)
		if house.island_id == island_id:
			people[house.tier] = people.get(house.tier, 0.0) + house.residents
	for tier: TierDef in data.tiers:
		var count: float = people.get(tier.id, 0.0)
		report.population[tier.id] = floori(count)
	report.income_per_min = world.income_per_min
	report.upkeep_per_min = world.upkeep_per_min
	return report


func line(good: StringName) -> GoodLine:
	for entry: GoodLine in goods:
		if entry.good == good:
			return entry
	return null


func balance_per_min() -> float:
	return income_per_min - upkeep_per_min
