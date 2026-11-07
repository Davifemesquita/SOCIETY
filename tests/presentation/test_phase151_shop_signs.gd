extends GdUnitTestSuite
## Placas das lojas (Fase 151): as lojas da lista ganham a placa (cada uma com a figura dela), as outras não; a placa fica
## para fora da fachada da frente, ao lado da porta, acima do toldo e abaixo do beiral; muda a forma e soma triângulos.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _spec(def_id: StringName) -> BuildingKit.Spec:
	var id := SimFixture.place(_sim, def_id, Vector2i(10 + _sim.world.buildings.size() * 6, 10))
	return BuildingKit.spec_for(_sim, _sim.world.building(id), _sim.world.island(0).cell_size)


func test_each_shop_gets_its_own_figure() -> void:
	var figures: Dictionary[int, bool] = {}
	for def_id: StringName in BuildingKit.SHOP_SIGNS:
		var spec := _spec(def_id)
		assert_int(spec.shop_sign).is_greater(0)
		figures[spec.shop_sign] = true
	assert_int(figures.size()).is_equal(BuildingKit.SHOP_SIGNS.size())
	for def_id: StringName in [&"lumberjack", &"church", &"furnace"]:
		assert_int(_spec(def_id).shop_sign).is_equal(0)


func test_the_sign_hangs_out_of_the_front_beside_the_door() -> void:
	for def_id: StringName in BuildingKit.SHOP_SIGNS:
		var spec := _spec(def_id)
		var center := BuildingKit.shop_sign_center(spec)
		var hall := spec.hall()
		var front_wall := spec.hall_offset().z - hall.size_m().y * 0.5
		# para fora da fachada da frente (−Z), inteira fora da parede
		assert_float(center.z + BuildingKit.SIGN_BOARD_M.z * 0.5).is_less(front_wall)
		# ao lado da porta, na divisa da célula dela
		var door := BuildingKit.door_position(spec)
		var step := hall.size_m().x / hall.cells.x
		assert_float(door.x - center.x).is_equal_approx(step * 0.5, 0.01)
		# acima do toldo e abaixo do beiral
		var bottom := center.y - BuildingKit.SIGN_BOARD_M.y * 0.5
		if spec.awning > 0:
			assert_float(bottom).is_greater(hall.floor_m() * BuildingKit.AWNING_AT)
		assert_float(center.y + BuildingKit.SIGN_BOARD_M.y * 0.5).is_less(spec.height_m)


func test_the_sign_changes_the_shape() -> void:
	var with_sign := _spec(&"bakery")
	var without := _spec(&"bakery")
	without.shop_sign = 0
	assert_str(with_sign.key()).is_not_equal(without.key())
	assert_int(BuildingKit.triangles(with_sign)).is_greater(BuildingKit.triangles(without))
