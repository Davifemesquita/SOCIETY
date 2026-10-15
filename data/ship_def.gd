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

@export_group("Combate")
## Casco (Fase 11): o navio afunda quando chega a zero. Canhões > 0 fazem dele um navio de guerra,
## que atira salvo_damage a cada reload_s no inimigo mais perto até cannon_range_m.
@export var hull_points: float = 120.0
@export var cannons: int = 0
@export var salvo_damage: float = 0.0
@export var cannon_range_m: float = 0.0
@export var reload_s: float = 5.0
## Marcos de população que liberam a compra (0 = desde o começo).
@export var unlock_milestone: int = 0

@export_group("Placeholder")
@export var hull_color: Color = Color(0.36, 0.24, 0.16)
@export var sail_color: Color = Color(0.92, 0.9, 0.82)
@export var length_m: float = 16.0


func capacity_t() -> int:
	return cargo_slots * slot_capacity_t
