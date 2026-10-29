extends GdUnitTestSuite
## Moradores na festa (Fase 83): na hora dos fogos, parte dos moradores também vai às praças da festa e fica na rua em
## volta do mastro, de frente para ele, e sai andando do lugar; sem festa, nenhum morador vai à praça. Só visual.

const STREET := 6
const STRIDES := [1.4, 1.4, 0.0, 0.0]
const NIGHT := 0.0

var _sim: Simulation
var _square: int


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true
	SimFixture.port(_sim)
	for x: int in [26, 30, 34, 50, 54]:
		SimFixture.house_on_main_road(_sim, x, &"peasants", 10.0)
	_sim.world.events_state.enabled = true
	_sim.world.events_state.next_edition_tick = 999_999_999
	_square = SimFixture.place(_sim, &"fountain_square", Vector2i(40, STREET + 1), 0)


func _festival() -> void:
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


func test_at_night_residents_watch_around_the_mast() -> void:
	_festival()
	assert_array(FestivalView.strings_of(_sim, _square)).is_not_empty()
	var mast_top: Vector3 = FestivalView.strings_of(_sim, _square)[0][0]
	var mast := Vector3(mast_top.x, 0.0, mast_top.z)
	var crowd := _crowd()
	crowd.update(0.5, NIGHT)
	assert_bool(crowd.fireworks_now(SimFixture.ISLAND)).is_true()
	var seen := 0
	for step: int in 400:
		crowd.update(0.5, NIGHT)
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or agent.tourist or agent.state != Crowd.State.WAITING or agent.target_id != _square:
				continue
			assert_bool(agent.watching).is_true()
			var flat := Vector3(agent.spot.x, 0.0, agent.spot.z)
			var away := flat.distance_to(mast)
			assert_float(away).is_greater_equal(Crowd.WATCH_NEAR_M - 0.01)
			assert_float(away).is_less_equal(Crowd.WATCH_FAR_M + _sim.config.cell_size_m * Crowd.WATCH_SIDE_SHARE + 0.01)
			assert_float(agent.facing.normalized().dot((mast - flat).normalized())).is_greater(cos(0.41))
			seen += 1
	assert_int(seen).is_greater(0)


func test_residents_leave_the_festival_from_their_spot() -> void:
	_festival()
	var crowd := _crowd()
	var watched: Dictionary[int, Vector3] = {}
	var left := 0
	for step: int in 600:
		crowd.update(0.5, NIGHT)
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or agent.tourist:
				continue
			if agent.state == Crowd.State.WAITING and agent.target_id == _square:
				watched[agent.index] = agent.spot
			elif watched.has(agent.index) and agent.state == Crowd.State.WALKING and agent.leg == Crowd.Leg.TO_HOME:
				assert_bool(agent.points[0].is_equal_approx(watched[agent.index])).is_true()
				assert_bool(agent.watching).is_false()
				watched.erase(agent.index)
				left += 1
	assert_int(left).is_greater(0)


func test_the_fireworks_fill_the_street_at_night() -> void:
	var crowd := _crowd()
	crowd.activity_override = -1.0
	crowd.update(0.5, NIGHT)
	var quiet := crowd.desired_out(NIGHT)
	assert_int(crowd.agent_count()).is_greater(0)
	_festival()
	crowd.update(2.5, NIGHT)
	assert_bool(crowd.fireworks_now(SimFixture.ISLAND)).is_true()
	var festive := crowd.desired_out(NIGHT)
	assert_int(festive).is_greater(quiet)
	# todos os pedestres estão na ilha da festa: metade na rua (a soma em ponto flutuante pode arredondar para o lado)
	var half := crowd.agent_count() * Crowd.FESTIVAL_NIGHT_ACTIVITY
	assert_int(festive).is_between(floori(half), ceili(half))
	# de dia a hora já põe mais gente que isso: a festa não muda nada
	assert_int(crowd.desired_out(12.0)).is_equal(roundi(crowd.agent_count() * DayClock.activity(_sim.config, 12.0)))


func test_without_festival_no_resident_goes_to_the_square() -> void:
	var crowd := _crowd()
	crowd.update(0.5, NIGHT)
	assert_bool(crowd.fireworks_now(SimFixture.ISLAND)).is_false()
	var out := 0
	for step: int in 400:
		crowd.update(0.5, NIGHT)
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or agent.tourist:
				continue
			assert_int(agent.target_id).is_not_equal(_square)
			out += int(agent.state != Crowd.State.HOME)
	assert_int(out).is_greater(0)
