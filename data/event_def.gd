class_name EventDef
extends Resource
## Evento da partida (Fase 11): acontece sozinho de tempos em tempos, sorteado pela semente, e vale
## por duration_s de jogo. Só mexe em multiplicadores lidos pelos sistemas (EventEffects): nada é
## destruído nem tirado do jogador. Título EVENT_<ID>, descrição EVENT_<ID>_DESC.

enum Effect {
	## Velocidade de produção dos prédios do grupo target_group (numa ilha).
	PRODUCTION,
	## Preço do comerciante para um bem sorteado entre os que ele compra (o arquipélago todo).
	TRADER_PRICE,
	## Velocidade de todos os navios (o arquipélago todo).
	SHIP_SPEED,
	## Felicidade somada ao alvo das casas (numa ilha); amount é em pontos, não multiplicador.
	HAPPINESS,
	## Ritmo de chegada de moradores (numa ilha).
	ARRIVAL,
}

## Grupos de prédios de produção para Effect.PRODUCTION.
enum Group {
	## Todos os prédios de produção.
	ALL,
	## Os que plantam ou criam (fertilidade ou módulos de campo/pasto).
	FARMS,
	## As minas (jazida debaixo do prédio).
	MINES,
}

@export var id: StringName
@export var effect: Effect = Effect.PRODUCTION
@export var target_group: Group = Group.ALL
## Multiplicador (PRODUCTION, TRADER_PRICE, SHIP_SPEED, ARRIVAL) ou pontos de felicidade (HAPPINESS).
@export var amount: float = 1.0
@export var duration_s: float = 480.0
## Peso no sorteio entre os eventos liberados.
@export var weight: int = 1
## Só entra no sorteio depois de tantos marcos de população.
@export var after_milestone: int = 0


func title_key() -> String:
	return "EVENT_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"


## Vale para uma ilha só (sorteada entre as colonizadas) ou para o arquipélago inteiro.
func is_local() -> bool:
	return effect in [Effect.PRODUCTION, Effect.HAPPINESS, Effect.ARRIVAL]


## Efeito bom para o jogador (a notificação sai em verde; a tempestade, em laranja).
func is_good() -> bool:
	return amount >= 1.0 if effect != Effect.HAPPINESS else amount >= 0.0


## O prédio entra no grupo deste evento?
func covers(def: BuildingDef) -> bool:
	match target_group:
		Group.FARMS:
			return def.fertility != &"" or def.modules_required > 0
		Group.MINES:
			return def.deposit != &""
	return true
