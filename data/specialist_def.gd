class_name SpecialistDef
extends Resource
## Especialista (Fase 11): alguém que o comerciante traz a cada volta e que o jogador contrata e põe
## num prédio de produção do grupo dele, um por prédio. Ganha salário por minuto enquanto está
## contratado, posto ou não. Título SPECIALIST_<ID>, descrição SPECIALIST_<ID>_DESC.

enum Effect {
	## Fração somada à velocidade do prédio (0,25 = +25%), multiplicada com eventos e eletricidade.
	SPEED,
	## Fração cortada da manutenção do prédio (0,5 = metade).
	UPKEEP,
	## Uma tonelada a mais da saída a cada amount ciclos completos.
	EXTRA_OUTPUT,
}

## Prédios de produção em que o especialista pode trabalhar. A usina fica de fora de todos.
enum Group {
	ALL,
	## Os que plantam ou criam (fertilidade ou módulos de campo/pasto).
	FARMS,
	## As minas (jazida debaixo do prédio).
	MINES,
	## Produção com entrada (as que a usina acelera).
	FACTORIES,
	## Só os prédios da lista buildings.
	LISTED,
}

@export var id: StringName
@export var effect: Effect = Effect.SPEED
@export var target_group: Group = Group.ALL
## Prédios do grupo LISTED.
@export var buildings: Array[StringName] = []
## Fração (SPEED, UPKEEP) ou ciclos por tonelada extra (EXTRA_OUTPUT).
@export var amount: float = 0.25
@export var hire_cost: int = 2000
@export var salary_per_min: int = 10
## Peso no sorteio da oferta entre os liberados.
@export var weight: int = 1
## Só é oferecido depois de tantos marcos de população.
@export var after_milestone: int = 0


func title_key() -> String:
	return "SPECIALIST_" + String(id).to_upper()


func description_key() -> String:
	return title_key() + "_DESC"


## Ciclos por tonelada extra (EXTRA_OUTPUT), pelo menos 1.
func cycles_per_extra() -> int:
	return maxi(roundi(amount), 1)


## O prédio aceita este especialista?
func covers(def: BuildingDef) -> bool:
	if def == null or not def.is_production() or def.is_power_plant():
		return false
	match target_group:
		Group.FARMS:
			return def.fertility != &"" or def.modules_required > 0
		Group.MINES:
			return def.deposit != &""
		Group.FACTORIES:
			return def.is_electrifiable()
		Group.LISTED:
			return buildings.has(def.id)
	return true
