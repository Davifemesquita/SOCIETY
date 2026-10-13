class_name ShipDef
extends Resource
## Definição de um tipo de navio (seção 6): porão, velocidade, manutenção e custo.

@export var id: StringName
## Chave de tradução do nome.
@export var name_key: String
## Compartimentos do porão; cada um leva um bem só.
@export var cargo_slots: int = 4
@export var slot_capacity_t: int = 50
## Velocidade no mar, em metros por segundo de jogo.
@export var speed_m_s: float = 6.0
## Manutenção em moedas por minuto enquanto o navio existe.
@export var upkeep_per_min: int = 40
@export var cost_money: int = 0
@export var cost_materials: Dictionary[StringName, int] = {}

@export_group("Placeholder")
@export var hull_color: Color = Color(0.36, 0.24, 0.16)
@export var sail_color: Color = Color(0.92, 0.9, 0.82)
@export var length_m: float = 16.0


func capacity_t() -> int:
	return cargo_slots * slot_capacity_t
