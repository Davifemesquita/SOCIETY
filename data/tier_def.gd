class_name TierDef
extends Resource
## Classe de moradores: capacidade da casa, imposto, materiais para subir até ela e
## necessidades básicas (exigidas) e de luxo (opcionais).

@export var id: StringName
@export var name_key: String
@export var residents_per_house: int = 10
## Imposto por morador, em moedas por minuto, antes da felicidade e do nível de imposto.
@export var tax_per_resident_min: float = 0.6
## Materiais retirados do estoque quando uma casa sobe para esta classe.
@export var upgrade_materials: Dictionary[StringName, int] = {}
@export var basic_needs: Array[NeedCategoryDef] = []
@export var luxury_needs: Array[NeedCategoryDef] = []
## Cor e altura da casa enquanto não há modelo.
@export var house_color: Color = Color(0.7, 0.6, 0.45)
@export var house_height_m: float = 4.0
