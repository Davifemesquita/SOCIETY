class_name PlanRecord
extends RefCounted
## Uma planta (Fase 49): um prédio desenhado no mapa, sem custo, que ainda não existe. Não ocupa a célula para as regras
## da simulação (um prédio de verdade pode ser feito por cima; a planta então não consegue mais ser construída e fica
## até o jogador apagá-la). Vai para o save.

var id: int
var def_id: StringName
var island_id: int
var origin: Vector2i
var rotation: int


func _init(plan_id: int, def: StringName, island: int, at: Vector2i, rot: int) -> void:
	id = plan_id
	def_id = def
	island_id = island
	origin = at
	rotation = rot


func rect(data: GameData) -> Rect2i:
	return Footprint.rect(origin, data.building(def_id).size, rotation)


func to_dict() -> Dictionary:
	return {"id": id, "def": def_id, "island": island_id, "origin": origin, "rotation": rotation}


## Lê uma planta do save; null se algum campo vier com tipo errado ou o prédio não existir mais.
static func from_dict(data: Dictionary, game_data: GameData, island_count: int) -> PlanRecord:
	var raw_id: Variant = data.get("id")
	var raw_def: Variant = data.get("def")
	var raw_island: Variant = data.get("island")
	var raw_origin: Variant = data.get("origin")
	var raw_rotation: Variant = data.get("rotation")
	if not (raw_id is int and raw_def is StringName and raw_island is int and raw_origin is Vector2i and raw_rotation is int):
		return null
	var def_id: StringName = raw_def
	var island: int = raw_island
	var rot: int = raw_rotation
	if game_data.building(def_id) == null or island < 0 or island >= island_count or rot < 0 or rot > 3:
		return null
	var plan_id: int = raw_id
	var at: Vector2i = raw_origin
	return PlanRecord.new(plan_id, def_id, island, at, rot)
