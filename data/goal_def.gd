class_name GoalDef
extends Resource
## Meta guiada (seção 3): objetivo curto que ensina o jogo, cumprido na ordem da lista. O título é
## GOAL_<ID> (com %s para a quantidade) e o conselheiro fala os blocos <id> (ao começar) e
## <id>_done (ao cumprir) de ui/advisor/advisor.dialogue.

enum Kind {
	## Quantos prédios do tipo target existem (em todas as ilhas).
	BUILDING_COUNT,
	## Moradores da classe target.
	TIER_POPULATION,
	## Moradores da classe target que têm a categoria need atendida (o atendimento da ilha).
	NEED_SUPPLIED,
	## Moradores somando todas as classes.
	TOTAL_POPULATION,
	## Células de estrada de paralelepípedo.
	PAVED_CELLS,
	## Ilhas com entreposto.
	COLONIZED_ISLANDS,
}

@export var id: StringName
@export var kind: Kind = Kind.BUILDING_COUNT
@export var target: StringName
@export var need: StringName
@export var amount: int = 1
@export var reward_money: int = 0
## A meta só começa a contar depois de tantos marcos de população (as ligadas aos marcos).
@export var after_milestone: int = 0


func title_key() -> String:
	return "GOAL_" + String(id).to_upper()
