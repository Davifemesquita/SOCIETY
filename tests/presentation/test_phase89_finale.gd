extends GdUnitTestSuite
## Grand finale (Fase 89): às 23h de cada noite de festa, uma salva de foguetes nas formas da lista, um atrás do outro,
## acabando na chuva dourada; uma vez por noite, rearmada de dia; durante a salva os fogos de sempre esperam.

const NIGHT_BEFORE := 21.0

var _sim: Simulation
var _view: FestivalView
var _launches: int = 0
var _shapes: Array[int] = []
var _finales: int = 0


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
	_launches = 0
	_shapes.clear()
	_finales = 0
	_view.launched.connect(func(_island: int, _from: Vector3, _to: Vector3, _rise: float) -> void: _launches += 1)
	_view.exploded.connect(func(_island: int, _at: Vector3) -> void: _shapes.append(_view.last_shape))
	_view.finale_started.connect(func() -> void: _finales += 1)


func after_test() -> void:
	_view.free()


## Anda a salva e os foguetes no ar até a salva acabar e o último estourar.
func _play_finale() -> void:
	for step: int in 400:
		_view.advance_finale(0.1)
		_view.advance_rockets(0.1)
		if _view.finale_left() == 0 and _view.rockets_flying() == 0:
			return


func test_the_finale_fires_the_whole_list_in_order() -> void:
	_view.start_finale()
	assert_int(_finales).is_equal(1)
	assert_int(_view.finale_left()).is_equal(FestivalView.FINALE_SHAPES.size())
	_play_finale()
	assert_int(_view.finale_left()).is_equal(0)
	assert_int(_launches).is_equal(FestivalView.FINALE_SHAPES.size())
	# todas estouraram, nas formas da lista; a salva acaba na chuva dourada
	assert_int(_shapes.size()).is_equal(FestivalView.FINALE_SHAPES.size())
	var sorted_shapes := _shapes.duplicate()
	sorted_shapes.sort()
	var expected := FestivalView.FINALE_SHAPES.duplicate()
	expected.sort()
	assert_array(sorted_shapes).is_equal(expected)
	assert_int(_shapes[_shapes.size() - 1]).is_equal(FestivalView.Shape.WILLOW)


func test_the_finale_is_quick_but_not_all_at_once() -> void:
	_view.start_finale()
	_view.advance_finale(0.0)
	assert_int(_launches).is_equal(1)
	# em poucos segundos sai a salva toda (sem esperar os estouros)
	var seconds := 0.0
	while _view.finale_left() > 0 and seconds < 30.0:
		_view.advance_finale(0.05)
		_view.advance_rockets(0.05)
		seconds += 0.05
	assert_float(seconds).is_less(FestivalView.FINALE_SHAPES.size() * FestivalView.FINALE_GAP_S.y + 3.0)
	assert_float(seconds).is_greater(FestivalView.FINALE_SHAPES.size() * FestivalView.FINALE_GAP_S.x * 0.5)


func test_once_a_night_at_eleven() -> void:
	GameClock.set_speed(1)
	var clock := GameClock.clock
	_set_hour(NIGHT_BEFORE)
	_view._process(0.016)
	assert_int(_finales).is_equal(0)
	_set_hour(FestivalView.FINALE_HOUR + 0.1)
	_view._process(0.016)
	assert_int(_finales).is_equal(1)
	_play_finale()
	# a mesma noite não repete
	_set_hour(FestivalView.FINALE_HOUR + 0.5)
	_view._process(0.016)
	assert_int(_finales).is_equal(1)
	# de dia rearma; na noite seguinte, outra
	_set_hour(12.0)
	_view._process(0.016)
	_set_hour(FestivalView.FINALE_HOUR + 0.1)
	_view._process(0.016)
	assert_int(_finales).is_equal(2)
	clock.extra_hours = 0.0


func test_regular_fireworks_wait_during_the_finale() -> void:
	_view.start_finale()
	assert_bool(_view.advance_finale(0.01)).is_true()
	_play_finale()
	assert_bool(_view.advance_finale(0.01)).is_false()


## Na salva cada estouro pega pouca gente nova: as vivas seguem quantos ainda batem palmas.
func test_the_cheer_follows_everyone_still_clapping() -> void:
	var sounds := FestivalSounds.new()
	add_child(sounds)
	auto_free(sounds)
	GameClock.set_speed(1)
	# um só reagiu a este estouro, mas seis ainda batem palmas pelos de antes
	sounds.on_burst(Vector3(0.0, 20.0, 0.0), 1, 6)
	sounds._process(FestivalSounds.CLAP_DELAY_S + 0.01)
	assert_int(sounds.played.get(&"cheer", 0)).is_equal(1)
	assert_float(sounds.cheer_level).is_greater(0.0)
	# e ninguém batendo: sem vivas
	var before: int = sounds.played.get(&"cheer", 0)
	sounds.on_burst(Vector3(0.0, 20.0, 0.0), 1, 1)
	sounds._process(FestivalSounds.ECHO_DELAY_S + 0.01)
	assert_int(sounds.played.get(&"cheer", 0)).is_equal(before)


func test_the_crowd_counts_who_is_clapping() -> void:
	for x: int in [26, 30, 34, 50, 54]:
		SimFixture.house_on_main_road(_sim, x, &"peasants", 10.0)
	var strides: Array[PackedFloat32Array] = [PackedFloat32Array([1.4, 1.4, 0.0, 0.0, 0.0]),
			PackedFloat32Array([1.4, 1.4, 0.0, 0.0, 0.0])]
	var crowd := Crowd.new(_sim, _sim.config, strides, 4)
	crowd.activity_override = 1.0
	var mast := _view.firework_sites()[0]
	var reacted := 0
	for step: int in 400:
		crowd.update(0.5, 0.0)
		reacted = crowd.react_to_burst(SimFixture.ISLAND, mast + Vector3.UP * 18.0)
		if reacted >= 2:
			break
	assert_int(reacted).is_greater_equal(2)
	assert_int(crowd.cheering_count()).is_greater_equal(reacted)
	# passado o tempo das palmas, ninguém
	for step: int in 8:
		crowd.update(0.5, 0.0)
	assert_int(crowd.cheering_count()).is_equal(0)


func _set_hour(hour: float) -> void:
	var clock := GameClock.clock
	clock.extra_hours = 0.0
	clock.extra_hours = fposmod(hour - clock.hour(), 24.0)
