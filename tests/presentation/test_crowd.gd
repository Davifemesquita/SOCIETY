extends GdUnitTestSuite
## Multidão (seção 9): quantidade pela população com teto, rotina casa → trabalho → serviço → casa
## só pela estrada, menos gente à noite, e nada disso mexe na simulação.

const STREET := 10
const STRIDES := [1.4, 1.4, 0.0, 0.0]

var _sim: Simulation
var _houses: Array[int] = []
var _work: int
var _market: int


## Rua em y = 10 com 6 casas de camponeses (20 moradores cada) em cima; embaixo, o mercado (que
## alcança as casas) e o lenhador.
func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 30))
	SimFixture.road(_sim, Vector2i(2, STREET), Vector2i(70, STREET))
	_houses.clear()
	for i: int in 6:
		_houses.append(SimFixture.house(_sim, 4 + i * 3, STREET, &"peasants", 20.0))
	_market = SimFixture.place(_sim, &"market", Vector2i(26, STREET + 1), 0)
	_work = SimFixture.place(_sim, &"lumberjack", Vector2i(36, STREET + 1), 0)


func _crowd(seed_value: int = 3) -> Crowd:
	var strides: Array[PackedFloat32Array] = [PackedFloat32Array(STRIDES), PackedFloat32Array(STRIDES)]
	return Crowd.new(_sim, _sim.config, strides, seed_value)


func _run(crowd: Crowd, seconds: int, hour: float) -> void:
	for second: int in seconds:
		crowd.update(1.0, hour)


func test_one_pedestrian_for_every_five_residents() -> void:
	var crowd := _crowd()
	_run(crowd, 1, 12.0)
	assert_int(crowd.agent_count()).is_equal(24)


func test_visible_pedestrians_are_capped() -> void:
	_sim.config.max_visible_pedestrians = 10
	var crowd := _crowd()
	_run(crowd, 30, 12.0)
	assert_int(crowd.agent_count()).is_equal(10)
	assert_int(crowd.visible_count()).is_less_equal(10)


func test_fewer_people_on_the_street_at_night() -> void:
	var day := _crowd()
	_run(day, 120, 12.0)
	var night := _crowd()
	_run(night, 120, 2.0)
	assert_int(day.visible_count()).is_greater(night.visible_count() * 3)
	assert_int(night.out_count()).is_less_equal(night.desired_out(2.0) + 1)


func test_routine_goes_to_work_then_to_the_service_then_home() -> void:
	var crowd := _crowd()
	crowd.activity_override = 1.0
	var targets: Dictionary[int, bool] = {}
	var legs: Dictionary[int, bool] = {}
	for second: int in 400:
		crowd.update(1.0, 12.0)
		for agent: Crowd.Agent in crowd.agents:
			if agent != null and agent.state == Crowd.State.WALKING:
				targets[agent.target_id] = true
				legs[agent.leg] = true
	assert_bool(targets.has(_work)).is_true()
	assert_bool(targets.has(_market)).is_true()
	assert_array(legs.keys()).contains_exactly_in_any_order([Crowd.Leg.TO_WORK, Crowd.Leg.TO_SERVICE, Crowd.Leg.TO_HOME])


func test_pedestrians_walk_only_on_the_road() -> void:
	var crowd := _crowd()
	crowd.activity_override = 1.0
	var grid := _sim.world.island(0)
	var checked := 0
	for second: int in 120:
		crowd.update(1.0, 12.0)
		for agent: Crowd.Agent in crowd.agents:
			if agent == null or agent.state != Crowd.State.WALKING:
				continue
			# a primeira e a última perna saem da porta; o resto é calçada
			if agent.segment == 0 or agent.segment >= agent.points.size() - 2:
				continue
			var point := crowd.position_of(agent)
			var cell := Vector2i(floori(point.x / _sim.config.cell_size_m), floori(point.z / _sim.config.cell_size_m))
			assert_bool(grid.has_road(cell)).override_failure_message("pedestre fora da estrada em %s" % point).is_true()
			checked += 1
	assert_int(checked).is_greater(50)


func test_disconnected_buildings_are_never_a_destination() -> void:
	SimFixture.road(_sim, Vector2i(2, 25), Vector2i(20, 25))
	var far_work := SimFixture.place(_sim, &"lumberjack", Vector2i(10, 26), 0)
	var crowd := _crowd()
	crowd.activity_override = 1.0
	for second: int in 300:
		crowd.update(1.0, 12.0)
		for agent: Crowd.Agent in crowd.agents:
			assert_bool(agent != null and agent.target_id == far_work).is_false()


func test_demolished_home_takes_its_pedestrians_and_a_cut_road_sends_walkers_home() -> void:
	var crowd := _crowd()
	crowd.activity_override = 1.0
	_run(crowd, 60, 12.0)
	_sim.execute(DemolishCommand.new(0, Rect2i(_sim.world.building(_houses[0]).origin, Vector2i(1, 1))))
	crowd.mark_structure_changed()
	_run(crowd, 3, 12.0)
	for agent: Crowd.Agent in crowd.agents:
		assert_bool(agent != null and agent.home_id == _houses[0]).is_false()
	_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(30, STREET), Vector2i(1, 1))))
	crowd.mark_structure_changed()
	crowd.update(0.01, 12.0)
	var cut := _sim.world.island(0).index(Vector2i(30, STREET))
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.state == Crowd.State.WALKING:
			assert_bool(agent.cells.has(cut)).is_false()


func test_same_seed_gives_the_same_crowd() -> void:
	var first := _crowd(9)
	var second := _crowd(9)
	_run(first, 90, 12.0)
	_run(second, 90, 12.0)
	assert_int(first.agents.size()).is_equal(second.agents.size())
	for i: int in first.agents.size():
		var a := first.agents[i]
		var b := second.agents[i]
		if a == null or b == null:
			assert_bool(a == null and b == null).is_true()
			continue
		assert_vector(first.position_of(a)).is_equal(second.position_of(b))
		assert_int(a.target_id).is_equal(b.target_id)


func test_pause_freezes_everyone() -> void:
	var crowd := _crowd()
	crowd.activity_override = 1.0
	_run(crowd, 60, 12.0)
	var before: Array[Vector3] = []
	for agent: Crowd.Agent in crowd.agents:
		before.append(crowd.position_of(agent) if agent != null else Vector3.ZERO)
	for frame: int in 30:
		crowd.update(0.0, 12.0)
	for i: int in crowd.agents.size():
		if crowd.agents[i] != null:
			assert_vector(crowd.position_of(crowd.agents[i])).is_equal(before[i])


func test_the_crowd_never_touches_the_simulation() -> void:
	var before := JSON.stringify(SaveSystem.pack_floats(_sim.world.to_dict()))
	var crowd := _crowd()
	crowd.activity_override = 1.0
	_run(crowd, 200, 12.0)
	assert_str(JSON.stringify(SaveSystem.pack_floats(_sim.world.to_dict()))).is_equal(before)


func test_people_leaving_the_market_carry_baskets() -> void:
	var crowd := _crowd()
	crowd.activity_override = 1.0
	var carried := false
	for second: int in 400:
		crowd.update(1.0, 12.0)
		for agent: Crowd.Agent in crowd.agents:
			if agent != null and agent.state == Crowd.State.WALKING and agent.leg == Crowd.Leg.TO_HOME:
				carried = carried or agent.clip == Crowd.CLIP_WALK_CARRY
	assert_bool(carried).is_true()


func test_upgraded_house_gets_pedestrians_of_the_new_tier() -> void:
	var crowd := _crowd()
	_run(crowd, 5, 12.0)
	_sim.world.building(_houses[1]).tier = &"workers"
	crowd.mark_structure_changed()
	_run(crowd, 5, 2.0)
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.home_id == _houses[1] and not agent.retiring:
			assert_str(agent.tier).is_equal("workers")


func test_instance_walks_along_its_segment_facing_forward() -> void:
	var crowd := _crowd()
	crowd.activity_override = 1.0
	_run(crowd, 30, 12.0)
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.state == Crowd.State.WALKING:
			var xform := crowd.instance_transform(agent)
			var direction := (agent.points[agent.segment + 1] - agent.points[agent.segment]).normalized()
			# o boneco olha para −Z: o −Z da instância aponta para onde ele anda
			assert_vector(-xform.basis.z).is_equal_approx(direction, Vector3.ONE * 0.001)
			var custom := crowd.instance_custom(agent)
			assert_float(custom.b).is_equal_approx(_sim.config.pedestrian_speed_m_s, 0.0001)
			assert_int(int(custom.a)).is_equal(agent.clip)
			return
	fail("ninguém andando")


func test_new_routes_per_frame_respect_the_time_budget() -> void:
	# teto zero: passada a primeira rota nova do quadro, as outras esperam o próximo
	_sim.config.pedestrian_route_budget_ms = 0.0
	var crowd := _crowd()
	crowd.activity_override = 1.0
	var most := 0
	for frame: int in 200:
		var before := crowd.routes_computed
		crowd.update(5.0, 12.0)
		most = maxi(most, crowd.routes_computed - before)
	assert_int(most).is_equal(1)
	assert_int(crowd.visible_count()).is_greater(0)
