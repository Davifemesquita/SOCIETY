extends GdUnitTestSuite
## Ver os fogos (Fase 82): na festa, na hora dos fogos, os turistas vão às praças da festa e ficam na rua em volta do
## mastro, de frente para ele; de dia, seguem visitando as atrações. Só visual.

const STREET := 6
const STRIDES := [1.4, 1.4, 0.0, 0.0]
const NIGHT := 0.0
const DAY := 12.0

var _sim: Simulation
var _square: int
var _statue: int


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true
	SimFixture.port(_sim)
	SimFixture.house_on_main_road(_sim, 30, &"peasants", 5.0)
	_sim.world.events_state.enabled = true
	_sim.world.events_state.next_edition_tick = 999_999_999
	_square = SimFixture.place(_sim, &"fountain_square", Vector2i(40, STREET + 1), 0)
	_statue = SimFixture.place(_sim, &"statue", Vector2i(50, STREET + 1), 0)
	var event := WorldEvent.new()
	event.def = _sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = SimFixture.ISLAND
	event.ends_tick = _sim.world.tick + 100000
	_sim.world.events_state.events.append(event)


func _crowd() -> Crowd:
	var strides: Array[PackedFloat32Array] = [PackedFloat32Array(STRIDES), PackedFloat32Array(STRIDES)]
	var crowd := Crowd.new(_sim, _sim.config, strides, 4)
	crowd.activity_override = 1.0
	return crowd


func _watchers(crowd: Crowd) -> Array[Crowd.Agent]:
	var result: Array[Crowd.Agent] = []
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.tourist and agent.state == Crowd.State.WAITING:
			result.append(agent)
	return result


func test_at_night_tourists_watch_around_the_mast() -> void:
	assert_array(FestivalView.strings_of(_sim, _square)).is_not_empty()
	var mast_top: Vector3 = FestivalView.strings_of(_sim, _square)[0][0]
	var mast := Vector3(mast_top.x, 0.0, mast_top.z)
	var crowd := _crowd()
	crowd.update(0.5, NIGHT)
	assert_bool(crowd.fireworks_now(SimFixture.ISLAND)).is_true()
	var seen := 0
	for step: int in 400:
		crowd.update(0.5, NIGHT)
		for agent: Crowd.Agent in _watchers(crowd):
			assert_int(agent.target_id).is_equal(_square)
			var flat := Vector3(agent.spot.x, 0.0, agent.spot.z)
			var away := flat.distance_to(mast)
			assert_float(away).is_greater_equal(Crowd.WATCH_NEAR_M - 0.01)
			assert_float(away).is_less_equal(Crowd.WATCH_FAR_M + _sim.config.cell_size_m * Crowd.WATCH_SIDE_SHARE + 0.01)
			# de frente para o mastro (até 0,4 rad de folga)
			assert_float(agent.facing.normalized().dot((mast - flat).normalized())).is_greater(cos(0.41))
			seen += 1
	assert_int(seen).is_greater(0)


func test_leaving_the_festival_walks_from_the_spot() -> void:
	var crowd := _crowd()
	var watched: Dictionary[int, Vector3] = {}
	var left := 0
	for step: int in 600:
		crowd.update(0.5, NIGHT)
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or not agent.tourist:
				continue
			if agent.state == Crowd.State.WAITING:
				watched[agent.index] = agent.spot
			elif watched.has(agent.index) and agent.state == Crowd.State.WALKING and agent.leg == Crowd.Leg.TO_HOME:
				assert_bool(agent.points[0].is_equal_approx(watched[agent.index])).is_true()
				# a rota em cache não leva o lugar dele: o próximo que sair dali não começa no lugar de outro
				assert_bool(agent.points[1].is_equal_approx(watched[agent.index])).is_false()
				watched.erase(agent.index)
				left += 1
	assert_int(left).is_greater(0)


func test_by_day_tourists_still_visit_the_attractions() -> void:
	var crowd := _crowd()
	crowd.update(0.5, DAY)
	assert_bool(crowd.fireworks_now(SimFixture.ISLAND)).is_false()
	var at_statue := 0
	for step: int in 400:
		crowd.update(0.5, DAY)
		for agent: Crowd.Agent in _watchers(crowd):
			at_statue += int(agent.target_id == _statue)
	assert_int(at_statue).is_greater(0)
