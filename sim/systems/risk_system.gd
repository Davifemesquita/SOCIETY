class_name RiskSystem
extends RefCounted
## Incêndio e doença (seção 8, opcionais). A cada risk_check_ticks, com os riscos ligados:
## - resolve os que venceram: fogo protegido por bombeiros se apaga em fire_extinguish_s; o
##   desprotegido queima fire_burnout_s e o prédio se perde. Doença sara em disease_cure_s com
##   hospital, em disease_duration_s sem. A proteção vale a de agora: quartel erguido durante o
##   fogo ainda salva o prédio;
## - sorteia fogo novo em casa e produção (depois de fire_after_milestone marcos) e doença nova em
##   casa (depois de disease_after_milestone), até o teto de cada um. A chance é por hora de jogo,
##   convertida para a conferência; quartel e hospital a cortam pelo fator de proteção.
## Tudo pela semente e pelo tick: a partida carregada segue igual. O prédio perdido sai do mundo
## pela Simulation (devolvido em lost), que avisa as vistas.


## Roda a conferência e devolve os prédios perdidos no fogo.
static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState) -> Array[int]:
	var lost: Array[int] = []
	var state := world.risks_state
	if not state.enabled or world.tick % config.risk_check_ticks != 0:
		return lost
	_resolve_fires(world, config, derived, lost)
	_resolve_outbreaks(world, config, derived)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.seed, &"risk", world.tick])
	var hours := float(config.risk_check_ticks) / config.ticks_per_second / 3600.0
	if world.milestones_reached >= config.fire_after_milestone:
		_ignite(world, data, config, derived, rng, hours, lost)
	if world.milestones_reached >= config.disease_after_milestone:
		_infect(world, config, derived, rng, hours, lost)
	return lost


static func _resolve_fires(world: WorldState, config: GameConfig, derived: DerivedState, lost: Array[int]) -> void:
	var state := world.risks_state
	for building_id: int in _sorted(state.fires):
		var burning_ticks := world.tick - state.fires[building_id]
		if derived.fire_protected.has(building_id):
			if burning_ticks >= config.ticks_of(config.fire_extinguish_s):
				state.fires.erase(building_id)
				EventBus.fire_ended.emit(building_id, false)
		elif burning_ticks >= config.ticks_of(config.fire_burnout_s):
			state.forget(building_id)
			state.buildings_lost += 1
			lost.append(building_id)


static func _resolve_outbreaks(world: WorldState, config: GameConfig, derived: DerivedState) -> void:
	var state := world.risks_state
	for house_id: int in _sorted(state.outbreaks):
		var limit := config.disease_cure_s if derived.health_protected.has(house_id) else config.disease_duration_s
		if world.tick - state.outbreaks[house_id] >= config.ticks_of(limit):
			state.outbreaks.erase(house_id)
			state.outbreaks_cured += 1
			EventBus.outbreak_ended.emit(house_id)


## O sorteio anda pela lista do estado derivado, que ainda tem os prédios perdidos nesta conferência
## (saem do mundo depois): esses ficam de fora.
static func _ignite(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState, rng: RandomNumberGenerator, hours: float,
		lost: Array[int]) -> void:
	var state := world.risks_state
	for building_id: int in derived.houses + derived.production:
		if state.fires.size() >= config.max_active_fires:
			return
		if lost.has(building_id):
			continue
		var def := data.building(world.building(building_id).def_id)
		var chance := config.fire_chance_per_hour * def.fire_risk * hours
		if derived.fire_protected.has(building_id):
			chance *= config.fire_protected_factor
		# Fase 66: a vigia de incêndio da prefeitura em volta
		chance *= derived.policy_fire.get(building_id, 1.0)
		if rng.randf() < chance and not state.fires.has(building_id):
			ignite(world, building_id)


static func _infect(world: WorldState, config: GameConfig, derived: DerivedState, rng: RandomNumberGenerator, hours: float,
		lost: Array[int]) -> void:
	var state := world.risks_state
	for house_id: int in derived.houses:
		if state.outbreaks.size() >= config.max_active_outbreaks:
			return
		if lost.has(house_id):
			continue
		var pollution: float = derived.pollution.get(house_id, 0.0)
		var chance := config.disease_chance_per_hour * (1.0 + config.disease_pollution_factor * pollution) * hours
		if derived.health_protected.has(house_id):
			chance *= config.disease_protected_factor
		if rng.randf() < chance and not state.outbreaks.has(house_id) and world.building(house_id).residents >= 1.0:
			infect(world, house_id)


## Põe fogo no prédio agora (o sorteio e os testes).
static func ignite(world: WorldState, building_id: int) -> void:
	world.risks_state.fires[building_id] = world.tick
	EventBus.fire_started.emit(building_id)


## Adoece a casa agora (o sorteio e os testes).
static func infect(world: WorldState, house_id: int) -> void:
	world.risks_state.outbreaks[house_id] = world.tick
	EventBus.outbreak_started.emit(house_id)


static func _sorted(map: Dictionary[int, int]) -> Array[int]:
	var ids: Array[int] = []
	ids.assign(map.keys())
	ids.sort()
	return ids
