class_name ScenarioDef
extends Resource
## Cenário pronto (Fase 12): um jogo novo já configurado (semente, tamanho, dificuldade, eventos,
## rivais e riscos) com objetivo e prazo. O título é SCENARIO_<ID> e a descrição SCENARIO_<ID>_DESC.

@export var id: StringName
@export var seed: int = 0
## 0 pequeno, 1 médio, 2 grande (GameConfig.archipelago_island_counts).
@export var archipelago_size: int = 1
## 0 fácil, 1 normal, 2 difícil.
@export var difficulty: int = 1
## Dinheiro inicial no lugar do da dificuldade (0 = o da dificuldade).
@export var starting_money: int = 0
@export var events: bool = true
@export var rivals: bool = true
@export var risks: bool = true

@export_group("Objetivo")
## O que vence a partida (a mesma conta das metas guiadas) e quanto.
@export var victory_kind: GoalDef.Kind = GoalDef.Kind.TIER_POPULATION
@export var victory_target: StringName
@export var victory_amount: int = 1
## Prazo em minutos de jogo (0 = sem prazo).
@export var time_limit_min: float = 0.0


func title_key() -> String:
	return "SCENARIO_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"
