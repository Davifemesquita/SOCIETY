class_name SpecialistSystem
extends RefCounted
## Oferta de especialistas (Fase 11): a cada volta nova do comerciante, ele traz specialist_offers
## especialistas sorteados pelo peso entre os liberados pelos marcos (sem repetir na mesma oferta),
## com hash([semente, &"specialist", volta, i]). Sem comerciante no mar, não há oferta.


static func run(world: WorldState, data: GameData, config: GameConfig) -> void:
	var state := world.specialists_state
	if world.trader.ship_id == 0 or state.offer_tour == world.trader.tour:
		return
	state.offer_tour = world.trader.tour
	state.offers = roll_offers(world.seed, world.trader.tour, world.milestones_reached, data, config)
	if not state.offers.is_empty():
		EventBus.specialists_offered.emit()
	EventBus.specialists_changed.emit()


static func roll_offers(world_seed: int, tour: int, milestones: int, data: GameData, config: GameConfig) -> Array[StringName]:
	var pool: Array[SpecialistDef] = []
	for def: SpecialistDef in data.specialists:
		if def.after_milestone <= milestones:
			pool.append(def)
	var picked: Array[StringName] = []
	for index: int in config.specialist_offers:
		var total := 0
		for def: SpecialistDef in pool:
			total += def.weight
		if total <= 0:
			break
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([world_seed, &"specialist", tour, index])
		var roll := rng.randi_range(1, total)
		for def: SpecialistDef in pool:
			roll -= def.weight
			if roll <= 0:
				picked.append(def.id)
				pool.erase(def)
				break
	return picked
