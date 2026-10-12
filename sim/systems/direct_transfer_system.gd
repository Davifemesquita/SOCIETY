class_name DirectTransferSystem
extends RefCounted
## PROVISÓRIO até a Fase 3: a saída dos prédios entra direto no estoque da ilha e as entradas
## saem direto dele, sem carroça. A Fase 3 troca este sistema pelas carroças e armazéns.
## Só prédios com estrada trocam com o estoque.
##
## Entrada escassa vai primeiro a quem precisa dela antes: cada consumidor recebe 1 t (o que
## basta para o próximo ciclo) em ordem de urgência — parado esperando, depois quem termina o
## ciclo antes — e só então os buffers são completados. Sem isso o primeiro consumidor enche
## o buffer inteiro e os outros ficam parados. Com estoque para todos, não há o que ordenar;
## com estoque para poucos (o caso comum na escassez), escolhe só os mais urgentes.


## Até este número de toneladas no estoque, escolhe os mais urgentes um a um em vez de
## ordenar a lista inteira.
const FEW_TAKERS := 8
const KEY_STRIDE := 1 << 20
## Urgência máxima na chave (prédio pausado), em centésimos de segundo.
const URGENCY_CAP := 1 << 30


static func run(world: WorldState, config: GameConfig, derived: DerivedState) -> void:
	var capacity := float(config.island_storage_capacity_t)
	var buffer := float(config.building_buffer_t)
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		if entry.has_road and entry.record.output_buffer > 0.0:
			entry.record.output_buffer -= entry.economy.add(entry.def.output, entry.record.output_buffer, capacity)
	for island_id: int in derived.consumers:
		var economy := world.economy(island_id)
		var by_good: Dictionary = derived.consumers[island_id]
		for input: StringName in by_good:
			var waiting: Array = by_good[input]
			var missing := 0.0
			for entry: DerivedState.ProductionEntry in waiting:
				var held: float = entry.record.input_buffer.get(input, 0.0)
				missing += maxf(0.0, buffer - held)
			if missing <= 0.0:
				continue
			var available := economy.amount(input)
			if available >= missing:
				for entry: DerivedState.ProductionEntry in waiting:
					_fill(economy, entry.record, input, buffer)
				continue
			var takers := ceili(available)
			if takers <= FEW_TAKERS:
				for entry: DerivedState.ProductionEntry in _most_urgent(waiting, input, takers):
					_fill(economy, entry.record, input, 1.0)
				continue
			var order := _by_urgency(waiting)
			for entry: DerivedState.ProductionEntry in order:
				_fill(economy, entry.record, input, 1.0)
			for entry: DerivedState.ProductionEntry in order:
				_fill(economy, entry.record, input, buffer)


## Ordena pela urgência (em centésimos de segundo) e, no empate, pela ordem da lista (que já
## é a de id). A chave junta as duas num inteiro só, para usar a ordenação nativa.
static func _by_urgency(waiting: Array) -> Array:
	var keys := PackedInt64Array()
	keys.resize(waiting.size())
	for index: int in waiting.size():
		var entry: DerivedState.ProductionEntry = waiting[index]
		keys[index] = mini(roundi(_urgency(entry) * 100.0), URGENCY_CAP) * KEY_STRIDE + index
	keys.sort()
	var ordered: Array = []
	ordered.resize(waiting.size())
	for position: int in keys.size():
		ordered[position] = waiting[keys[position] % KEY_STRIDE]
	return ordered


## Os count consumidores mais urgentes que ainda não têm 1 t da entrada, em ordem.
static func _most_urgent(waiting: Array, input: StringName, count: int) -> Array:
	var chosen: Array = []
	var taken: Dictionary[int, bool] = {}
	for round: int in count:
		var best: DerivedState.ProductionEntry = null
		var best_urgency := INF
		for entry: DerivedState.ProductionEntry in waiting:
			if taken.has(entry.record.id):
				continue
			var held: float = entry.record.input_buffer.get(input, 0.0)
			if held >= 1.0:
				continue
			var urgency := _urgency(entry)
			if urgency < best_urgency:
				best = entry
				best_urgency = urgency
		if best == null:
			break
		taken[best.record.id] = true
		chosen.append(best)
	return chosen


## Segundos até o prédio precisar da próxima tonelada: 0 se está parado esperando.
static func _urgency(entry: DerivedState.ProductionEntry) -> float:
	if entry.record.paused:
		return URGENCY_CAP / 100.0
	if not entry.record.in_cycle:
		return 0.0
	return (1.0 - entry.record.progress) * entry.def.cycle_s


static func _fill(economy: IslandEconomy, record: BuildingRecord, input: StringName, up_to: float) -> void:
	var held: float = record.input_buffer.get(input, 0.0)
	if held < up_to:
		record.input_buffer[input] = held + economy.take(input, up_to - held)
