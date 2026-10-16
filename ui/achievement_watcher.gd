class_name AchievementWatcher
extends RefCounted
## Confere as conquistas durante a partida (Fase 12): as de estado (população, dinheiro, ilhas,
## navios do estaleiro) a cada conferência, e as de acontecimento (fogo apagado, navio da rival
## afundado, vitória) pelo EventBus, somando nos contadores do jogador. Devolve as ganhas agora, para
## a interface avisar. Sem nós: testável.

## Partida de onde vem a conta (as de estado leem o mundo dela).
var _simulation: Simulation
var _store: Achievements
var _fresh: Array[AchievementDef] = []


func _init(simulation: Simulation, store: Achievements) -> void:
	_simulation = simulation
	_store = store


## Liga os acontecimentos que contam (chamada uma vez pela tela da partida).
func connect_events() -> void:
	EventBus.fire_ended.connect(func(_building_id: int, lost: bool) -> void:
		if not lost:
			on_event(AchievementDef.Kind.FIRES_PUT_OUT))
	EventBus.ship_sunk.connect(func(_ship_id: int, owner: int, _at: Vector2) -> void:
		if owner == Ship.Owner.RIVAL:
			on_event(AchievementDef.Kind.ENEMY_SUNK))
	EventBus.match_won.connect(func() -> void: on_event(AchievementDef.Kind.VICTORY))


## Um acontecimento: soma no contador e confere as conquistas daquele tipo.
func on_event(kind: AchievementDef.Kind) -> void:
	var key: String = AchievementDef.Kind.keys()[kind]
	var total := _store.add(key)
	for def: AchievementDef in _simulation.data.achievements:
		if def.kind != kind or _store.is_unlocked(def.id):
			continue
		if kind == AchievementDef.Kind.VICTORY and def.target != &"":
			if _simulation.world.victory_state.scenario_id == def.target:
				_grant(def)
		elif total >= def.amount:
			_grant(def)


## Confere as de estado e devolve todas as ganhas desde a última conferência.
func check() -> Array[AchievementDef]:
	var world := _simulation.world
	for def: AchievementDef in _simulation.data.achievements:
		if _store.is_unlocked(def.id):
			continue
		var value := -1
		match def.kind:
			AchievementDef.Kind.TIER_POPULATION:
				value = world.population(def.target)
			AchievementDef.Kind.MONEY:
				value = floori(world.money)
			AchievementDef.Kind.COLONIZED_ISLANDS:
				value = world.colonized_islands(_simulation.data).size()
			AchievementDef.Kind.SHIPS_BUILT:
				value = world.shipyard_state.ships_built
		if value >= def.amount:
			_grant(def)
	var result := _fresh.duplicate()
	_fresh.clear()
	return result


## Construir de graça (trapaça de desenvolvimento) não ganha conquista.
func _grant(def: AchievementDef) -> void:
	if _simulation.free_build:
		return
	if _store.unlock(def.id):
		_fresh.append(def)
