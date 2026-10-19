extends GdUnitTestSuite
## Vento (Fase 22): sai da semente e da hora, mais forte com a chuva e quase parado na neblina; deita a
## fumaça das chaminés e vira as bandeiras de mastro.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.get_default()


func test_the_wind_is_the_same_for_the_same_seed_and_hour_and_turns_slowly() -> void:
	for hours: float in [3.0, 30.5, 77.25]:
		var a := WeatherCycle.sample(1840, hours, _config)
		var b := WeatherCycle.sample(1840, hours, _config)
		assert_float(a.wind).is_equal(b.wind)
		assert_vector(a.wind_direction).is_equal(b.wind_direction)
		assert_float(a.wind_direction.length()).is_equal_approx(1.0, 0.0001)
	# de minuto em minuto a direção e a força quase não mudam, nem na virada do dia (a troca de
	# direção leva as duas últimas horas: no pior caso, meia volta, ~0,04 rad por minuto)
	for hours: float in [10.0, 23.0, 23.95, 24.0, 47.99]:
		var now := WeatherCycle.sample(1840, hours, _config)
		var later := WeatherCycle.sample(1840, hours + 1.0 / 60.0, _config)
		assert_float(absf(now.wind_direction.angle_to(later.wind_direction))).is_less(0.05)
		assert_float(absf(now.wind - later.wind)).is_less(0.02)


func test_each_day_blows_from_its_own_side() -> void:
	var angles := {}
	for day: int in 20:
		angles[snappedf(WeatherCycle.day(1840, day, _config).wind_angle, 0.5)] = true
	assert_int(angles.size()).is_greater(5)


func test_rain_brings_wind_and_mist_calms_it() -> void:
	var rainy := -1
	var today: WeatherCycle.Day
	for index: int in 200:
		today = WeatherCycle.day(1840, index, _config)
		if today.kind == WeatherCycle.Kind.RAIN and today.mist == 0.0:
			rainy = index
			break
	assert_int(rainy).is_not_equal(-1)
	var middle := WeatherCycle.sample(1840, rainy * 24.0 + (today.rain_start + today.rain_end) * 0.5, _config)
	assert_float(middle.wind).is_equal_approx(_config.weather_wind_rain * today.wind_factor, 0.02)
	var misty := -1
	for index: int in 200:
		var day := WeatherCycle.day(1840, index, _config)
		if day.kind == WeatherCycle.Kind.CLEAR and day.mist > 0.8:
			misty = index
			break
	assert_int(misty).is_not_equal(-1)
	var dawn := WeatherCycle.sample(1840, misty * 24.0 + _config.weather_mist_peak_hour, _config)
	var noon := WeatherCycle.sample(1840, misty * 24.0 + 13.0, _config)
	assert_float(dawn.wind).is_less(noon.wind * 0.5)
	assert_float(middle.wind).is_greater(noon.wind)


func test_the_wind_does_not_change_the_sky_each_seed_already_had() -> void:
	# o vento sai do mesmo sorteio do dia, depois do resto: o céu de antes fica igual
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([1840, 5, "clima"])
	var roll := rng.randf()
	var day := WeatherCycle.day(1840, 5, _config)
	var kind := WeatherCycle.Kind.CLEAR
	if roll < _config.weather_rain_chance:
		kind = WeatherCycle.Kind.RAIN
	elif roll < _config.weather_rain_chance + _config.weather_cloudy_chance:
		kind = WeatherCycle.Kind.CLOUDY
	assert_int(day.kind).is_equal(kind)
	assert_float(day.rain_start).is_equal(rng.randf_range(_config.weather_rain_start_hours.x, _config.weather_rain_start_hours.y))


func test_smoke_rises_straight_when_calm_and_leans_downwind() -> void:
	var calm := SmokeView.drift(Vector2.RIGHT, 0.0)
	assert_float(Vector2(calm.x, calm.z).length()).is_equal(0.0)
	assert_float(calm.y).is_greater(0.0)
	var east := SmokeView.drift(Vector2.RIGHT, 1.0)
	assert_float(east.x).is_equal_approx(SmokeView.WIND_PUSH_M_S2, 0.0001)
	var south := SmokeView.drift(Vector2(0.0, 1.0), 0.5)
	assert_float(south.z).is_greater(0.0)
	assert_float(south.z).is_less(east.x)


func test_the_flag_points_downwind_and_droops_when_calm() -> void:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var flag := WindFlag.make(Vector3(2.0, 1.2, 0.05), StandardMaterial3D.new(), Vector3(0.0, 8.0, 0.0))
	root.add_child(flag)
	assert_object(flag.get_node_or_null(^"Cloth")).is_not_null()
	assert_bool(flag.is_in_group(WindFlag.GROUP)).is_true()
	for direction: Vector2 in [Vector2.RIGHT, Vector2(0.0, 1.0), Vector2(-0.6, -0.8)]:
		flag.blow(direction, 1.0, 0.0)
		var out := flag.global_basis.x.normalized()
		assert_float(Vector2(out.x, out.z).normalized().dot(direction)).override_failure_message(str(direction)).is_greater(0.97)
		assert_float(absf(out.y)).is_less(0.05)
	flag.blow(Vector2.RIGHT, 0.0, 0.0)
	assert_float(flag.global_basis.x.normalized().y).is_less(-0.8)
	assert_float(flag.global_basis.x.length()).is_equal_approx(WindFlag.LIMP_WIDTH, 0.001)
	# a beira presa no mastro continua em pé
	assert_vector(flag.global_basis.y).is_equal_approx(Vector3.UP, Vector3.ONE * 0.001)


func test_the_flag_flutters_only_with_wind() -> void:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var flag := WindFlag.make(Vector3(2.0, 1.2, 0.05), StandardMaterial3D.new(), Vector3.ZERO)
	root.add_child(flag)
	flag.blow(Vector2.RIGHT, 0.0, 0.0)
	var still := flag.global_basis
	flag.blow(Vector2.RIGHT, 0.0, 0.3)
	assert_bool(flag.global_basis.is_equal_approx(still)).is_true()
	flag.blow(Vector2.RIGHT, 1.0, 0.0)
	var a := flag.global_basis.x
	flag.blow(Vector2.RIGHT, 1.0, 0.15)
	assert_float(a.angle_to(flag.global_basis.x)).is_greater(0.01)


func test_the_trading_post_flag_is_a_wind_flag() -> void:
	var post: Node3D = auto_free(TraderPostModel.build())
	assert_object(post.get_node(^"Flag")).is_instanceof(WindFlag)


func test_crops_and_grass_sway_in_the_wind_but_fences_and_furrows_do_not() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 20))
	var view: CropView = auto_free(CropView.new())
	add_child(view)
	view.setup(sim)
	var foliage := "res://shaders/foliage.gdshader"
	for child: Node in view.get_children():
		var layer := child as MultiMeshInstance3D
		if layer == null:
			continue
		var material := layer.material_override as ShaderMaterial
		var sways := material != null and material.shader.resource_path == foliage
		var expected := layer.name.begins_with("Crop") or layer.name == "Grass"
		assert_bool(sways).override_failure_message(layer.name).is_equal(expected)
		if sways:
			assert_bool(material.get_shader_parameter(&"use_vertex_color")).is_true()
			var height: float = material.get_shader_parameter(&"model_height")
			assert_float(height).is_equal_approx(layer.multimesh.mesh.get_aabb().end.y, 0.06)
	var roads: RoadView = auto_free(RoadView.new())
	add_child(roads)
	roads.setup(sim, sim.config.cell_size_m)
	var verge := (roads.get_node(^"Verge") as MultiMeshInstance3D).material_override as ShaderMaterial
	assert_str(verge.shader.resource_path).is_equal(foliage)


func test_the_weather_publishes_the_wind_to_the_shaders() -> void:
	var foliage := load("res://shaders/foliage.gdshader") as Shader
	var names: Array[StringName] = []
	for uniform: Dictionary in foliage.get_shader_uniform_list():
		var uniform_name: String = uniform["name"]
		names.append(StringName(uniform_name))
	for wanted: StringName in [&"sway", &"calm", &"lean", &"use_vertex_color"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
	for global_name: String in ["wind_direction", "wind_strength"]:
		assert_bool(ProjectSettings.has_setting("shader_globals/" + global_name)).override_failure_message(global_name).is_true()
