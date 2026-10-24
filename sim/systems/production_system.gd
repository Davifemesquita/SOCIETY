class_name ProductionSystem
extends RefCounted
## Produção por ciclo: cada ciclo consome 1 t de cada entrada (no começo) e gera 1 t da
## saída (no fim). A velocidade é a da força de trabalho da classe. O prédio para sem
## estrada, sem os módulos, sem árvores (lenhador), sem entrada, sem trabalhador, com a saída
## cheia ou pausado.
## Eventos (Fase 11) multiplicam a velocidade (boa colheita, veio rico).
## Eletricidade (Fase 11): a usina queima a entrada sem gerar bem; a fábrica no raio de uma usina
## que produzia no tick anterior ganha electricity_bonus na velocidade.
## Especialistas (Fase 11): o de velocidade multiplica o fator; o de tonelada extra conta os ciclos.
## Riscos: o prédio em chamas para (o ciclo espera o fogo apagar).
## O estaleiro não tem ciclo: o ShipyardSystem cuida dele.
## O fim do ciclo tem folga de 1e-6: 75 ticks de 0,2/15 somam 0,99999… e o ciclo atrasaria
## um tick inteiro a cada volta.

const _EPSILON := 0.000001


static func run(config: GameConfig, derived: DerivedState, dt: float, events: EventsState = null, risks: RisksState = null) -> void:
	var smoothing := 1.0 - exp(-dt / config.productivity_smoothing_seconds)
	var boosted := events != null and not events.events.is_empty()
	var fires: Dictionary[int, int] = risks.fires if risks != null else {}
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		entry.powered = false
		if entry.power_plants.is_empty():
			continue
		for plant: DerivedState.ProductionEntry in entry.power_plants:
			if plant.record.state == BuildingRecord.State.PRODUCING:
				entry.powered = true
				break
	# Fase 29: o que não muda dentro do tick (há especialista? há fogo?) fica fora do laço
	var any_fire := not fires.is_empty()
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		if entry.shipyard:
			continue
		var record := entry.record
		var previous := record.state
		var factor := EventEffects.production(events, record.island_id, entry.def) if boosted else 1.0
		if entry.powered:
			factor *= 1.0 + config.electricity_bonus
		if entry.specialist != null and entry.specialist.def.effect == SpecialistDef.Effect.SPEED:
			factor *= 1.0 + entry.specialist.def.amount
		var speed := 0.0
		if any_fire and fires.has(record.id):
			record.state = BuildingRecord.State.ON_FIRE
		else:
			speed = _step(entry, config, dt, factor)
		record.productivity += (speed - record.productivity) * smoothing
		if record.state != previous:
			EventBus.building_state_changed.emit(record.id)


## Avança o ciclo e devolve a velocidade efetiva deste tick (0..1).
static func _step(entry: DerivedState.ProductionEntry, config: GameConfig, dt: float, factor: float) -> float:
	var record := entry.record
	var def := entry.def
	if record.paused:
		record.state = BuildingRecord.State.PAUSED
		return 0.0
	if not entry.has_road:
		record.state = BuildingRecord.State.NO_ROAD
		return 0.0
	if not entry.modules_ok:
		record.state = BuildingRecord.State.NO_MODULES
		return 0.0
	if not entry.trees_ok:
		record.state = BuildingRecord.State.NO_TREES
		return 0.0
	if entry.warehouse_id == 0 and not config.instant_logistics:
		record.state = BuildingRecord.State.NO_WAREHOUSE
		return 0.0
	if not record.in_cycle and not _start_cycle(record, def, config):
		return 0.0
	var speed := entry.economy.workforce(entry.workforce_tier) * factor
	if speed <= 0.0:
		record.state = BuildingRecord.State.NO_WORKERS
		return 0.0
	record.state = BuildingRecord.State.PRODUCING
	record.progress += dt * speed / def.cycle_s
	if record.progress >= 1.0 - _EPSILON:
		if def.output != &"":
			record.output_buffer += 1.0
			_extra_output(entry, config)
		record.in_cycle = false
		var leftover := maxf(record.progress - 1.0, 0.0)
		record.progress = 0.0
		if _start_cycle(record, def, config):
			record.progress = leftover
			record.state = BuildingRecord.State.PRODUCING
	return speed


## Começa um ciclo se há 1 t de cada entrada e lugar na saída; senão marca o motivo.
static func _start_cycle(record: BuildingRecord, def: BuildingDef, config: GameConfig) -> bool:
	if record.output_buffer + 1.0 > config.building_buffer_t + 0.000001:
		record.state = BuildingRecord.State.OUTPUT_FULL
		return false
	for input: StringName in def.inputs:
		if record.input_buffer.get(input, 0.0) < 1.0 - 0.000001:
			record.state = BuildingRecord.State.NO_INPUT
			return false
	for input: StringName in def.inputs:
		record.input_buffer[input] = record.input_buffer[input] - 1.0
	record.in_cycle = true
	return true


## Especialista de tonelada extra: a cada cycles_per_extra ciclos, mais 1 t na saída, se couber.
static func _extra_output(entry: DerivedState.ProductionEntry, config: GameConfig) -> void:
	var specialist := entry.specialist
	if specialist == null or specialist.def.effect != SpecialistDef.Effect.EXTRA_OUTPUT:
		return
	specialist.cycles += 1
	if specialist.cycles < specialist.def.cycles_per_extra():
		return
	specialist.cycles = 0
	entry.record.output_buffer = minf(entry.record.output_buffer + 1.0, float(config.building_buffer_t))
