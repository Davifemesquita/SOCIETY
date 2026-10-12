extends GdUnitTestSuite
## A configuração padrão carrega, é válida e traz os valores iniciais da especificação.


func test_default_config_loads_and_is_valid() -> void:
	var config := GameConfig.get_default()
	assert_object(config).is_not_null()
	assert_array(Array(config.validate())).is_empty()


func test_default_values_follow_the_spec() -> void:
	var config := GameConfig.get_default()
	assert_float(config.tick_interval()).is_equal_approx(0.2, 0.0001)
	assert_array(Array(config.game_speeds)).is_equal([1.0, 2.0, 4.0])
	assert_float(config.day_length_game_seconds()).is_equal(1440.0)
	assert_int(config.starting_money).is_equal(50000)
	assert_int(config.min_balance_to_build).is_equal(-10000)
	assert_int(config.island_storage_capacity_t).is_equal(50)
	assert_int(config.logistics_range_cells).is_equal(40)
	assert_int(config.service_radius_cells).is_equal(25)
	assert_float(config.autosave_interval_minutes).is_equal(10.0)
	assert_str(config.supported_locales[0]).is_equal("pt_BR")


func test_invalid_values_are_listed() -> void:
	var config := GameConfig.new()
	config.ticks_per_second = 0
	config.game_speeds = PackedFloat32Array([1.0, 0.0])
	config.demolish_refund = 1.5
	config.supported_locales = PackedStringArray()
	assert_int(config.validate().size()).is_equal(4)
