class_name RivalsState
extends RefCounted
## As companhias rivais da partida (Fase 11), no save. Desligado (enabled = false) não há rivais: é o
## padrão de mundo novo da simulação e uma opção do jogo novo. Ligado, a lista tem uma entrada por
## RivalDef de GameData.rivals, na mesma ordem.

var enabled: bool = false
var rivals: Array[RivalState] = []


## Rival dona da ilha, ou null.
func owner_of(island_id: int) -> RivalState:
	for rival: RivalState in rivals:
		if rival.islands.has(island_id):
			return rival
	return null


func by_id(def_id: StringName) -> RivalState:
	for rival: RivalState in rivals:
		if rival.def_id == def_id:
			return rival
	return null


## Rival pelo navio dela (o mercante ou uma fragata), ou null.
func by_ship(ship_id: int) -> RivalState:
	if ship_id == 0:
		return null
	for rival: RivalState in rivals:
		if rival.ship_id == ship_id or rival.warships.has(ship_id):
			return rival
	return null


## Ilhas tomadas por rivais, somadas.
func claimed_count() -> int:
	var count := 0
	for rival: RivalState in rivals:
		count += rival.islands.size()
	return count


func at_war() -> bool:
	for rival: RivalState in rivals:
		if rival.stance == RivalState.Stance.WAR:
			return true
	return false


## Liga e cria uma entrada por definição (jogo novo com rivais).
func start(data: GameData, config: GameConfig) -> void:
	enabled = true
	rivals.clear()
	for def: RivalDef in data.rivals:
		var rival := RivalState.new()
		rival.def = def
		rival.def_id = def.id
		rival.relation = def.base_relation(config)
		rivals.append(rival)


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for rival: RivalState in rivals:
		list.append(rival.to_dict())
	return {"enabled": enabled, "rivals": list}


static func from_dict(data: Dictionary, game_data: GameData, island_count: int) -> RivalsState:
	var raw_enabled: Variant = data.get("enabled")
	var raw_rivals: Variant = data.get("rivals")
	if not (raw_enabled is bool and raw_rivals is Array):
		return null
	var state := RivalsState.new()
	state.enabled = raw_enabled
	var list: Array = raw_rivals
	for raw: Variant in list:
		if not raw is Dictionary:
			return null
		var rival_data: Dictionary = raw
		var rival := RivalState.from_dict(rival_data, game_data, island_count)
		if rival == null or state.by_id(rival.def_id) != null:
			return null
		for island_id: int in rival.islands:
			if state.owner_of(island_id) != null:
				return null
		state.rivals.append(rival)
	return state
