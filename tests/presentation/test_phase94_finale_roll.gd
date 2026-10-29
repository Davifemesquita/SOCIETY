extends GdUnitTestSuite
## Rufar e câmera do grand finale (Fase 94): a salva começa com o rufar na praça e o primeiro foguete espera ele acabar;
## com a opção ligada, a câmera vai à praça; desligada (o padrão), fica onde está.

const SettingsScript := preload("res://core/settings.gd")

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


func test_the_finale_starts_with_the_roll_at_the_square() -> void:
	var sites: Array[Vector3] = []
	_view.finale_started.connect(func(site: Vector3) -> void: sites.append(site))
	var sounds := FestivalSounds.new()
	add_child(sounds)
	auto_free(sounds)
	_view.finale_started.connect(sounds.on_finale)
	_view.start_finale()
	assert_int(sites.size()).is_equal(1)
	assert_bool(sites[0].is_equal_approx(_view.firework_sites()[0])).is_true()
	assert_int(sounds.played.get(&"roll", 0)).is_equal(1)
	# o primeiro foguete só sobe quando o rufar acaba
	_view.advance_finale(FestivalView.FINALE_ROLL_S * 0.9)
	assert_int(_view.rockets_flying()).is_equal(0)
	_view.advance_finale(FestivalView.FINALE_ROLL_S * 0.2)
	assert_int(_view.rockets_flying()).is_equal(1)


func test_the_roll_lasts_as_long_as_the_wait_and_speeds_up() -> void:
	assert_float(FestivalSounds.ROLL_S).is_equal(FestivalView.FINALE_ROLL_S)
	var stream := FestivalSounds.roll_stream()
	assert_float(stream.get_length()).is_greater(FestivalSounds.ROLL_S)
	# a segunda metade tem mais som que a primeira (as batidas apertam e sobem)
	var half := roundi(FestivalSounds.ROLL_S * FestivalSounds.RATE * 0.5)
	var first := 0.0
	var second := 0.0
	for i: int in half:
		first += absf(stream.data.decode_s16(i * 2))
		second += absf(stream.data.decode_s16((half + i) * 2))
	assert_float(second).is_greater(first * 1.5)


func test_the_camera_option_is_off_by_default_and_saved() -> void:
	var fresh: SettingsScript = auto_free(SettingsScript.new())
	assert_bool(fresh.finale_camera).is_false()
	var path := "user://test_finale_camera.cfg"
	var settings: SettingsScript = auto_free(SettingsScript.new())
	settings.finale_camera = true
	assert_int(settings.save_to(path)).is_equal(OK)
	var loaded: SettingsScript = auto_free(SettingsScript.new())
	loaded.load_from(path)
	assert_bool(loaded.finale_camera).is_true()
	DirAccess.remove_absolute(path)
