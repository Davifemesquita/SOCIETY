extends GdUnitTestSuite
## Festa cheia (Fase 81): com a festa na ilha, vêm mais turistas para a rua, na mesma proporção da renda do turismo
## (1 + tourism_festival_bonus), com o teto subindo junto; acabou a festa, voltam ao normal. Só visual.

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


func _run(crowd: Crowd, seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		crowd.update(0.5, 12.0)
		left -= 0.5


func _festival() -> WorldEvent:
	var event := WorldEvent.new()
	event.def = _sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = SimFixture.ISLAND
	event.ends_tick = _sim.world.tick + 100000
	return event


func test_the_festival_brings_more_tourists() -> void:
	var crowd := _crowd()
	_run(crowd, 3.0)
	var normal := crowd.tourist_count()
	assert_int(normal).is_greater(0)
	assert_bool(TourismSystem.has_festival(_sim.world, SimFixture.ISLAND)).is_false()
	var event := _festival()
	_sim.world.events_state.events.append(event)
	assert_bool(TourismSystem.has_festival(_sim.world, SimFixture.ISLAND)).is_true()
	_run(crowd, 3.0)
	var points: float = _sim.derived_state().attractiveness[SimFixture.ISLAND]
	var factor := 1.0 + _sim.config.tourism_festival_bonus
	var expected := mini(roundi(_sim.config.max_tourists_per_island * factor), floori(points * _sim.config.tourists_per_point * factor))
	assert_int(crowd.tourist_count()).is_equal(expected)
	assert_int(crowd.tourist_count()).is_greater(normal)
	# a festa acabou: os que sobram vão embora quando chegam
	_sim.world.events_state.events.erase(event)
	_run(crowd, 300.0)
	assert_int(crowd.tourist_count()).is_equal(normal)


func test_the_cap_grows_with_the_festival() -> void:
	_sim.config.max_tourists_per_island = 2
	var crowd := _crowd()
	_run(crowd, 3.0)
	assert_int(crowd.tourist_count()).is_equal(2)
	_sim.world.events_state.events.append(_festival())
	_run(crowd, 3.0)
	assert_int(crowd.tourist_count()).is_equal(roundi(2 * (1.0 + _sim.config.tourism_festival_bonus)))
