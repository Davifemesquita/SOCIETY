class_name RivalDef
extends Resource
## Companhia rival com IA (Fase 11): coloniza ilhas livres de tempos em tempos, faz a vila crescer,
## manda o navio dela ao comerciante e tem uma relação com o jogador (-100 a 100) que a diplomacia
## move. A personalidade diz para onde a relação volta sozinha e quando ela declara guerra ou
## aceita acordo. Nome RIVAL_<ID>.

enum Personality {
	## Volta para a amizade; nunca declara guerra.
	PEACEFUL,
	## Neutra; não gosta que o jogador se espalhe.
	AMBITIOUS,
	## Volta para a desconfiança; declara guerra quando a relação cai demais.
	AGGRESSIVE,
}

@export var id: StringName
@export var name_key: String
@export var personality: Personality = Personality.AMBITIOUS
## Cor das velas e dos telhados da vila dela.
@export var color: Color = Color(0.3, 0.4, 0.7)
## Navio mercante que ela usa (o mesmo tipo do jogador, com as velas dela).
@export var ship: StringName = &"merchant_ship"
## A primeira colônia sai depois de tanto tempo de jogo; as seguintes, a cada colony_interval_s.
@export var first_colony_s: float = 1200.0
@export var colony_interval_s: float = 2400.0
@export var max_islands: int = 2
## Moradores que chegam por minuto numa ilha dela (o crescimento desacelera perto do teto).
@export var growth_per_min: float = 6.0


func title_key() -> String:
	return name_key


## Relação para onde ela volta sozinha com o tempo.
func base_relation(config: GameConfig) -> float:
	return config.rival_base_relation[personality]
