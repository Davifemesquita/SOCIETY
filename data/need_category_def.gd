class_name NeedCategoryDef
extends Resource
## Categoria de necessidade de uma classe. Uma opção atendida já cobre a categoria;
## duas ou mais dão bônus de imposto e dividem o consumo entre si.

@export var id: StringName
@export var name_key: String
## Bens que atendem a categoria (consumidos do estoque da ilha).
@export var goods: Array[StringName] = []
## Prédios de serviço que atendem a categoria (casa dentro do raio, por estrada).
@export var services: Array[StringName] = []


func option_count() -> int:
	return goods.size() + services.size()
