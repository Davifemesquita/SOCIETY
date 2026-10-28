class_name ExhibitsState
extends RefCounted
## Peças de coleção da companhia (Fase 67), no save: cada peça comprada e o prédio em que ela está (0 = guardada, o
## prédio dela foi demolido). Peça que não está aqui ainda não foi comprada.

var placed: Dictionary[StringName, int] = {}


func owns(exhibit_id: StringName) -> bool:
	return placed.has(exhibit_id)


## As peças de um prédio, na ordem do catálogo (data.exhibits).
func in_building(building_id: int, data: GameData) -> Array[ExhibitDef]:
	var list: Array[ExhibitDef] = []
	for def: ExhibitDef in data.exhibits:
		if placed.get(def.id, -1) == building_id:
			list.append(def)
	return list


## O prédio saiu: as peças dele ficam guardadas. Verdadeiro se havia alguma.
func release(building_id: int) -> bool:
	var any := false
	for exhibit_id: StringName in placed:
		if placed[exhibit_id] == building_id:
			placed[exhibit_id] = 0
			any = true
	return any


func to_dict() -> Dictionary:
	return {"placed": placed.duplicate()}


static func from_dict(data: Dictionary, game_data: GameData) -> ExhibitsState:
	var raw_placed: Variant = data.get("placed")
	if not raw_placed is Dictionary:
		return null
	var state := ExhibitsState.new()
	var entries: Dictionary = raw_placed
	for key: Variant in entries:
		var value: Variant = entries[key]
		if not (key is StringName and value is int):
			return null
		var exhibit_id: StringName = key
		var building_id: int = value
		if building_id < 0 or game_data.exhibit(exhibit_id) == null:
			return null
		state.placed[exhibit_id] = building_id
	return state
