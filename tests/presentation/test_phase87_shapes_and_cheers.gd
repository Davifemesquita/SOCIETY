extends GdUnitTestSuite
## Formas e vivas (Fase 87): o estouro sorteia bola, crisântemo, salgueiro ou anel, cada um com o seu jeito; e as vivas do
## povo (gravação em laço) sobem a cada estouro com gente reagindo e somem devagar.

var _sim: Simulation
var _view: FestivalView


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


func after_test() -> void:
	_view.free()


func test_the_draw_follows_the_weights() -> void:
	var counts := PackedInt32Array([0, 0, 0, 0])
	for i: int in 1000:
		counts[FestivalView.pick_shape((i + 0.5) / 1000.0)] += 1
	var total := 0.0
	for weight: float in FestivalView.SHAPE_WEIGHTS:
		total += weight
	for shape: int in counts.size():
		assert_int(counts[shape]).is_between(roundi(1000.0 * FestivalView.SHAPE_WEIGHTS[shape] / total) - 2,
				roundi(1000.0 * FestivalView.SHAPE_WEIGHTS[shape] / total) + 2)


func test_each_shape_has_its_own_burst() -> void:
	var burst := FestivalView._burst()
	auto_free(burst)
	var process := burst.process_material as ParticleProcessMaterial
	var red := Color(1.0, 0.2, 0.2)
	var blue := Color(0.2, 0.4, 1.0)
	FestivalView.shape_burst(burst, FestivalView.Shape.PEONY, red, blue, Vector3.UP)
	var peony_life := burst.lifetime
	var peony_amount := burst.amount
	assert_int(process.emission_shape).is_equal(ParticleProcessMaterial.EMISSION_SHAPE_POINT)
	# o crisântemo é mais denso e muda de cor
	FestivalView.shape_burst(burst, FestivalView.Shape.CHRYSANTHEMUM, red, blue, Vector3.UP)
	assert_int(burst.amount).is_greater(peony_amount)
	var fade := (process.color_ramp as GradientTexture1D).gradient
	assert_bool(Color(fade.get_color(0), 1.0).is_equal_approx(red)).is_true()
	assert_bool(Color(fade.get_color(1), 1.0).is_equal_approx(blue)).is_true()
	# o salgueiro é dourado, dura mais, sai devagar e cai mais
	FestivalView.shape_burst(burst, FestivalView.Shape.WILLOW, red, blue, Vector3.UP)
	assert_float(burst.lifetime).is_greater(peony_life)
	assert_float(process.initial_velocity_max).is_less(9.0)
	assert_float(process.gravity.y).is_less(-4.0)
	assert_bool(Color(fade.get_color(0), 1.0).is_equal_approx(FestivalView.WILLOW_COLOR)).is_true()
	# o anel abre num plano, saindo do círculo
	var axis := Vector3(0.3, 1.0, 0.1).normalized()
	FestivalView.shape_burst(burst, FestivalView.Shape.RING, red, blue, axis)
	assert_int(process.emission_shape).is_equal(ParticleProcessMaterial.EMISSION_SHAPE_RING)
	assert_bool(process.emission_ring_axis.is_equal_approx(axis)).is_true()
	assert_float(process.radial_velocity_min).is_greater(0.0)
	assert_float(process.initial_velocity_max).is_equal(0.0)
	# e volta a bola sem sobra do anel
	FestivalView.shape_burst(burst, FestivalView.Shape.PEONY, red, blue, Vector3.UP)
	assert_int(process.emission_shape).is_equal(ParticleProcessMaterial.EMISSION_SHAPE_POINT)
	assert_float(process.radial_velocity_max).is_equal(0.0)


func test_the_show_mixes_the_shapes() -> void:
	var seen: Dictionary[int, bool] = {}
	var site := _view.firework_sites()[0]
	for i: int in 60:
		_view.burst_at(site, site + Vector3.UP * 30.0)
		seen[_view.last_shape] = true
		_view.advance_rockets(0.0)
		for node: Node in _view.get_children():
			if node is GPUParticles3D:
				(node as GPUParticles3D).emitting = false
	assert_int(seen.size()).is_equal(FestivalView.Shape.size())


func test_the_cheer_swells_with_the_crowd_and_fades() -> void:
	assert_float(FestivalSounds.cheer_share(FestivalSounds.CHEER_MIN_PEOPLE - 1)).is_equal(0.0)
	assert_float(FestivalSounds.cheer_share(FestivalSounds.CHEER_MIN_PEOPLE)).is_greater(0.0)
	assert_float(FestivalSounds.cheer_share(FestivalSounds.CLAP_FULL_PEOPLE)).is_equal(1.0)
	var sounds := FestivalSounds.new()
	add_child(sounds)
	auto_free(sounds)
	# poucos reagindo: palmas, sem vivas
	sounds.on_burst(Vector3(0.0, 30.0, 0.0), FestivalSounds.CHEER_MIN_PEOPLE - 1)
	GameClock.set_speed(1)
	sounds._process(FestivalSounds.ECHO_DELAY_S + 0.01)
	assert_int(sounds.played.get(&"cheer", 0)).is_equal(0)
	assert_float(sounds.cheer_level).is_equal(0.0)
	# muitos: as vivas sobem ao nível da gente
	sounds.on_burst(Vector3(0.0, 30.0, 0.0), FestivalSounds.CLAP_FULL_PEOPLE)
	sounds._process(FestivalSounds.CLAP_DELAY_S + 0.01)
	assert_int(sounds.played.get(&"cheer", 0)).is_equal(1)
	assert_float(sounds.cheer_level).is_greater(0.9)
	# um estouro com menos gente não baixa o que já está alto (só o sumiço do tempo que passou)
	sounds.on_burst(Vector3(0.0, 30.0, 0.0), FestivalSounds.CHEER_MIN_PEOPLE)
	sounds._process(FestivalSounds.CLAP_DELAY_S + 0.01)
	assert_float(sounds.cheer_level).is_greater(FestivalSounds.cheer_share(FestivalSounds.CHEER_MIN_PEOPLE) + 0.2)
	# parado, não some; andando, some
	var before := sounds.cheer_level
	sounds.fade_cheer(0.0, true)
	assert_float(sounds.cheer_level).is_equal(before)
	sounds.fade_cheer(1.0 / FestivalSounds.CHEER_FADE_PER_S + 0.1, false)
	assert_float(sounds.cheer_level).is_equal(0.0)


func test_the_recording_is_there() -> void:
	var recording := load(FestivalSounds.CHEER_PATH) as AudioStreamMP3
	assert_object(recording).is_not_null()
	assert_float(recording.get_length()).is_greater(5.0)
