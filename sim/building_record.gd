class_name BuildingRecord
extends RefCounted
## Um prédio no mundo. Não é nó: só o registro que a simulação guarda.

var id: int
var def_id: StringName
var island_id: int
var origin: Vector2i
var rotation: int


func _init(building_id: int, def: StringName, island: int, at: Vector2i, rot: int) -> void:
	id = building_id
	def_id = def
	island_id = island
	origin = at
	rotation = rot


func to_dict() -> Dictionary:
	return {"id": id, "def": def_id, "island": island_id, "origin": origin, "rotation": rotation}


## Lê um registro de save; devolve null se algum campo vier com tipo errado.
static func from_dict(data: Dictionary) -> BuildingRecord:
	var raw_id: Variant = data.get("id")
	var raw_def: Variant = data.get("def")
	var raw_island: Variant = data.get("island")
	var raw_origin: Variant = data.get("origin")
	var raw_rotation: Variant = data.get("rotation")
	if not (raw_id is int and raw_def is StringName and raw_island is int and raw_origin is Vector2i and raw_rotation is int):
		return null
	var building_id: int = raw_id
	var def: StringName = raw_def
	var island: int = raw_island
	var at: Vector2i = raw_origin
	var rot: int = raw_rotation
	if rot < 0 or rot > 3:
		return null
	return BuildingRecord.new(building_id, def, island, at, rot)
