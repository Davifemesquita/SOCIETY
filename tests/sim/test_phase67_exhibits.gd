extends GdUnitTestSuite
## Zoológico e museu (Fase 67): a peça se compra uma vez e vai numa vaga de prédio do tipo dela, somando beleza às casas
## em volta; prédio cheio, de outro tipo, peça já exposta, bloqueada e sem dinheiro são recusados; demolir guarda as
## peças, que voltam de graça; tudo no save (o antigo carrega sem peça).

const STREET := 20


func _sim() -> Simulation:
	var sim := SimFixture.simulation()
	sim.free_build = true
	SimFixture.road(sim, Vector2i(0, STREET), Vector2i(119, STREET))
	return sim


func _zoo(sim: Simulation, x: int) -> int:
	return SimFixture.place(sim, &"zoo", Vector2i(x, STREET - 6), 2)


func _museum(sim: Simulation, x: int) -> int:
	return SimFixture.place(sim, &"museum", Vector2i(x, STREET - 5), 2)


func test_data_has_the_halls_and_twelve_exhibits() -> void:
	var data := GameData.get_default()
	assert_array(data.validate()).is_empty()
	assert_bool(data.building(&"zoo").is_exhibit_hall()).is_true()
	assert_bool(data.building(&"museum").is_exhibit_hall()).is_true()
	assert_int(data.building(&"zoo").exhibit_kind).is_equal(ExhibitDef.Kind.ANIMAL)
	assert_int(data.building(&"museum").exhibit_kind).is_equal(ExhibitDef.Kind.ARTIFACT)
	assert_int(data.exhibits.size()).is_equal(12)
	for def: ExhibitDef in data.exhibits:
		assert_str(tr(def.title_key())).override_failure_message(def.title_key()).is_not_equal(def.title_key())
		assert_str(tr(def.description_key())).is_not_equal(def.description_key())
	for id: StringName in [&"zoo", &"museum"]:
		assert_bool(Icons.has("building_" + id)).override_failure_message(String(id)).is_true()


func test_buying_an_exhibit_costs_money_and_raises_the_beauty_around() -> void:
	var sim := _sim()
	var house := SimFixture.house(sim, 40, STREET, &"peasants", 5.0)
	var zoo := _zoo(sim, 30)
	sim.free_build = false
	var before: float = sim.derived_state().beauty[house]
	var money := sim.world.money
	assert_bool(sim.execute(PlaceExhibitCommand.new(&"zebras", zoo)).ok()).is_true()
	assert_float(sim.world.money).is_equal_approx(money - sim.data.exhibit(&"zebras").price, 0.001)
	assert_float(sim.derived_state().beauty[house]).is_greater(before)
	assert_float(DerivedState.beauty_strength(sim.world, sim.data, zoo)).is_equal_approx(
			sim.data.building(&"zoo").beauty + sim.data.exhibit(&"zebras").beauty, 0.0001)


func test_refusals() -> void:
	var sim := _sim()
	var zoo := _zoo(sim, 30)
	var museum := _museum(sim, 60)
	sim.free_build = false
	# peça de museu no zoológico
	assert_str(String(sim.execute(PlaceExhibitCommand.new(&"amphora", zoo)).reason)).is_equal(String(PlaceExhibitCommand.NOT_A_HALL))
	# bloqueada pelo marco
	assert_str(String(sim.execute(PlaceExhibitCommand.new(&"lion", zoo)).reason)).is_equal(String(PlaceExhibitCommand.LOCKED))
	assert_bool(sim.execute(PlaceExhibitCommand.new(&"parrots", zoo)).ok()).is_true()
	# já exposta
	assert_str(String(sim.execute(PlaceExhibitCommand.new(&"parrots", zoo)).reason)).is_equal(String(PlaceExhibitCommand.ALREADY_SHOWN))
	# sem dinheiro
	sim.world.money = 10.0
	assert_str(String(sim.execute(PlaceExhibitCommand.new(&"amphora", museum)).reason)).is_equal(String(PlacementRules.NO_MONEY))


func test_a_full_hall_takes_no_more() -> void:
	var sim := _sim()
	var zoo := _zoo(sim, 30)
	# com a obra livre, as seis peças de animal cabem nas seis vagas
	for def: ExhibitDef in sim.data.exhibits:
		if def.kind == ExhibitDef.Kind.ANIMAL:
			assert_bool(sim.execute(PlaceExhibitCommand.new(def.id, zoo)).ok()).is_true()
	assert_int(sim.world.exhibits_state.in_building(zoo, sim.data).size()).is_equal(6)
	# num zoológico de uma vaga só, a segunda peça é recusada
	var hall := sim.data.building(&"zoo")
	var slots := hall.exhibit_slots
	hall.exhibit_slots = 1
	var small := _zoo(sim, 60)
	sim.world.exhibits_state.placed.clear()
	assert_bool(sim.execute(PlaceExhibitCommand.new(&"parrots", small)).ok()).is_true()
	var reason := PlaceExhibitCommand.check(sim.world, sim.data, &"zebras", small, true)
	hall.exhibit_slots = slots
	assert_str(String(reason)).is_equal(String(PlaceExhibitCommand.HALL_FULL))


func test_demolishing_stores_the_exhibits_and_they_return_for_free() -> void:
	var sim := _sim()
	var zoo := _zoo(sim, 30)
	sim.free_build = false
	assert_bool(sim.execute(PlaceExhibitCommand.new(&"zebras", zoo)).ok()).is_true()
	var record := sim.world.building(zoo)
	sim.free_build = true
	assert_bool(sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(record.origin, Vector2i.ONE))).ok()).is_true()
	assert_int(sim.world.exhibits_state.placed[&"zebras"]).is_equal(0)
	var other := _zoo(sim, 60)
	sim.free_build = false
	var money := sim.world.money
	assert_bool(sim.execute(PlaceExhibitCommand.new(&"zebras", other)).ok()).is_true()
	assert_float(sim.world.money).is_equal(money)
	assert_int(sim.world.exhibits_state.placed[&"zebras"]).is_equal(other)


func test_exhibits_go_in_the_save() -> void:
	var sim := _sim()
	var zoo := _zoo(sim, 30)
	sim.execute(PlaceExhibitCommand.new(&"zebras", zoo))
	sim.world.exhibits_state.placed[&"amphora"] = 0
	var saved := sim.world.to_dict()
	var loaded := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(loaded).is_not_null()
	assert_dict(loaded.exhibits_state.to_dict()).is_equal(sim.world.exhibits_state.to_dict())
	# o save de antes da fase carrega sem peça
	var old := saved.duplicate(true)
	old.erase("exhibits")
	var from_old := WorldState.from_dict(old, sim.data, sim.config)
	assert_object(from_old).is_not_null()
	assert_bool(from_old.exhibits_state.placed.is_empty()).is_true()
	# peça de museu no zoológico recusa o save
	var exhibits: Dictionary = saved["exhibits"]
	var placed: Dictionary = exhibits["placed"]
	placed[&"amphora"] = zoo
	assert_object(WorldState.from_dict(saved, sim.data, sim.config)).is_null()
