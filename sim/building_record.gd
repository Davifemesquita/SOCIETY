class_name BuildingRecord
extends RefCounted
## Um prédio no mundo. Não é nó: só o registro que a simulação guarda.
## Os campos de produção valem para prédios de produção; os de casa, para residências.

## NO_TREES (Fase 5) e ON_FIRE (riscos) entram no fim: o número de cada estado vai no save.
enum State { IDLE, PRODUCING, NO_INPUT, NO_WORKERS, OUTPUT_FULL, NO_ROAD, NO_MODULES, PAUSED, NO_WAREHOUSE, NO_TREES, ON_FIRE }

var id: int
var def_id: StringName
var island_id: int
var origin: Vector2i
var rotation: int
var paused: bool = false
## Nível do armazém ou entreposto (0 = como construído).
var level: int = 0
## Prefeitura (Fase 66): a política escolhida (vazia = nenhuma). Só vai no save quando há.
var policy: StringName = &""

# produção
var in_cycle: bool = false
## Fração do ciclo atual já feita, 0..1.
var progress: float = 0.0
var input_buffer: Dictionary[StringName, float] = {}
var output_buffer: float = 0.0
## Produtividade média mostrada no painel (0..1).
var productivity: float = 0.0

# casa
var tier: StringName
var residents: float = 0.0
var happiness: float = 0.0
var upgrade_blocked: bool = false

## Imposto da casa na última avaliação, em moedas por minuto (salvo: a economia soma os
## valores de todas as casas a cada tick, e a soma tem de voltar igual depois de carregar).
var tax_per_min: float = 0.0

# runtime: recalculado a cada tick, fora do save
var state: State = State.IDLE


func _init(building_id: int, def: StringName, island: int, at: Vector2i, rot: int) -> void:
	id = building_id
	def_id = def
	island_id = island
	origin = at
	rotation = rot


func is_house() -> bool:
	return tier != &""


func to_dict() -> Dictionary:
	var data := {"id": id, "def": def_id, "island": island_id, "origin": origin, "rotation": rotation, "paused": paused,
			"level": level}
	if policy != &"":
		data["policy"] = policy
	if is_house():
		data["house"] = {"tier": tier, "residents": residents, "happiness": happiness, "upgrade_blocked": upgrade_blocked,
				"tax_per_min": tax_per_min}
	else:
		data["production"] = {"in_cycle": in_cycle, "progress": progress, "input_buffer": input_buffer.duplicate(),
				"output_buffer": output_buffer, "productivity": productivity}
	return data


## Lê um registro de save; devolve null se algum campo vier com tipo errado.
static func from_dict(data: Dictionary) -> BuildingRecord:
	var raw_id: Variant = data.get("id")
	var raw_def: Variant = data.get("def")
	var raw_island: Variant = data.get("island")
	var raw_origin: Variant = data.get("origin")
	var raw_rotation: Variant = data.get("rotation")
	var raw_paused: Variant = data.get("paused")
	var raw_level: Variant = data.get("level")
	if not (raw_id is int and raw_def is StringName and raw_island is int and raw_origin is Vector2i \
			and raw_rotation is int and raw_paused is bool and raw_level is int):
		return null
	var building_id: int = raw_id
	var def: StringName = raw_def
	var island: int = raw_island
	var at: Vector2i = raw_origin
	var rot: int = raw_rotation
	if rot < 0 or rot > 3:
		return null
	var record := BuildingRecord.new(building_id, def, island, at, rot)
	record.paused = raw_paused
	record.level = raw_level
	var raw_policy: Variant = data.get("policy", &"")
	if not raw_policy is StringName:
		return null
	record.policy = raw_policy
	var raw_house: Variant = data.get("house")
	var raw_production: Variant = data.get("production")
	if raw_house is Dictionary:
		var house: Dictionary = raw_house
		return record if record._read_house(house) else null
	if raw_production is Dictionary:
		var production: Dictionary = raw_production
		return record if record._read_production(production) else null
	return null


func _read_house(house: Dictionary) -> bool:
	var raw_tier: Variant = house.get("tier")
	var raw_residents: Variant = house.get("residents")
	var raw_happiness: Variant = house.get("happiness")
	var raw_blocked: Variant = house.get("upgrade_blocked")
	var raw_tax: Variant = house.get("tax_per_min")
	if not (raw_tier is StringName and raw_residents is float and raw_happiness is float and raw_blocked is bool and raw_tax is float):
		return false
	tax_per_min = raw_tax
	tier = raw_tier
	residents = raw_residents
	happiness = raw_happiness
	upgrade_blocked = raw_blocked
	return tier != &"" and residents >= 0.0


func _read_production(production: Dictionary) -> bool:
	var raw_in_cycle: Variant = production.get("in_cycle")
	var raw_progress: Variant = production.get("progress")
	var raw_inputs: Variant = production.get("input_buffer")
	var raw_output: Variant = production.get("output_buffer")
	var raw_productivity: Variant = production.get("productivity")
	if not (raw_in_cycle is bool and raw_progress is float and raw_inputs is Dictionary \
			and raw_output is float and raw_productivity is float):
		return false
	in_cycle = raw_in_cycle
	progress = raw_progress
	output_buffer = raw_output
	productivity = raw_productivity
	var inputs: Dictionary = raw_inputs
	for good: Variant in inputs:
		var tons: Variant = inputs[good]
		if not (good is StringName and tons is float):
			return false
		input_buffer[good] = tons
	return true
