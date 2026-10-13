class_name TraderDef
extends Resource
## Comerciante neutro (seção 6): compra e vende uma lista de bens ao preço base com variação
## sorteada a cada volta. O navio dele visita os entrepostos (comércio passivo) e o posto dele,
## no mar aberto, recebe os navios do jogador (comércio ativo).

@export var id: StringName
@export var name_key: String
## Bens que ele vende ao jogador.
@export var sells: Array[StringName] = []
## Bens que ele compra do jogador.
@export var buys: Array[StringName] = []
## Navio que ele usa nas visitas.
@export var ship: StringName = &"trader_ship"
## Espera no posto entre uma volta pelos entrepostos e a próxima, em segundos de jogo.
@export var visit_interval_s: float = 300.0
## Quanto ele fica em cada entreposto antes de seguir viagem.
@export var dwell_s: float = 20.0
## Teto de toneladas por bem negociadas numa visita (comércio passivo).
@export var max_tons_per_visit: int = 20
