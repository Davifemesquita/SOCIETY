class_name ExpeditionDef
extends Resource
## Expedição (Fase 69): o jogador manda um navio parado da companhia para um destino distante por cost_money moedas;
## o navio some do mapa por duration_s e volta ao porto de onde saiu. Na volta, sorteado pela semente: naufraga
## (lost_chance: o navio se perde), volta de mãos vazias (empty_chance) ou traz a recompensa — uma peça de coleção do
## tipo do destino ainda não comprada (vai guardada, para o zoológico ou o museu) ou reward_money moedas. Título
## EXPEDITION_<ID>, texto EXPEDITION_<ID>_DESC.

enum Reward { ANIMAL, ARTIFACT, MONEY }

@export var id: StringName
@export var reward: Reward = Reward.MONEY
@export var reward_money: int = 0
@export var duration_s: float = 480.0
@export var cost_money: int = 3000
@export var empty_chance: float = 0.25
@export var lost_chance: float = 0.05
## Só se manda depois de tantos marcos de população.
@export var after_milestone: int = 0


func title_key() -> String:
	return "EXPEDITION_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"


## O tipo de peça que o destino traz (só ANIMAL e ARTIFACT).
func exhibit_kind() -> ExhibitDef.Kind:
	return ExhibitDef.Kind.ANIMAL if reward == Reward.ANIMAL else ExhibitDef.Kind.ARTIFACT
