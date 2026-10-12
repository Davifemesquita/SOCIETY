extends GdUnitTestSuite
## Critério da Fase 4 (seção 16): 2.000 pedestres com a carga do benchmark (10 mil moradores) e o
## ciclo do dia. O FPS da meta só se mede no PC alvo (tools/benchmark.tscn); aqui, a conta da
## multidão: quantos, todos na rua quando a hora pede, e o custo dela na CPU.


func test_ten_thousand_residents_give_two_thousand_pedestrians_on_the_street() -> void:
	var config := GameConfig.new()
	config.instant_logistics = true
	config.pedestrian_door_seconds = Vector2.ZERO
	var sim := Simulation.new(config, GameData.get_default())
	var houses := TownLayout.build(sim, 500, &"house", Vector2i(2, 2))
	for house_id: int in houses:
		var house := sim.world.building(house_id)
		house.tier = &"workers"
		house.residents = 20.0
	# mercados logo abaixo das casas, na mesma rede de estrada
	var markets := TownLayout.build(sim, 12, &"market", Vector2i(2, 32))
	assert_int(markets.size()).is_equal(12)
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(2, 30), Vector2i(2, 32))))
	var strides: Array[PackedFloat32Array] = [PackedFloat32Array([1.4, 1.4, 0, 0]), PackedFloat32Array([1.4, 1.4, 0, 0])]
	var crowd := Crowd.new(sim, config, strides, 5)
	crowd.activity_override = 1.0
	crowd.update(0.01, 12.0)
	assert_int(crowd.agent_count()).is_equal(config.max_visible_pedestrians)
	var started := Time.get_ticks_usec()
	var frames := 0
	for frame: int in 600:
		crowd.update(1.0 / 60.0, 12.0)
		crowd.take_changes()
		frames += 1
	var per_frame_ms := (Time.get_ticks_usec() - started) / 1000.0 / frames
	print("multidão: %d pedestres, %d à vista, %.2f ms por quadro na CPU" % [crowd.agent_count(), crowd.visible_count(), per_frame_ms])
	assert_int(crowd.visible_count()).is_greater(roundi(config.max_visible_pedestrians * 0.9))


func test_a_full_day_turns_in_six_real_minutes_at_4x() -> void:
	var config := GameConfig.new()
	var clock := TickClock.new(config)
	clock.set_speed(2)
	var nights := 0
	var was_night := false
	for second: int in 6 * 60:
		clock.advance(1.0)
		var night := DayClock.night_factor(config, clock.hour()) > 0.5
		nights += int(night and not was_night)
		was_night = night
	assert_int(clock.day_number()).is_equal(2)
	assert_float(clock.hour()).is_equal_approx(7.0, 0.01)
	assert_int(nights).is_equal(1)
