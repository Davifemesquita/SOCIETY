extends GdUnitTestSuite
## Eletricidade (Fase 11): a usina queima carvão sem gerar bem e, enquanto produz, acelera as
## fábricas (produção com entrada) no raio dela em electricity_bonus. Fora do raio, com a usina
## parada, em outra ilha ou em fazenda e mina, nada muda. A camada do mapa mostra o raio e as fábricas.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	SimFixture.house(_sim, 60, 20, &"workers", 400.0)
	SimFixture.house(_sim, 70, 20, &"engineers", 200.0)


func _plant() -> int:
	return SimFixture.place(_sim, &"power_station", Vector2i(10, 21))


func _entry(building_id: int) -> DerivedState.ProductionEntry:
	return _sim.derived_state().entry_of(building_id)


func test_power_station_is_a_plant_and_only_factories_take_power() -> void:
	var data := GameData.get_default()
	var plant := data.building(&"power_station")
	assert_bool(plant.is_power_plant()).is_true()
	assert_bool(plant.is_electrifiable()).is_false()
	assert_float(plant.output_per_min()).is_equal(0.0)
	assert_array(plant.inputs).contains([&"coal"])
	assert_bool(data.building(&"steel_beam_works").is_electrifiable()).is_true()
	assert_bool(data.building(&"coal_mine").is_electrifiable()).is_false()
	assert_bool(data.building(&"wheat_farm").is_electrifiable()).is_false()
	assert_array(data.validate()).is_empty()
	assert_array(GameConfig.new().validate()).is_empty()


func test_running_plant_speeds_up_the_factory_in_range() -> void:
	var plant := _plant()
	var factory := SimFixture.place(_sim, &"steel_beam_works", Vector2i(20, 21))
	SimFixture.give(_sim, &"coal", 10.0)
	SimFixture.give(_sim, &"steel", 10.0)
	SimFixture.run_production(_sim, 61.0)
	assert_int(_sim.world.building(plant).state).is_equal(BuildingRecord.State.PRODUCING)
	assert_bool(_entry(factory).powered).is_true()
	# ciclo de 45 s a 150%: 30 s por viga, duas em 61 s (sem usina seria uma)
	assert_float(SimFixture.stock(_sim, &"steel_beams")).is_equal(2.0)
	assert_float(_sim.world.building(factory).productivity).is_greater(1.0)
	# a usina queima o carvão e não põe bem nenhum no estoque
	assert_float(SimFixture.stock(_sim, &"coal")).is_less(10.0)
	assert_int(_sim.derived_state().powered_by(plant).size()).is_equal(1)


func test_factory_out_of_range_keeps_its_speed() -> void:
	_plant()
	var factory := SimFixture.place(_sim, &"steel_beam_works", Vector2i(100, 21))
	SimFixture.give(_sim, &"coal", 10.0)
	SimFixture.give(_sim, &"steel", 10.0)
	SimFixture.run_production(_sim, 61.0)
	assert_array(_entry(factory).power_plants).is_empty()
	assert_bool(_entry(factory).powered).is_false()
	assert_float(SimFixture.stock(_sim, &"steel_beams")).is_equal(1.0)


func test_plant_without_coal_gives_no_power() -> void:
	var plant := _plant()
	var factory := SimFixture.place(_sim, &"steel_beam_works", Vector2i(20, 21))
	SimFixture.give(_sim, &"steel", 10.0)
	SimFixture.run_production(_sim, 61.0)
	assert_int(_sim.world.building(plant).state).is_equal(BuildingRecord.State.NO_INPUT)
	assert_int(_entry(factory).power_plants.size()).is_equal(1)
	assert_bool(_entry(factory).powered).is_false()
	assert_float(SimFixture.stock(_sim, &"steel_beams")).is_equal(1.0)


func test_paused_plant_cuts_the_power() -> void:
	var plant := _plant()
	var factory := SimFixture.place(_sim, &"steel_beam_works", Vector2i(20, 21))
	SimFixture.give(_sim, &"coal", 10.0)
	SimFixture.give(_sim, &"steel", 10.0)
	SimFixture.run_production(_sim, 5.0)
	assert_bool(_entry(factory).powered).is_true()
	_sim.execute(SetPausedCommand.new(plant, true))
	SimFixture.run_production(_sim, 1.0)
	assert_bool(_entry(factory).powered).is_false()


func test_farms_and_mines_do_not_take_power() -> void:
	_plant()
	var lumberjack := SimFixture.place(_sim, &"lumberjack", Vector2i(20, 21))
	SimFixture.run_production(_sim, 1.0)
	assert_array(_entry(lumberjack).power_plants).is_empty()


func test_plant_does_not_reach_another_island() -> void:
	var sim := SimFixture.two_islands()
	var plant := sim.execute(PlaceBuildingCommand.new(0, &"power_station", Vector2i(10, 7), 0))
	var factory := sim.execute(PlaceBuildingCommand.new(1, &"steel_beam_works", Vector2i(10, 7), 0))
	assert_bool(plant.ok() and factory.ok()).is_true()
	assert_array(sim.derived_state().entry_of(factory.placed[0]).power_plants).is_empty()


func test_overlay_shows_the_range_and_the_factories() -> void:
	var plant := _plant()
	var near := SimFixture.place(_sim, &"steel_beam_works", Vector2i(20, 21))
	var far := SimFixture.place(_sim, &"steel_beam_works", Vector2i(100, 21))
	SimFixture.give(_sim, &"coal", 10.0)
	SimFixture.give(_sim, &"steel", 10.0)
	SimFixture.run_production(_sim, 2.0)
	var image := MapOverlays.image(MapOverlays.Layer.ELECTRICITY, _sim, 0)
	var origin := _sim.world.building(plant).origin
	# a imagem é RGBA8: as cores voltam arredondadas
	_assert_color(image.get_pixelv(origin + Vector2i(-3, 8)), MapOverlays.POWER_ON)
	_assert_color(image.get_pixelv(_sim.world.building(near).origin + Vector2i(1, 1)), MapOverlays.SERVED)
	_assert_color(image.get_pixelv(_sim.world.building(far).origin + Vector2i(1, 1)), MapOverlays.UNSERVED)
	assert_float(image.get_pixelv(Vector2i(60, 5)).a).is_equal(0.0)


func _assert_color(got: Color, wanted: Color) -> void:
	assert_bool(got.is_equal_approx(wanted) or (absf(got.r - wanted.r) < 0.01 and absf(got.g - wanted.g) < 0.01 \
			and absf(got.b - wanted.b) < 0.01 and absf(got.a - wanted.a) < 0.01)) \
			.override_failure_message("cor %s, esperada %s" % [got, wanted]).is_true()
