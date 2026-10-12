class_name BuildingLevelDef
extends Resource
## Um nível de prédio que melhora (entreposto, armazém). O nível 0 é o prédio construído;
## o custo de cada nível seguinte é o do upgrade até ele.

@export var cost_money: int = 0
@export var cost_materials: Dictionary[StringName, int] = {}
## Rampas de carga: carroças atendidas ao mesmo tempo.
@export var ramps: int = 2
## Estoque por bem da ilha que o entreposto dá neste nível (0 = não muda o estoque).
@export var storage_capacity_t: int = 0
