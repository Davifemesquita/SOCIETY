extends GdUnitTestSuite
## Jornal (Fase 63): desligado com os eventos; ligado, a primeira edição sai na hora marcada e as seguintes a cada
## intervalo, com a manchete sorteada pela semente (a mesma partida dá as mesmas manchetes) entre as de notícia
## liberadas pelos marcos. A manchete soma felicidade ao alvo das casas de todas as ilhas. A propaganda paga troca a
## manchete, uma vez por edição. Tudo vai no save, e o save de antes do jornal carrega sem edição.


## Duas ilhas com os eventos ligados e o jornal acelerado (primeira edição em 10 s, as outras a cada 20 s).
func _fast_sim(enabled: bool = true) -> Simulation:
	var sim := SimFixture.two_islands()
	sim.world.seed = 1840
	sim.config.newspaper_first_after_s = 10.0
	sim.config.newspaper_interval_s = 20.0
	sim.world.events_state.enabled = enabled
	return sim


func _editions(sim: Simulation, seconds: float) -> Array[String]:
	var seen: Array[String] = []
	var record := func(headline_id: StringName) -> void: seen.append("%s:%d" % [headline_id, sim.world.tick])
	EventBus.newspaper_published.connect(record)
	SimFixture.run(sim, seconds)
	EventBus.newspaper_published.disconnect(record)
	return seen


func test_data_has_news_and_propaganda_and_is_valid() -> void:
	var data := GameData.get_default()
	assert_array(data.validate()).is_empty()
	assert_array(GameConfig.get_default().validate()).is_empty()
	var news := data.headlines.filter(func(def: HeadlineDef) -> bool: return not def.propaganda)
	var propaganda := data.headlines.filter(func(def: HeadlineDef) -> bool: return def.propaganda)
	assert_int(news.size()).is_greater_equal(4)
	assert_int(propaganda.size()).is_greater_equal(2)
	# há notícia boa e ruim, e toda propaganda sobe a felicidade
	assert_bool(news.any(func(def: HeadlineDef) -> bool: return def.happiness > 0.0)).is_true()
	assert_bool(news.any(func(def: HeadlineDef) -> bool: return def.happiness < 0.0)).is_true()
	assert_bool(propaganda.all(func(def: HeadlineDef) -> bool: return def.happiness > 0.0)).is_true()
	for def: HeadlineDef in data.headlines:
		assert_str(tr(def.title_key())).override_failure_message(def.title_key()).is_not_equal(def.title_key())
		assert_str(tr(def.description_key())).override_failure_message(def.description_key()).is_not_equal(def.description_key())


func test_no_newspaper_with_events_off() -> void:
	var sim := _fast_sim(false)
	assert_array(_editions(sim, 60.0)).is_empty()
	assert_int(sim.world.events_state.edition_count).is_equal(0)
	assert_object(sim.world.events_state.headline).is_null()


func test_editions_come_on_schedule_with_news_headlines() -> void:
	var sim := _fast_sim()
	var seen := _editions(sim, 75.0)
	# marca na primeira conferência e sai aos 10 s, depois aos 30, 50 e 70
	assert_int(seen.size()).is_equal(4)
	var state := sim.world.events_state
	assert_int(state.edition_count).is_equal(4)
	assert_object(state.headline).is_not_null()
	assert_bool(state.headline.propaganda).is_false()
	assert_int(state.headline.after_milestone).is_less_equal(sim.world.milestones_reached)
	var ticks: Array[int] = []
	for entry: String in seen:
		ticks.append(entry.get_slice(":", 1).to_int())
	var interval := sim.config.ticks_of(sim.config.newspaper_interval_s)
	for index: int in range(1, ticks.size()):
		assert_int(ticks[index] - ticks[index - 1]).is_equal(interval)


func test_the_same_seed_gives_the_same_headlines() -> void:
	var first := _editions(_fast_sim(), 200.0)
	var second := _editions(_fast_sim(), 200.0)
	assert_array(second).is_equal(first)
	var other := _fast_sim()
	other.world.seed = 31337
	assert_array(_editions(other, 200.0)).is_not_equal(first)


func test_headline_happiness_applies_on_every_island() -> void:
	var sim := _fast_sim()
	var state := sim.world.events_state
	var def := HeadlineDef.new()
	def.id = &"test_headline"
	def.happiness = 7.0
	state.headline = def
	assert_float(EventEffects.happiness(state, 0)).is_equal(7.0)
	assert_float(EventEffects.happiness(state, 1)).is_equal(7.0)
	state.headline = null
	assert_float(EventEffects.happiness(state, 0)).is_equal(0.0)


func test_good_headline_raises_the_house_happiness() -> void:
	var sims: Array[Simulation] = [SimFixture.simulation(), SimFixture.simulation()]
	var happiness: Array[float] = []
	for index: int in 2:
		var sim := sims[index]
		SimFixture.road(sim, Vector2i(0, 20), Vector2i(119, 20))
		var house := SimFixture.house(sim, 60, 20, &"peasants", 10.0)
		if index == 1:
			var def := HeadlineDef.new()
			def.id = &"test_headline"
			def.happiness = 12.0
			sim.world.events_state.headline = def
		SimFixture.run(sim, 600.0)
		happiness.append(sim.world.building(house).happiness)
	assert_float(happiness[1]).is_greater(happiness[0] + 5.0)


func test_propaganda_replaces_the_headline_once_per_edition_for_a_price() -> void:
	var sim := _fast_sim()
	var state := sim.world.events_state
	var choice := NewspaperSystem.propaganda_choices(sim.world, sim.data)[0]
	# antes da primeira edição não há o que trocar
	assert_str(String(sim.execute(BuyPropagandaCommand.new(choice.id)).reason)).is_equal(String(BuyPropagandaCommand.NO_EDITION))
	SimFixture.run_until(sim, func() -> bool: return state.edition_count > 0, 30.0)
	var money := sim.world.money
	var result := sim.execute(BuyPropagandaCommand.new(choice.id))
	assert_bool(result.ok()).is_true()
	assert_float(sim.world.money).is_equal_approx(money - sim.config.newspaper_propaganda_cost, 0.001)
	assert_str(String(state.headline_id)).is_equal(String(choice.id))
	assert_bool(state.propaganda_used).is_true()
	# a segunda na mesma edição é recusada
	assert_str(String(sim.execute(BuyPropagandaCommand.new(choice.id)).reason)).is_equal(String(BuyPropagandaCommand.ALREADY_USED))
	# a próxima edição volta a ser notícia e libera a propaganda de novo
	var editions := state.edition_count
	SimFixture.run_until(sim, func() -> bool: return state.edition_count > editions, 30.0)
	assert_bool(state.propaganda_used).is_false()
	assert_bool(state.headline == null or not state.headline.propaganda).is_true()


func test_propaganda_needs_money_and_a_propaganda_headline() -> void:
	var sim := _fast_sim()
	var state := sim.world.events_state
	SimFixture.run_until(sim, func() -> bool: return state.edition_count > 0, 30.0)
	var news := sim.data.headlines.filter(func(def: HeadlineDef) -> bool: return not def.propaganda)
	var first_news: HeadlineDef = news[0]
	assert_str(String(sim.execute(BuyPropagandaCommand.new(first_news.id)).reason)).is_equal(String(BuyPropagandaCommand.NOT_PROPAGANDA))
	# a de marco alto ainda não se compra
	var locked := sim.data.headlines.filter(func(def: HeadlineDef) -> bool:
		return def.propaganda and def.after_milestone > sim.world.milestones_reached)
	if not locked.is_empty():
		var locked_def: HeadlineDef = locked[0]
		assert_str(String(sim.execute(BuyPropagandaCommand.new(locked_def.id)).reason)).is_equal(String(BuyPropagandaCommand.NOT_PROPAGANDA))
	sim.world.money = sim.config.newspaper_propaganda_cost - 1
	var choice := NewspaperSystem.propaganda_choices(sim.world, sim.data)[0]
	assert_str(String(sim.execute(BuyPropagandaCommand.new(choice.id)).reason)).is_equal(String(PlacementRules.NO_MONEY))
	assert_bool(state.propaganda_used).is_false()


func test_save_and_load_keeps_the_newspaper_and_continues_the_same() -> void:
	var sim := _fast_sim()
	var state := sim.world.events_state
	SimFixture.run(sim, 35.0)
	sim.execute(BuyPropagandaCommand.new(NewspaperSystem.propaganda_choices(sim.world, sim.data)[0].id))
	var saved := sim.world.to_dict()
	var loaded_world := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(loaded_world).is_not_null()
	assert_dict(loaded_world.events_state.to_dict()).is_equal(state.to_dict())
	assert_object(loaded_world.events_state.headline).is_same(state.headline)
	var copy := Simulation.new(sim.config, sim.data, loaded_world)
	assert_array(_editions(copy, 100.0)).is_equal(_editions(sim, 100.0))


func test_old_saves_load_without_an_edition_and_bad_headlines_refuse() -> void:
	var sim := _fast_sim()
	var saved := sim.world.to_dict()
	var events: Dictionary = saved["events"]
	for key: String in ["edition_count", "next_edition_tick", "headline", "propaganda_used"]:
		events.erase(key)
	var loaded := WorldState.from_dict(saved, sim.data, sim.config)
	assert_object(loaded).is_not_null()
	assert_int(loaded.events_state.edition_count).is_equal(0)
	assert_object(loaded.events_state.headline).is_null()
	events["headline"] = &"no_such_headline"
	assert_object(WorldState.from_dict(saved, sim.data, sim.config)).is_null()
