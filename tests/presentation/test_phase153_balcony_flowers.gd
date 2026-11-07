extends GdUnitTestSuite
## Flores nas sacadas (Fase 153): as casas dos engenheiros e investidores têm as floreiras nas sacadas (a forma muda e soma
## triângulos); as outras classes não; a floreira fica por fora do guarda-corpo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _spec(tier: StringName) -> BuildingKit.Spec:
	var id := SimFixture.house(_sim, 20 + _sim.world.buildings.size() * 4, 12, tier, 5.0)
	return BuildingKit.spec_for(_sim, _sim.world.building(id), _sim.world.island(0).cell_size)


func test_only_balcony_houses_get_the_flowers() -> void:
	assert_bool(_spec(&"engineers").balcony_flowers).is_true()
	assert_bool(_spec(&"investors").balcony_flowers).is_true()
	for tier: StringName in [&"peasants", &"workers", &"artisans"]:
		assert_bool(_spec(tier).balcony_flowers).is_false()


func test_the_flowers_change_the_shape_and_add_triangles() -> void:
	for tier: StringName in [&"engineers", &"investors"]:
		# as duas formas da mesma casa (outra casa tem outra variação de telhado e ala)
		var id := SimFixture.house(_sim, 20 + _sim.world.buildings.size() * 4, 12, tier, 5.0)
		var record := _sim.world.building(id)
		var with_flowers := BuildingKit.spec_for(_sim, record, _sim.world.island(0).cell_size)
		var without := BuildingKit.spec_for(_sim, record, _sim.world.island(0).cell_size)
		without.balcony_flowers = false
		assert_str(with_flowers.key()).is_not_equal(without.key())
		assert_int(BuildingKit.triangles(with_flowers)).is_greater(BuildingKit.triangles(without))


func test_the_box_hangs_outside_the_railing() -> void:
	assert_float(BuildingKit.BALCONY_FLOWERS_OUT_M).is_greater(0.0)
	assert_float(BuildingKit.BALCONY_FLOWERS_UP_M).is_less(BuildingKit.RAIL_M)
