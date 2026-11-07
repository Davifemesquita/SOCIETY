extends GdUnitTestSuite
## Turistas na rua (Fase 80): com os eventos ligados, a ilha com atratividade ganha turistas na multidão (um por
## tourists_per_point pontos, até o teto), de roupa clara e com a calça da classe mais rica; saem do entreposto, visitam
## as atrações da ilha (os prédios com beleza) e voltam. Sem os eventos ou sem atratividade, nenhum. Só visual.

const STREET := 6
const STRIDES := [1.4, 1.4, 0.0, 0.0]

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true
	SimFixture.port(_sim)
	SimFixture.house_on_main_road(_sim, 30, &"peasants", 5.0)
	_sim.world.events_state.enabled = true
	_sim.world.events_state.next_edition_tick = 999_999_999
	SimFixture.place(_sim, &"fountain_square", Vector2i(40, STREET + 1), 0)
	SimFixture.place(_sim, &"statue", Vector2i(50, STREET + 1), 0)


func _crowd() -> Crowd:
	var strides: Array[PackedFloat32Array] = [PackedFloat32Array(STRIDES), PackedFloat32Array(STRIDES)]
	return Crowd.new(_sim, _sim.config, strides, 4)


func _expected() -> int:
	var points: float = _sim.derived_state().attractiveness[SimFixture.ISLAND]
	return mini(_sim.config.max_tourists_per_island, floori(points * _sim.config.tourists_per_point))


func _run(crowd: Crowd, seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		crowd.update(0.5, 12.0)
		left -= 0.5


func test_tourists_follow_the_attractiveness() -> void:
	assert_int(_expected()).is_greater(0)
	var crowd := _crowd()
	_run(crowd, 3.0)
	assert_int(crowd.tourist_count()).is_equal(_expected())
	var richest := _sim.data.tiers[_sim.data.tiers.size() - 1].id
	var post_id := 0
	for record: BuildingRecord in _sim.world.buildings.values():
		if _sim.def_of(record).is_trading_post:
			post_id = record.id
	for agent: Crowd.Agent in crowd.agents:
		if agent == null or not agent.tourist:
			continue
		# de roupa clara, com a calça da classe mais rica, morando no entreposto
		assert_str(String(agent.tier)).is_equal(String(richest))
		assert_int(agent.home_id).is_equal(post_id)
		var coat := Color(agent.color.r, agent.color.g, agent.color.b)
		var known := false
		for color: Color in Crowd.TOURIST_COLORS:
			known = known or coat.is_equal_approx(color)
		assert_bool(known).is_true()
	# o teto por ilha manda
	_sim.config.max_tourists_per_island = 1
	_run(crowd, 3.0)
	_run(crowd, 120.0)
	assert_int(crowd.tourist_count()).is_less_equal(1)


func test_tourists_visit_the_attractions_and_go_back() -> void:
	var crowd := _crowd()
	var attractions: Array[int] = []
	for record: BuildingRecord in _sim.world.buildings.values():
		var def := _sim.def_of(record)
		if def.beauty > 0.0 and def.beauty_radius_cells > 0:
			attractions.append(record.id)
	var visited := false
	var went_back := false
	for step: int in 600:
		crowd.update(0.5, 12.0)
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or not agent.tourist or agent.state == Crowd.State.HOME:
				continue
			if agent.leg == Crowd.Leg.TO_SERVICE:
				# o turista só visita atração (nunca trabalho nem serviço da casa)
				assert_bool(attractions.has(agent.target_id)).is_true()
				if agent.state == Crowd.State.WAITING:
					visited = true
			assert_bool(agent.leg != Crowd.Leg.TO_WORK).is_true()
			if agent.leg == Crowd.Leg.TO_HOME and agent.state == Crowd.State.WALKING:
				went_back = true
	assert_bool(visited).is_true()
	assert_bool(went_back).is_true()


func test_no_events_or_no_beauty_no_tourists() -> void:
	_sim.world.events_state.enabled = false
	var crowd := _crowd()
	_run(crowd, 3.0)
	assert_int(crowd.tourist_count()).is_equal(0)
	# com os eventos, aparecem; sem as atrações, vão embora (os que andam, quando chegam)
	_sim.world.events_state.enabled = true
	_run(crowd, 3.0)
	assert_int(crowd.tourist_count()).is_greater(0)
	_sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(38, STREET + 1), Vector2i(20, 6))))
	assert_float(_sim.derived_state().attractiveness.get(SimFixture.ISLAND, 0.0)).is_equal(0.0)
	_run(crowd, 300.0)
	assert_int(crowd.tourist_count()).is_equal(0)
