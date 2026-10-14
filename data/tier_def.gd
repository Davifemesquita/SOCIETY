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
## Texturas da casa (Fase 9): paredes (BuildingMaterials.Wall) e telhado (BuildingMaterials.Roof).
@export var wall_material: int = 0
@export var roof_material: int = 0
## Roupa dos pedestres desta classe (seção 9): cada um sorteia a cor de cima desta lista; a calça
## (ou saia) é a mesma para a classe.
@export var clothing_colors: PackedColorArray = PackedColorArray([Color(0.45, 0.4, 0.35)])
@export var trousers_color: Color = Color(0.25, 0.22, 0.2)

var _all_needs: Array[NeedCategoryDef] = []


## Básicas e depois as de luxo, numa lista feita uma vez (as necessidades rodam a cada tick).
func all_needs() -> Array[NeedCategoryDef]:
	if _all_needs.size() != basic_needs.size() + luxury_needs.size():
		_all_needs = basic_needs + luxury_needs
	return _all_needs
