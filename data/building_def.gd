class_name BuildingDef
extends Resource
## Definição de um tipo de prédio. Na Fase 1 só forma e cor; produção, custo e
## trabalhadores entram na Fase 2.

@export var id: StringName
## Chave de tradução do nome.
@export var name_key: String
## Largura (x) e profundidade (y) em células, com a frente voltada para −Z sem rotação.
@export var size: Vector2i = Vector2i(3, 3)
@export var height_m: float = 4.0
## Cor do placeholder enquanto não há modelo.
@export var color: Color = Color(0.6, 0.6, 0.6)
