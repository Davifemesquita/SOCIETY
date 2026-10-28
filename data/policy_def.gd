class_name PolicyDef
extends Resource
## Política da prefeitura (Fase 66): o jogador escolhe uma por prefeitura, e ela vale para os prédios em volta (até
## policy_radius_cells da prefeitura), enquanto a prefeitura tem estrada, custando upkeep_per_min a mais. A mesma
## política de duas prefeituras não soma no mesmo prédio; políticas diferentes somam. Título POLICY_<ID>, texto
## POLICY_<ID>_DESC.

enum Effect {
	## Fração somada à velocidade da produção (0,15 = +15%), multiplicada com eventos, eletricidade e especialista.
	PRODUCTION_SPEED,
	## Multiplicador da chance de incêndio das casas e da produção (0,4 = 40% da chance).
	FIRE_RISK,
	## Pontos de felicidade somados ao alvo das casas.
	HAPPINESS,
	## Fração somada ao imposto das casas (0,15 = +15%).
	TAX,
}

@export var id: StringName
@export var effect: Effect = Effect.PRODUCTION_SPEED
## Fração (PRODUCTION_SPEED, TAX), multiplicador (FIRE_RISK) ou pontos (HAPPINESS).
@export var amount: float = 0.1
@export var upkeep_per_min: int = 20
## Só se escolhe depois de tantos marcos de população.
@export var after_milestone: int = 0


func title_key() -> String:
	return "POLICY_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"
