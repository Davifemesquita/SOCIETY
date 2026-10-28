class_name ExhibitDef
extends Resource
## Peça de coleção (Fase 67): um animal para o zoológico ou um objeto para o museu. Cada uma se compra uma vez, por
## price moedas, depois de after_milestone marcos, e vai numa vaga de um prédio do mesmo tipo; lá ela soma beauty à
## beleza do prédio (que embeleza as casas em volta). Prédio demolido guarda as peças dele, que voltam de graça para
## outro. Título EXHIBIT_<ID>, texto EXHIBIT_<ID>_DESC.

enum Kind { ANIMAL, ARTIFACT }

@export var id: StringName
@export var kind: Kind = Kind.ANIMAL
## Beleza somada à do prédio em que a peça está (a soma por casa, com as decorações, vai até 1).
@export var beauty: float = 0.08
@export var price: int = 2000
@export var after_milestone: int = 0


func title_key() -> String:
	return "EXHIBIT_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"
