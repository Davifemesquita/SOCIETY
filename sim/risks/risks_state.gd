class_name RisksState
extends RefCounted
## Incêndio e doença (seção 8, opcionais), no save. Desligado (enabled = false) nada pega fogo nem
## adoece: é o padrão de mundo novo da simulação (testes, ferramentas, o jogador-robô) e uma opção
## do jogo novo. Os sorteios saem da semente e do tick, então a partida carregada segue igual.

var enabled: bool = false
## Prédio em chamas → tick em que o fogo começou.
var fires: Dictionary[int, int] = {}
## Casa doente → tick em que a doença começou.
var outbreaks: Dictionary[int, int] = {}
## Prédios perdidos no fogo e surtos curados (estatística e testes).
var buildings_lost: int = 0
var outbreaks_cured: int = 0


func is_burning(building_id: int) -> bool:
	return fires.has(building_id)


func is_sick(building_id: int) -> bool:
	return outbreaks.has(building_id)


## O prédio saiu do mundo (demolido ou perdido): esquece o fogo e a doença dele.
func forget(building_id: int) -> void:
	fires.erase(building_id)
	outbreaks.erase(building_id)


func to_dict() -> Dictionary:
	return {"enabled": enabled, "fires": _pairs(fires), "outbreaks": _pairs(outbreaks), "buildings_lost": buildings_lost,
			"outbreaks_cured": outbreaks_cured}


## Lê o estado de um save; null se algo vier com tipo errado, repetido ou num prédio que não pode
## ter aquele risco (fogo só em casa e produção, doença só em casa).
static func from_dict(data: Dictionary, world: WorldState, game_data: GameData) -> RisksState:
	var raw_enabled: Variant = data.get("enabled")
	var raw_fires: Variant = data.get("fires")
	var raw_outbreaks: Variant = data.get("outbreaks")
	var raw_lost: Variant = data.get("buildings_lost")
	var raw_cured: Variant = data.get("outbreaks_cured")
	if not (raw_enabled is bool and raw_fires is Array and raw_outbreaks is Array and raw_lost is int and raw_cured is int):
		return null
	var state := RisksState.new()
	state.enabled = raw_enabled
	state.buildings_lost = raw_lost
	state.outbreaks_cured = raw_cured
	if state.buildings_lost < 0 or state.outbreaks_cured < 0:
		return null
	var fire_list: Array = raw_fires
	var outbreak_list: Array = raw_outbreaks
	if not (_read_pairs(fire_list, state.fires, world.tick) and _read_pairs(outbreak_list, state.outbreaks, world.tick)):
		return null
	for building_id: int in state.fires:
		var record := world.building(building_id)
		if record == null or not game_data.building(record.def_id).can_burn():
			return null
	for building_id: int in state.outbreaks:
		var record := world.building(building_id)
		if record == null or not record.is_house():
			return null
	return state


static func _pairs(map: Dictionary[int, int]) -> Array[Dictionary]:
	var ids: Array[int] = []
	ids.assign(map.keys())
	ids.sort()
	var list: Array[Dictionary] = []
	for building_id: int in ids:
		list.append({"building": building_id, "started": map[building_id]})
	return list


static func _read_pairs(list: Array, into: Dictionary[int, int], tick: int) -> bool:
	for raw: Variant in list:
		if not raw is Dictionary:
			return false
		var pair: Dictionary = raw
		var raw_building: Variant = pair.get("building")
		var raw_started: Variant = pair.get("started")
		if not (raw_building is int and raw_started is int):
			return false
		var building_id: int = raw_building
		var started: int = raw_started
		if into.has(building_id) or started < 0 or started > tick:
			return false
		into[building_id] = started
	return true
