class_name MissionDef
extends Resource
## Encomenda (Fase 11): o comerciante pede tons de um bem para entregar no posto dele em
## duration_s de jogo. Cada tonelada entregue é paga ao preço da volta, mesmo que ele não compre o
## bem; cumprida no prazo, paga ainda o prêmio (bonus_fraction do valor base da encomenda). Perder
## o prazo não custa nada. Na tela, o pedido é "<toneladas> t de <bem>".

@export var id: StringName
@export var good: StringName
@export var tons: int = 30
@export var duration_s: float = 1200.0
@export var bonus_fraction: float = 0.5
@export var weight: int = 1
## Só é oferecida depois de tantos marcos de população.
@export var after_milestone: int = 0


## Prêmio de quem cumpre no prazo, em moedas.
func bonus(data: GameData) -> int:
	var def := data.good(good)
	var price: float = float(def.base_price) if def != null else 0.0
	return roundi(tons * price * bonus_fraction)
