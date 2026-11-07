extends GdUnitTestSuite
## Duas etapas e vivas calmas (Fase 88): a bomba de duas etapas solta poucas estrelas que estouram de novo no fim, na
## segunda cor, e as outras formas não usam o sub-emissor; as vivas calmas tocam com pouca gente e a forte com muita.


func test_the_double_burst_bursts_again_at_the_end() -> void:
	var burst := FestivalView._burst()
	auto_free(burst)
	var process := burst.process_material as ParticleProcessMaterial
	var sub := burst.get_node("Sub") as GPUParticles3D
	assert_object(sub).is_not_null()
	assert_str(str(burst.sub_emitter)).is_equal("Sub")
	assert_int(sub.amount).is_greater_equal(FestivalView.DOUBLE_STARS * FestivalView.DOUBLE_SPARKS)
	var blue := Color(0.2, 0.4, 1.0)
	FestivalView.shape_burst(burst, FestivalView.Shape.DOUBLE, Color.RED, blue, Vector3.UP)
	assert_int(burst.amount).is_equal(FestivalView.DOUBLE_STARS)
	assert_int(process.sub_emitter_mode).is_equal(ParticleProcessMaterial.SUB_EMITTER_AT_END)
	assert_int(process.sub_emitter_amount_at_end).is_equal(FestivalView.DOUBLE_SPARKS)
	var sub_fade := ((sub.process_material as ParticleProcessMaterial).color_ramp as GradientTexture1D).gradient
	assert_bool(Color(sub_fade.get_color(0), 1.0).is_equal_approx(blue)).is_true()
	# as outras formas desligam o sub-emissor
	for shape: int in [FestivalView.Shape.PEONY, FestivalView.Shape.CHRYSANTHEMUM, FestivalView.Shape.WILLOW,
			FestivalView.Shape.RING]:
		FestivalView.shape_burst(burst, shape, Color.RED, blue, Vector3.UP)
		assert_int(process.sub_emitter_mode).is_equal(ParticleProcessMaterial.SUB_EMITTER_DISABLED)


func test_the_double_burst_comes_up_in_the_draw() -> void:
	var seen := false
	for i: int in 1000:
		seen = seen or FestivalView.pick_shape((i + 0.5) / 1000.0) == FestivalView.Shape.DOUBLE
	assert_bool(seen).is_true()


func test_the_soft_cheer_gives_way_to_the_strong_one() -> void:
	assert_float(FestivalSounds.cheer_mix(0.0)).is_equal(0.0)
	assert_float(FestivalSounds.cheer_mix(FestivalSounds.CHEER_MIX_FROM)).is_equal(0.0)
	assert_float(FestivalSounds.cheer_mix(FestivalSounds.CHEER_MIX_TO)).is_equal(1.0)
	var middle := FestivalSounds.cheer_mix((FestivalSounds.CHEER_MIX_FROM + FestivalSounds.CHEER_MIX_TO) * 0.5)
	assert_float(middle).is_between(0.3, 0.7)
	# pouca gente fica na calma; muita, na forte
	assert_float(FestivalSounds.cheer_mix(FestivalSounds.cheer_share(FestivalSounds.CHEER_MIN_PEOPLE))).is_equal(0.0)
	assert_float(FestivalSounds.cheer_mix(FestivalSounds.cheer_share(FestivalSounds.CLAP_FULL_PEOPLE))).is_equal(1.0)


func test_both_recordings_are_there() -> void:
	for path: String in [FestivalSounds.CHEER_SOFT_PATH, FestivalSounds.CHEER_PATH]:
		var recording := load(path) as AudioStreamMP3
		assert_object(recording).is_not_null()
		assert_float(recording.get_length()).is_greater(5.0)
