extends GdUnitTestSuite
## Céu (seção 9): o Sky3D mostra a hora do GameClock, com o relógio próprio desligado, e o nascer
## e o pôr do sol do GameConfig batem com o sol dele (é deles que as janelas dependem).

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()


func _sky(use_sky3d: bool) -> SkyAdapter:
	var sky: SkyAdapter = auto_free(SkyAdapter.new())
	add_child(sky)
	sky.setup(_config, use_sky3d)
	return sky


func _sun_up(sky: SkyAdapter) -> bool:
	return sky.sun().global_basis.z.y > 0.0


func test_sky3d_shows_the_hour_it_is_given() -> void:
	var sky := _sky(true)
	assert_bool(sky.uses_sky3d()).is_true()
	sky.set_hour(15.5)
	assert_float(sky.shown_hour()).is_equal_approx(15.5, 0.0001)
	# menos de 15 s de jogo não refaz o céu
	sky.set_hour(15.5 + 0.1 / 60.0)
	assert_float(sky.shown_hour()).is_equal_approx(15.5, 0.0001)
	sky.set_hour(26.0)
	assert_float(sky.shown_hour()).is_equal_approx(2.0, 0.0001)
	assert_int(sky.environment().tonemap_mode).is_equal(Environment.TONE_MAPPER_AGX)


func test_config_sunrise_and_sunset_match_the_sky3d_sun() -> void:
	var sky := _sky(true)
	for check: Array in [[_config.sunrise_hour - 0.15, false], [_config.sunrise_hour + 0.15, true],
			[12.0, true], [_config.sunset_hour - 0.15, true], [_config.sunset_hour + 0.15, false], [0.0, false]]:
		var hour: float = check[0]
		var up: bool = check[1]
		sky.set_hour(hour)
		assert_bool(_sun_up(sky)).override_failure_message("sol às %.2f" % hour).is_equal(up)


func test_simple_sky_dims_at_night() -> void:
	var sky := _sky(false)
	assert_bool(sky.uses_sky3d()).is_false()
	sky.set_hour(12.0)
	var noon := sky.sun().light_energy
	sky.set_hour(0.0)
	assert_float(sky.sun().light_energy).is_less(noon * 0.3)
	assert_float(sky.shown_hour()).is_equal(0.0)
