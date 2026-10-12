class_name WorkforceSystem
extends RefCounted
## Força de trabalho por classe e por ilha: os moradores da classe contra os trabalhadores que
## os prédios dela pedem. Faltando gente, todos os prédios daquela classe desaceleram igual
## (80% dos trabalhadores = 80% de velocidade). Classe de cima não substitui a de baixo.
## As somas vêm prontas do DerivedState (grupos de casas e demanda dos prédios).


static func run(world: WorldState, derived: DerivedState) -> void:
	for island_id: int in world.economies.size():
		var economy := world.economy(island_id)
		economy.workforce_available = derived.residents_by_tier(island_id)
		economy.workforce_demand.clear()
		economy.workforce_factor.clear()
		var demand: Dictionary = derived.workforce_demand.get(island_id, {})
		for tier: StringName in demand:
			var wanted: float = demand[tier]
			var available: float = economy.workforce_available.get(tier, 0.0)
			economy.workforce_demand[tier] = wanted
			economy.workforce_factor[tier] = minf(1.0, available / wanted) if wanted > 0.0 else 1.0
