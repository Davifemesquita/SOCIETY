extends GdUnitTestSuite
## Fase 10 (polimento): as contas do áudio, a música com os três climas, os efeitos ligados aos
## eventos, o salvamento automático que reveza os slots, as opções novas gravadas e o tutorial
## apontando o botão da meta.

const GAME := "res://ui/screens/game_screen.tscn"

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.get_default()


func test_music_mood_follows_the_match() -> void:
	assert_int(AudioMix.mood(_config, 1000.0, INF, INF)).is_equal(AudioMix.Mood.CALM)
	assert_int(AudioMix.mood(_config, 1000.0, INF, 10.0)).is_equal(AudioMix.Mood.PROGRESS)
	assert_int(AudioMix.mood(_config, 1000.0, 10.0, 10.0)).override_failure_message("falta pesa mais que marco").is_equal(AudioMix.Mood.ALERT)
	assert_int(AudioMix.mood(_config, -5.0, INF, INF)).is_equal(AudioMix.Mood.ALERT)
	assert_int(AudioMix.mood(_config, 1000.0, _config.music_alert_after_shortage_s + 1.0, INF)).is_equal(AudioMix.Mood.CALM)


func test_music_has_three_moods_from_public_domain_tracks() -> void:
	var stream := MusicDirector.build_stream(_config.music_fade_seconds)
	assert_int(stream.clip_count).is_equal(3)
	for index: int in 3:
		assert_str(stream.get_clip_name(index)).is_equal(MusicDirector.CLIP_NAMES[index])
		var playlist := stream.get_clip_stream(index) as AudioStreamPlaylist
		assert_object(playlist).is_not_null()
		assert_int(playlist.stream_count).is_greater(0)
		for track: int in playlist.stream_count:
			assert_object(playlist.get_list_stream(track)).is_not_null()


func test_ambience_follows_the_buildings_and_the_zoom() -> void:
	var counts := PackedFloat32Array([2.0, 0.0, 3.0, 50.0])
	var near := AudioMix.levels(_config, counts, 20.0)
	assert_float(near[AudioMix.Zone.PORT]).is_equal_approx(1.0, 0.001)
	assert_float(near[AudioMix.Zone.FACTORY]).is_equal(0.0)
	assert_float(near[AudioMix.Zone.FIELD]).is_equal_approx(0.5, 0.001)
	assert_float(near[AudioMix.Zone.CITY]).is_equal_approx(1.0, 0.001)
	var far := AudioMix.levels(_config, counts, _config.ambience_far_m + 10.0)
	for level: float in far:
		assert_float(level).is_equal(0.0)
	assert_float(AudioMix.wind_level(_config, 400.0, 0.0)).is_greater(AudioMix.wind_level(_config, 20.0, 0.0))
	var data := GameData.get_default()
	assert_int(AudioMix.zone_of(data.building(&"trading_post"))).is_equal(AudioMix.Zone.PORT)
	assert_int(AudioMix.zone_of(data.building(&"house"))).is_equal(AudioMix.Zone.CITY)
	assert_int(AudioMix.zone_of(data.building(&"field"))).is_equal(AudioMix.Zone.FIELD)
	assert_int(AudioMix.zone_of(data.building(&"furnace"))).is_equal(AudioMix.Zone.FACTORY)


func test_autosave_rotates_through_its_slots() -> void:
	assert_str(Autosave.next_slot(PackedStringArray(), 3)).is_equal("autosave_1")
	assert_str(Autosave.next_slot(PackedStringArray(["autosave_1", "meu_jogo"]), 3)).is_equal("autosave_2")
	# todos ocupados: o mais antigo (a lista vem do mais novo para o mais velho)
	var full := PackedStringArray(["autosave_2", "meu_jogo", "autosave_3", "autosave_1"])
	assert_str(Autosave.next_slot(full, 3)).is_equal("autosave_1")


func test_new_options_are_saved_and_bad_values_fall_back() -> void:
	var before := [Settings.autosave_minutes, Settings.advisor, Settings.camera_speed]
	Settings.autosave_minutes = 5.0
	Settings.advisor = false
	Settings.camera_speed = 1.6
	var path := "user://test_phase10_settings.cfg"
	Settings.save_to(path)
	Settings.autosave_minutes = 10.0
	Settings.advisor = true
	Settings.camera_speed = 1.0
	Settings.load_from(path)
	assert_float(Settings.autosave_minutes).is_equal(5.0)
	assert_bool(Settings.advisor).is_false()
	assert_float(Settings.camera_speed).is_equal_approx(1.6, 0.001)
	var file := ConfigFile.new()
	file.set_value("game", "autosave_minutes", 7.0)
	file.set_value("controls", "camera_speed", 9.0)
	file.save(path)
	Settings.load_from(path)
	assert_float(Settings.autosave_minutes).is_equal(_config.autosave_interval_minutes)
	assert_float(Settings.camera_speed).is_equal(Settings.CAMERA_SPEED_RANGE.y)
	DirAccess.remove_absolute(path)
	Settings.autosave_minutes = before[0]
	Settings.advisor = before[1]
	Settings.camera_speed = before[2]


func test_match_autosaves_plays_effects_and_points_the_goal() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	var saves_before := SaveSystem.save_dir
	SaveSystem.save_dir = "user://test_phase10_saves"
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(3)
	# tutorial: a primeira meta (o entreposto) aponta a aba da infraestrutura
	assert_str(game.hud.hinted_building()).is_equal(&"trading_post")
	assert_int(game.hud.category_of(&"trading_post")).is_equal(game.hud._categories().size() - 1)
	assert_int(game.hud.category_of(&"paved_road")).is_equal(game.hud._categories().size() - 1)
	# efeitos ligados aos eventos
	var sim := game.simulation
	sim.free_build = true
	var built_before: int = game.sound.played.get(&"build", 0)
	sim.execute(PlaceBuildingCommand.new(0, &"trading_post", Vector2i(0, 0), 2))
	assert_int(game.sound.played.get(&"build", 0)).is_equal(built_before + 1)
	EventBus.notice_shown.emit("notice_ship_arrived")
	assert_int(game.sound.played.get(&"ship", 0)).is_greater(0)
	# salvamento automático depois do intervalo de jogo
	var old_minutes := Settings.autosave_minutes
	Settings.autosave_minutes = 5.0
	sim.world.tick += roundi(5.0 * 60.0 * sim.config.ticks_per_second)
	await runner.simulate_frames(2)
	assert_bool(SaveSystem.has_slot("autosave_1")).is_true()
	Settings.autosave_minutes = old_minutes
	for slot: String in SaveSystem.list_slots():
		SaveSystem.delete_slot(slot)
	DirAccess.remove_absolute(SaveSystem.save_dir)
	SaveSystem.save_dir = saves_before
	GameScreen.use_sky3d = true
	GameScreen.flat_world = false
