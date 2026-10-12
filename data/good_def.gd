class_name GoodDef
extends Resource
## Um bem: o que se produz, se guarda no estoque da ilha e se consome.

@export var id: StringName
@export var name_key: String
## Preço base por tonelada; o comerciante (Fase 6) varia em torno dele.
@export var base_price: int = 10
## Consumo de cada morador que tem este bem como opção de necessidade, em t/min.
@export var consumption_per_resident_t_min: float = 0.0
## Cor do placeholder enquanto não há ícone.
@export var color: Color = Color(0.6, 0.6, 0.6)
