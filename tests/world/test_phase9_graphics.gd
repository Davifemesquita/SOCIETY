extends GdUnitTestSuite
## Fase 9 (gráficos finais): os quatro níveis gráficos e as opções, o ambiente de cada nível, o
## clima determinístico, a fumaça das fábricas, as nuvens fora do renderizador por software, o
## casco dos navios e o material dos prédios.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.get_default()


func test_four_presets_from_light_to_heavy() -> void:
	var ids: Array[StringName] = []
	for preset: GraphicsPresetDef in _config.graphics_presets:
		ids.append(preset.id)
		assert_array(Array(preset.validate())).is_empty()
		assert_str(tr(preset.name_key)).is_not_equal(preset.name_key)
	assert_array(ids).is_equal([&"low", &"medium", &"high", &"ultra"])
	assert_int(_config.default_graphics_preset).is_equal(2)
	for index: int in range(1, _config.graphics_presets.size()):
		var lighter := _config.graphics_presets[index - 1]
		var heavier := _config.graphics_presets[index]
		assert_float(heavier.shadow_distance_m).is_greater(lighter.shadow_distance_m)
		assert_float(heavier.particles_ratio).is_greater_equal(lighter.particles_ratio)
		assert_float(heavier.visibility_scale).is_greater_equal(lighter.visibility_scale)
		assert_float(heavier.pedestrian_ratio).is_greater_equal(lighter.pedestrian_ratio)
	assert_bool(_config.graphics_presets[0].ssao).is_false()
	assert_bool(_config.graphics_presets[2].ssil).is_true()
	assert_bool(_config.graphics_presets[2].volumetric_fog).is_true()


func test_choosing_a_preset_suggests_the_resolution_scale_and_is_saved() -> void:
	var before := Settings.graphics_preset
	var before_scale := Settings.render_scale
	Settings.set_graphics_preset(0)
	assert_float(Settings.render_scale).is_equal_approx(_config.graphics_presets[0].render_scale, 0.001)
	var path := "user://test_phase9_settings.cfg"
	Settings.save_to(path)
	Settings.set_graphics_preset(3)
	Settings.load_from(path)
	assert_int(Settings.graphics_preset).is_equal(0)
	var file := ConfigFile.new()
	file.set_value("graphics", "preset", 99)
	file.save(path)
	Settings.load_from(path)
	assert_int(Settings.graphics_preset).is_equal(_config.default_graphics_preset)
	DirAccess.remove_absolute(path)
	Settings.graphics_preset = before
	Settings.render_scale = before_scale


func test_each_preset_sets_the_environment() -> void:
	for preset: GraphicsPresetDef in _config.graphics_presets:
		var environment := Environment.new()
		GraphicsQuality.apply_to_environment(environment, preset, _config)
		assert_int(environment.tonemap_mode).is_equal(Environment.TONE_MAPPER_AGX)
		assert_bool(environment.ssao_enabled).is_equal(preset.ssao)
		assert_bool(environment.ssil_enabled).is_equal(preset.ssil)
		assert_bool(environment.glow_enabled).is_equal(preset.glow)
		assert_bool(environment.volumetric_fog_enabled).is_equal(preset.volumetric_fog)


func test_weather_is_the_same_for_the_same_seed_and_hour() -> void:
	for hours: float in [3.0, 30.5, 200.25, 1000.0]:
		var a := WeatherCycle.sample(1840, hours, _config)
		var b := WeatherCycle.sample(1840, hours, _config)
		assert_float(a.coverage).is_equal(b.coverage)
		assert_float(a.rain).is_equal(b.rain)
		assert_float(a.mist).is_equal(b.mist)
		assert_float(a.wetness).is_equal(b.wetness)
	var differs := false
	for day: int in 30:
		differs = differs or WeatherCycle.day(1840, day, _config).kind != WeatherCycle.day(7, day, _config).kind
	assert_bool(differs).override_failure_message("outra semente, outro clima").is_true()


func test_weather_mix_follows_the_chances() -> void:
	var counts := {WeatherCycle.Kind.CLEAR: 0, WeatherCycle.Kind.CLOUDY: 0, WeatherCycle.Kind.RAIN: 0}
	var days := 2000
	for day: int in days:
		counts[WeatherCycle.day(1840, day, _config).kind] += 1
	var rain: int = counts[WeatherCycle.Kind.RAIN]
	var cloudy: int = counts[WeatherCycle.Kind.CLOUDY]
	assert_float(float(rain) / days).is_equal_approx(_config.weather_rain_chance, 0.03)
	assert_float(float(cloudy) / days).is_equal_approx(_config.weather_cloudy_chance, 0.03)


func test_rain_wets_the_ground_and_it_dries_afterwards() -> void:
	var day := -1
	var today: WeatherCycle.Day
	for index: int in 200:
		today = WeatherCycle.day(1840, index, _config)
		if today.kind == WeatherCycle.Kind.RAIN and today.rain_end + _config.weather_dry_hours < 24.0:
			day = index
			break
	assert_int(day).is_greater_equal(0)
	var middle := WeatherCycle.sample(1840, day * 24.0 + (today.rain_start + today.rain_end) * 0.5, _config)
	assert_float(middle.rain).is_greater(0.9)
	assert_float(middle.wetness).is_greater(0.9)
	assert_float(middle.coverage).is_equal_approx(_config.weather_rain_coverage, 0.01)
	var after := WeatherCycle.sample(1840, day * 24.0 + today.rain_end + _config.weather_dry_hours * 0.5, _config)
	assert_float(after.rain).is_equal(0.0)
	assert_float(after.wetness).is_between(0.05, 0.95)
	var dry := WeatherCycle.sample(1840, day * 24.0 + today.rain_end + _config.weather_dry_hours + 0.1, _config)
	assert_float(dry.wetness).is_equal(0.0)


func test_mist_only_in_the_morning() -> void:
	for day: int in 60:
		for hour: float in [0.0, 3.0, 11.0, 15.0, 21.0]:
			assert_float(WeatherCycle.sample(1840, day * 24.0 + hour, _config).mist).is_equal(0.0)
	var misty := false
	for day: int in 60:
		misty = misty or WeatherCycle.sample(1840, day * 24.0 + _config.weather_mist_peak_hour, _config).mist > 0.3
	assert_bool(misty).is_true()


func test_smoke_follows_production_and_the_preset() -> void:
	var sim := SimFixture.simulation(Vector2i(80, 40), 50)
	SimFixture.road(sim, Vector2i(0, 20), Vector2i(79, 20))
	var furnace := SimFixture.place(sim, &"furnace", Vector2i(10, 21))
	SimFixture.place(sim, &"lumberjack", Vector2i(30, 21))
	var view: SmokeView = auto_free(SmokeView.new())
	add_child(view)
	view.setup(sim, sim.config.cell_size_m)
	view.set_quality(_config.graphics_presets[2])
	assert_int(view.plume_count()).override_failure_message("o lenhador não tem chaminé").is_equal(1)
	assert_int(view.soot_count()).is_equal(1)
	view.refresh()
	assert_int(view.emitting_count()).is_equal(0)
	sim.world.building(furnace).state = BuildingRecord.State.PRODUCING
	view.refresh()
	assert_int(view.emitting_count()).is_equal(1)
	sim.world.building(furnace).paused = true
	view.refresh()
	assert_int(view.emitting_count()).is_equal(0)
	view.set_quality(_config.graphics_presets[0])
	assert_int(view.soot_count()).override_failure_message("no nível baixo não há fuligem").is_equal(0)


func test_clouds_stay_off_on_the_software_renderer() -> void:
	var clouds: CloudsAdapter = auto_free(CloudsAdapter.new())
	add_child(clouds)
	clouds.set_coverage(1.4)
	assert_float(clouds.coverage()).is_equal(1.0)
	clouds.set_quality(_config.graphics_presets[3])
	if CloudsAdapter.software_renderer():
		assert_bool(clouds.is_enabled()).is_false()
	clouds.set_enabled(false)
	assert_bool(clouds.is_enabled()).is_false()


func test_hull_follows_the_ship_size() -> void:
	var def := GameData.get_default().ship(&"merchant_ship")
	var mesh := ShipView.hull_mesh(def.length_m, def.length_m * 0.28, ShipView.HULL_HEIGHT_M)
	var box := mesh.get_aabb()
	assert_float(box.size.x).is_equal_approx(def.length_m, 0.01)
	assert_float(box.size.z).is_less_equal(def.length_m * 0.28 + 0.01)
	assert_float(box.size.z).is_greater(def.length_m * 0.2)
	# as faces apontam para fora (senão o casco some com o descarte das faces de trás)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var outward := 0
	var sides := 0
	for i: int in vertices.size():
		if absf(vertices[i].z) > 0.5:
			sides += 1
			if normals[i].z * signf(vertices[i].z) > 0.0:
				outward += 1
	assert_int(outward).override_failure_message("%d de %d normais para fora" % [outward, sides]).is_greater(sides * 9 / 10)
	var sail := ShipView.sail_mesh(10.0, 6.0, 1.0)
	assert_float(sail.get_aabb().size.x).is_equal_approx(1.0, 0.05)


func test_buildings_share_the_pbr_material_by_tier_and_type() -> void:
	var data := GameData.get_default()
	assert_array(Array(data.validate())).is_empty()
	assert_int(data.tier(&"peasants").wall_material).is_equal(BuildingMaterials.Wall.WOOD)
	assert_int(data.tier(&"workers").wall_material).is_equal(BuildingMaterials.Wall.BRICK)
	assert_int(data.building(&"furnace").smoke).is_equal(BuildingDef.Smoke.HEAVY)
	var sim := SimFixture.simulation(Vector2i(60, 30), 50)
	SimFixture.road(sim, Vector2i(0, 10), Vector2i(59, 10))
	var house := SimFixture.house(sim, 2, 10, &"peasants", 10.0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(sim, sim.config.cell_size_m)
	var bodies := view.find_children("*", "MeshInstance3D", true, false)
	# desde os prédios de modelo, as paredes da casa estão no material do kit (mesma camada)
	var shared := BuildingMaterials.kit() if BuildingKit.available() else BuildingMaterials.walls()
	var walls := bodies.filter(func(node: MeshInstance3D) -> bool: return node.material_override == shared)
	assert_bool(walls.is_empty()).is_false()
	var body: MeshInstance3D = walls[0]
	assert_float(body.get_instance_shader_parameter(&"layer")).is_equal(float(BuildingMaterials.Wall.WOOD))
	assert_int(house).is_greater(0)
