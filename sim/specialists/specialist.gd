class_name Specialist
extends RefCounted
## Um especialista contratado (Fase 11): o prédio onde trabalha (0 = sem posto) e, no efeito de
## tonelada extra, os ciclos contados desde a última.

var id: int = 0
var def_id: StringName
var building_id: int = 0
var cycles: int = 0
## runtime: a definição (resolvida ao contratar e ao carregar), fora do save.
var def: SpecialistDef


func to_dict() -> Dictionary:
	return {"id": id, "def": def_id, "building": building_id, "cycles": cycles}


static func from_dict(data: Dictionary, game_data: GameData) -> Specialist:
	var raw_id: Variant = data.get("id")
	var raw_def: Variant = data.get("def")
	var raw_building: Variant = data.get("building")
	var raw_cycles: Variant = data.get("cycles")
	if not (raw_id is int and raw_def is StringName and raw_building is int and raw_cycles is int):
		return null
	var item := Specialist.new()
	item.id = raw_id
	item.def_id = raw_def
	item.building_id = raw_building
	item.cycles = raw_cycles
	item.def = game_data.specialist(item.def_id)
	if item.def == null or item.id <= 0 or item.building_id < 0 or item.cycles < 0:
		return null
	return item
