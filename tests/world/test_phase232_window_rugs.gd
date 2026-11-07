extends GdUnitTestSuite
## Tapete na janela (Fase 232): só as casas dos operários e dos artesãos do resto certo, com um andar de cima, têm o tapete no
## peitoril da fachada da frente, por fora da parede e caindo por ela; a base é de mão direita, com o y para cima.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(160, 40))
	_sim.free_build = true


func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(159, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 5, 20, tier, 5.0))
	return ids


func test_only_the_right_houses_get_a_rug_on_the_front() -> void:
	var count := 0
	for id: int in _houses(&"artisans", 20):
		var record := _sim.world.building(id)
		var found: Variant = WindowRugView.spot(_sim, record)
		if posmod(id, WindowRugView.RUG_EVERY) != WindowRugView.RUG_REST:
			assert_object(found).is_null()
			continue
		assert_object(found).is_not_null()
		count += 1
		var place: Transform3D = found
		var grid := _sim.world.island(0)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var center := grid.rect_world(area)
		# na fachada da frente (a da rua), acima do térreo, de mão direita e com o y para cima
		var front := Vector2(Footprint.front_direction(record.rotation))
		var out := Vector2(place.basis.z.x, place.basis.z.z)
		assert_float(out.dot(front)).is_greater(0.9)
		assert_float(Vector2(place.origin.x - center.x, place.origin.z - center.z).dot(front)).is_greater(1.0)
		assert_float(place.origin.y).is_greater(2.0)
		assert_float(place.basis.y.y).is_greater(0.99)
		assert_float(place.basis.x.cross(place.basis.y).dot(place.basis.z)).is_greater(0.99)
	assert_int(count).is_greater(0)


func test_peasants_never_get_one() -> void:
	for id: int in _houses(&"peasants", 12):
		assert_object(WindowRugView.spot(_sim, _sim.world.building(id))).is_null()


func test_the_rug_hangs_down_the_wall() -> void:
	var box := WindowRugView.rug_mesh().get_aabb()
	assert_float(box.end.y).is_less(0.1)
	assert_float(box.position.y).is_less(-WindowRugView.DROP_M + 0.01)
	assert_float(box.size.x).is_less(WindowRugView.WIDTH_M + 0.05)
