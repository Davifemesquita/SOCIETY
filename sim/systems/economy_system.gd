class_name EconomySystem
extends RefCounted
## Dinheiro: entra o imposto das casas (calculado pela população no mesmo tick), sai a
## manutenção de todo prédio que existe (metade se pausado). Guarda as taxas por minuto para
## a barra superior.


static func run(world: WorldState, derived: DerivedState, dt: float) -> void:
	world.income_per_min = derived.income_per_min()
	world.upkeep_per_min = derived.upkeep_per_min
	world.money += (world.income_per_min - world.upkeep_per_min) * dt / 60.0
