class_name StatisticsHistory
extends RefCounted
## Série histórica das estatísticas (seção 10, gráficos históricos): uma amostra a cada
## history_interval_s de jogo, com dinheiro, receita, manutenção, população por classe e, por ilha,
## a produção e o consumo de cada bem (t/min). Guarda as últimas history_samples.
## Todas as séries têm o mesmo comprimento (a última amostra é o último valor); série que aparece
## depois começa com zeros. Vai no save: o gráfico continua depois de carregar.

## Tick de cada amostra.
var ticks := PackedInt32Array()
var money := PackedFloat32Array()
var income := PackedFloat32Array()
var upkeep := PackedFloat32Array()
## Moradores por classe (todas as ilhas).
var population: Dictionary[StringName, PackedFloat32Array] = {}
## t/min por "ilha/bem".
var produced: Dictionary[String, PackedFloat32Array] = {}
var consumed: Dictionary[String, PackedFloat32Array] = {}


func size() -> int:
	return ticks.size()


static func key(island_id: int, good: StringName) -> String:
	return "%d/%s" % [island_id, good]


## Uma amostra do estado agora. Bem sem produção nem consumo numa ilha não ganha série.
func record(world: WorldState, data: GameData, derived: DerivedState, max_samples: int) -> void:
	var count := ticks.size()
	ticks.append(world.tick)
	money.append(world.money)
	income.append(world.income_per_min)
	upkeep.append(world.upkeep_per_min)
	var people: Dictionary[StringName, float] = {}
	for island_id: int in world.islands.size():
		var residents := derived.residents_by_tier(island_id)
		for tier: StringName in residents:
			people[tier] = people.get(tier, 0.0) + residents[tier]
	for tier: TierDef in data.tiers:
		var residents_now: float = people.get(tier.id, 0.0)
		_push(population, tier.id, residents_now, count)
	for island_id: int in world.islands.size():
		var report := Statistics.compute(world, data, derived, island_id)
		for line: Statistics.GoodLine in report.goods:
			if line.potential > 0.0 or line.consumed() > 0.0 or produced.has(key(island_id, line.good)):
				_push(produced, key(island_id, line.good), line.produced, count)
				_push(consumed, key(island_id, line.good), line.consumed(), count)
	_pad(count + 1)
	while ticks.size() > max_samples:
		_drop_first()


## Acrescenta o valor na série, criando-a com zeros se é nova.
static func _push(series: Dictionary, name: Variant, value: float, count: int) -> void:
	var values: PackedFloat32Array = series.get(name, PackedFloat32Array())
	while values.size() < count:
		values.append(0.0)
	values.append(value)
	series[name] = values


## Séries que não receberam valor nesta amostra (ilha que perdeu o entreposto) ganham zero.
func _pad(length: int) -> void:
	for series: Dictionary in [population, produced, consumed]:
		for name: Variant in series:
			var values: PackedFloat32Array = series[name]
			while values.size() < length:
				values.append(0.0)
			series[name] = values


func _drop_first() -> void:
	# um a um: array empacotado dentro de outro array seria alterado numa cópia
	ticks.remove_at(0)
	money.remove_at(0)
	income.remove_at(0)
	upkeep.remove_at(0)
	for series: Dictionary in [population, produced, consumed]:
		for name: Variant in series:
			var values: PackedFloat32Array = series[name]
			values.remove_at(0)
			series[name] = values


## Produção e consumo de um bem: numa ilha, ou somados em todas (island_id < 0).
func good_series(island_id: int, good: StringName, of_production: bool) -> PackedFloat32Array:
	var source := produced if of_production else consumed
	if island_id >= 0:
		return source.get(key(island_id, good), PackedFloat32Array())
	var total := PackedFloat32Array()
	total.resize(ticks.size())
	for name: String in source:
		if name.get_slice("/", 1) == String(good):
			var values: PackedFloat32Array = source[name]
			for i: int in mini(values.size(), total.size()):
				total[i] += values[i]
	return total


func to_dict() -> Dictionary:
	return {"ticks": ticks, "money": money, "income": income, "upkeep": upkeep,
			"population": population.duplicate(), "produced": produced.duplicate(), "consumed": consumed.duplicate()}


## Volta do save; conteúdo inconsistente devolve null (o save inteiro é recusado).
static func from_dict(data: Dictionary) -> StatisticsHistory:
	var history := StatisticsHistory.new()
	var raw_ticks: Variant = data.get("ticks")
	if not raw_ticks is PackedInt32Array:
		return null
	history.ticks = raw_ticks
	var length := history.ticks.size()
	for field: String in ["money", "income", "upkeep"]:
		var raw: Variant = data.get(field)
		if not raw is PackedFloat32Array:
			return null
		var values: PackedFloat32Array = raw
		if values.size() != length:
			return null
		history.set(field, values)
	var raw_population: Variant = data.get("population")
	if not raw_population is Dictionary:
		return null
	var population_data: Dictionary = raw_population
	for tier: Variant in population_data:
		var values: Variant = population_data[tier]
		if not (tier is StringName and values is PackedFloat32Array):
			return null
		var series: PackedFloat32Array = values
		if series.size() != length:
			return null
		var tier_id: StringName = tier
		history.population[tier_id] = series
	for field: String in ["produced", "consumed"]:
		var raw: Variant = data.get(field)
		if not raw is Dictionary:
			return null
		var source: Dictionary = raw
		var target: Dictionary[String, PackedFloat32Array] = history.produced if field == "produced" else history.consumed
		for name: Variant in source:
			var values: Variant = source[name]
			if not (name is String and values is PackedFloat32Array):
				return null
			var series: PackedFloat32Array = values
			if series.size() != length:
				return null
			var series_name: String = name
			target[series_name] = series
	return history
