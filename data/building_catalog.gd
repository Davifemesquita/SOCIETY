class_name BuildingCatalog
extends Resource
## Todos os prédios do jogo, na ordem do menu de construção.

const DEFAULT_PATH := "res://data/building_catalog.tres"

static var _default: BuildingCatalog

@export var buildings: Array[BuildingDef] = []


static func get_default() -> BuildingCatalog:
	if _default == null:
		_default = load(DEFAULT_PATH) as BuildingCatalog
	return _default


func find(id: StringName) -> BuildingDef:
	for def: BuildingDef in buildings:
		if def.id == id:
			return def
	return null


## Lista definições inválidas. Vazia quando o catálogo está bom.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	for def: BuildingDef in buildings:
		if def == null:
			problems.append("catálogo com entrada vazia")
			continue
		if def.id == &"" or seen.has(def.id):
			problems.append("id de prédio vazio ou repetido: '%s'" % def.id)
		seen[def.id] = true
		if def.size.x <= 0 or def.size.y <= 0:
			problems.append("%s: tamanho deve ser positivo" % def.id)
		if def.name_key.is_empty():
			problems.append("%s: sem chave de nome" % def.id)
	return problems
