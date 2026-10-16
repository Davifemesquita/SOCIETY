class_name AchievementDef
extends Resource
## Conquista (Fase 12): marca do jogador, fora do save da partida (vale para todas). O título é
## ACHIEVEMENT_<ID> e a descrição ACHIEVEMENT_<ID>_DESC (com %s para a quantidade).

enum Kind {
	## Moradores da classe target em todas as ilhas, pelo menos amount.
	TIER_POPULATION,
	## Moedas no caixa, pelo menos amount.
	MONEY,
	## Ilhas com entreposto, pelo menos amount.
	COLONIZED_ISLANDS,
	## Navios entregues pelo estaleiro na partida.
	SHIPS_BUILT,
	## Incêndios apagados pelos bombeiros (contados na hora do aviso).
	FIRES_PUT_OUT,
	## Navios de rival afundados.
	ENEMY_SUNK,
	## Partidas vencidas (com objetivo); com target, só o cenário de id target.
	VICTORY,
}

@export var id: StringName
@export var kind: Kind = Kind.TIER_POPULATION
@export var target: StringName
@export var amount: int = 1
## Ícone do atlas (ui/icons) mostrado na lista.
@export var icon: String = "notice_milestone"


func title_key() -> String:
	return "ACHIEVEMENT_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"
