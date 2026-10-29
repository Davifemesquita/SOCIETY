extends GdUnitTestSuite
## Palmas nos estouros (Fase 85): cada fogo avisa; quem vê a festa perto dele bate palmas olhando para o céu por um
## tempo e volta a olhar o mastro; o estrondo chega atrasado pela distância e as palmas tocam mais altas com mais gente.

const STREET := 6
const STRIDES := [1.4, 1.4, 0.0, 0.0, 0.0]
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


func _mast() -> Vector3:
	return FestivalView.strings_of(_sim, _square)[0][0]


## Anda até haver gente parada vendo a festa.
func _until_watching(crowd: Crowd) -> int:
	for step: int in 400:
		crowd.update(0.5, NIGHT)
		var watching := 0
		for agent: Crowd.Agent in crowd.agents:
			if agent != null and agent.watching and agent.state == Crowd.State.WAITING:
				watching += 1
		if watching >= 3:
			return watching
	return 0


func test_a_burst_makes_the_watchers_clap_and_then_look_back() -> void:
	var crowd := _crowd()
	assert_int(_until_watching(crowd)).is_greater_equal(3)
	var sky := _mast() + Vector3.UP * 30.0
	var clapping := crowd.react_to_burst(SimFixture.ISLAND, sky)
	assert_int(clapping).is_greater(0)
	var cheering: Array[Crowd.Agent] = []
	for agent: Crowd.Agent in crowd.agents:
		if agent != null and agent.clip == Crowd.CLIP_CHEER:
			assert_bool(agent.watching).is_true()
			# começa na palma, depois da reação
			assert_float(agent.phase).is_equal(0.0)
			assert_float(agent.segment_start - crowd.time).is_between(Crowd.REACT_DELAY_S.x, Crowd.REACT_DELAY_S.y)
			assert_float(agent.cheer_until - agent.segment_start).is_between(Crowd.CHEER_SECONDS.x, Crowd.CHEER_SECONDS.y)
			cheering.append(agent)
	assert_int(cheering.size()).is_equal(clapping)
	# quem já bate palmas não recomeça no estouro seguinte
	assert_int(crowd.react_to_burst(SimFixture.ISLAND, sky)).is_less_equal(crowd.agents.size() - clapping)
	for agent: Crowd.Agent in cheering:
		assert_float(agent.segment_start).is_less(agent.cheer_until)
	# passado o tempo das palmas, quem ainda está lá volta a olhar o mastro
	for step: int in 8:
		crowd.update(0.5, NIGHT)
	for agent: Crowd.Agent in cheering:
		if agent.state == Crowd.State.WAITING and agent.watching:
			assert_int(agent.clip).is_equal(Crowd.CLIP_IDLE)
			assert_float(agent.cheer_until).is_equal(0.0)


func test_a_burst_elsewhere_moves_nobody() -> void:
	var crowd := _crowd()
	assert_int(_until_watching(crowd)).is_greater_equal(3)
	var far := _mast() + Vector3(Crowd.REACT_RADIUS_M + 20.0, 30.0, 0.0)
	assert_int(crowd.react_to_burst(SimFixture.ISLAND, far)).is_equal(0)
	assert_int(crowd.react_to_burst(SimFixture.ISLAND + 1, _mast())).is_equal(0)


func test_bang_arrives_late_and_claps_follow() -> void:
	var sounds := FestivalSounds.new()
	add_child(sounds)
	auto_free(sounds)
	sounds.on_burst(Vector3(0.0, 30.0, 0.0), 6)
	sounds.on_burst(Vector3(0.0, 30.0, 0.0), 0)
	# estrondo e palmas no primeiro; só o estrondo no segundo
	assert_int(sounds.pending_count()).is_equal(3)
	assert_float(FestivalSounds.clap_db(1)).is_equal(FestivalSounds.CLAP_QUIET_DB)
	assert_float(FestivalSounds.clap_db(FestivalSounds.CLAP_FULL_PEOPLE)).is_equal(FestivalSounds.CLAP_FULL_DB)
	assert_float(FestivalSounds.clap_db(4)).is_between(FestivalSounds.CLAP_QUIET_DB, FestivalSounds.CLAP_FULL_DB)
	GameClock.set_speed(1)
	sounds._process(FestivalSounds.CLAP_DELAY_S + 0.01)
	assert_int(sounds.played.get(&"bang", 0)).is_equal(2)
	assert_int(sounds.played.get(&"applause", 0)).is_equal(1)
	assert_int(sounds.pending_count()).is_equal(0)


func test_generated_sounds_have_body() -> void:
	for stream: AudioStreamWAV in [FestivalSounds.bang_stream(), FestivalSounds.applause_stream()]:
		assert_int(stream.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
		var loud := 0
		for i: int in range(0, stream.data.size(), 2):
			loud += int(absi(stream.data.decode_s16(i)) > 3000)
		assert_int(loud).is_greater(200)


func test_the_festival_announces_each_burst() -> void:
	var view := FestivalView.new()
	add_child(view)
	auto_free(view)
	view.setup(_sim)
	var heard: Array[int] = []
	view.exploded.connect(func(island_id: int, _at: Vector3) -> void: heard.append(island_id))
	view.launch(view.firework_sites()[0])
	assert_array(heard).is_equal([SimFixture.ISLAND])
