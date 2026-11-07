extends GdUnitTestSuite
## Foguete e assobio (Fase 86): o fogo sobe do alto do mastro e só estoura lá em cima, onde a subida acaba; o assobio
## segue o foguete e cala no estouro; o estrondo ganha o eco.

var _sim: Simulation
var _view: FestivalView
var _bursts: Array[Vector3] = []
var _launches: Array[Array] = []


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true
	SimFixture.port(_sim)
	SimFixture.place(_sim, &"fountain_square", Vector2i(40, 7), 0)
	_sim.world.events_state.enabled = true
	_sim.world.events_state.next_edition_tick = 999_999_999
	var event := WorldEvent.new()
	event.def = _sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = SimFixture.ISLAND
	event.ends_tick = _sim.world.tick + 100000
	_sim.world.events_state.events.append(event)
	_view = FestivalView.new()
	add_child(_view)
	_view.setup(_sim)
	_bursts.clear()
	_launches.clear()
	_view.exploded.connect(func(_island: int, at: Vector3) -> void: _bursts.append(at))
	_view.launched.connect(func(island: int, from: Vector3, to: Vector3, rise_s: float) -> void:
		_launches.append([island, from, to, rise_s]))


func after_test() -> void:
	_view.free()


func test_the_rocket_rises_from_the_mast_and_bursts_at_the_top() -> void:
	var site := _view.firework_sites()[0]
	assert_bool(_view.fire(site)).is_true()
	assert_int(_view.rockets_flying()).is_equal(1)
	assert_int(_launches.size()).is_equal(1)
	var launch: Array = _launches[0]
	var to: Vector3 = launch[2]
	var rise_s: float = launch[3]
	assert_int(launch[0]).is_equal(SimFixture.ISLAND)
	var from: Vector3 = launch[1]
	assert_bool(from.is_equal_approx(site)).is_true()
	assert_float(to.y - site.y).is_between(FestivalView.FIREWORK_HEIGHT_M.x, FestivalView.FIREWORK_HEIGHT_M.y)
	assert_float(rise_s).is_between(FestivalView.ROCKET_RISE_S.x, FestivalView.ROCKET_RISE_S.y)
	# no meio da subida ainda não estourou, e já está bem acima do mastro
	_view.advance_rockets(rise_s * 0.5)
	assert_array(_bursts).is_empty()
	var shown := _view.get_children().filter(func(node: Node) -> bool: return node.name.begins_with("Rocket") and (node as Node3D).visible)
	assert_int(shown.size()).is_equal(1)
	var rocket: Node3D = shown[0]
	assert_float(rocket.position.y).is_greater(site.y + (to.y - site.y) * 0.5)
	# no alto, estoura onde a subida acabou
	_view.advance_rockets(rise_s * 0.6)
	assert_int(_bursts.size()).is_equal(1)
	assert_bool(_bursts[0].is_equal_approx(to)).is_true()
	assert_int(_view.rockets_flying()).is_equal(0)
	assert_bool(rocket.visible).is_false()


func test_the_climb_starts_fast_and_ends_at_the_burst() -> void:
	var rocket := FestivalView.Rocket.new()
	rocket.from = Vector3(0.0, 10.0, 0.0)
	rocket.to = Vector3(5.0, 45.0, 3.0)
	rocket.wobble = Vector2(1.0, 3.0)
	assert_bool(FestivalView.rocket_point(rocket, 0.0).is_equal_approx(rocket.from)).is_true()
	assert_bool(FestivalView.rocket_point(rocket, 1.0).is_equal_approx(rocket.to)).is_true()
	var last := rocket.from.y
	var first_half := FestivalView.rocket_point(rocket, 0.5).y - rocket.from.y
	assert_float(first_half).is_greater((rocket.to.y - rocket.from.y) * 0.5)
	for step: int in range(1, 11):
		var y := FestivalView.rocket_point(rocket, step / 10.0).y
		assert_float(y).is_greater(last)
		last = y


func test_no_free_rocket_no_launch() -> void:
	var site := _view.firework_sites()[0]
	for i: int in FestivalView.ROCKET_POOL:
		assert_bool(_view.fire(site)).is_true()
	assert_bool(_view.fire(site)).is_false()
	assert_int(_launches.size()).is_equal(FestivalView.ROCKET_POOL)


func test_the_whistle_follows_the_rocket_and_stops_at_the_burst() -> void:
	var sounds := FestivalSounds.new()
	add_child(sounds)
	auto_free(sounds)
	sounds.on_launch(Vector3.ZERO, Vector3(0.0, 30.0, 0.0), 1.0)
	assert_int(sounds.played.get(&"whistle", 0)).is_equal(1)
	assert_int(sounds.flights_count()).is_equal(1)
	sounds._follow_flights(0.5, false)
	assert_int(sounds.flights_count()).is_equal(1)
	sounds._follow_flights(0.6, false)
	assert_int(sounds.flights_count()).is_equal(0)
	# com o jogo parado o assobio não anda
	sounds.on_launch(Vector3.ZERO, Vector3(0.0, 30.0, 0.0), 1.0)
	sounds._follow_flights(0.0, true)
	assert_int(sounds.flights_count()).is_equal(1)


func test_the_whistle_has_body() -> void:
	var stream := FestivalSounds.whistle_stream()
	assert_float(stream.get_length()).is_equal_approx(FestivalSounds.WHISTLE_S, 0.01)
	var loud := 0
	for i: int in range(0, stream.data.size(), 2):
		loud += int(absi(stream.data.decode_s16(i)) > 3000)
	assert_int(loud).is_greater(stream.data.size() / 8)
