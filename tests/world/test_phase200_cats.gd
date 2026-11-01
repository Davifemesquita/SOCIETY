extends GdUnitTestSuite
## Gato na porta (Fase 200): só as casas do resto certo e sem cão têm o gato, sentado ao lado da porta, de frente para a rua; a
## cabeça olha para um lado ou para o outro e volta; o gato é pequeno e assenta no chão.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


## Casas espaçadas na rua y = 20 (duas células livres entre elas), de frente para ela.
func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 5, 20, tier, 5.0))
	return ids


func test_the_cat_sits_by_the_door_of_the_houses_of_its_rest() -> void:
	var ids := _houses(&"workers", 20)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := 0
	for id: int in ids:
		var record := _sim.world.building(id)
		var found: Variant = CatView.spot(_sim, record)
		var expected := posmod(id, CatView.CAT_EVERY) == CatView.CAT_REST and id % AnimalView.DOG_EVERY != 0
		assert_bool(found is Transform3D).is_equal(expected)
		if not found is Transform3D:
			continue
		count += 1
		var place: Transform3D = found
		var def := _sim.def_of(record)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var model := BuildingView.model_place(grid, record, area)
		var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
		var hall := spec.hall()
		var door := spec.hall_offset() + BuildingKit._wall_point(hall, 0, hall.door_index, 0)
		var local := model.affine_inverse() * place.origin
		# ao lado da porta, um pouco à frente da parede
		assert_float(absf(local.x - door.x)).is_equal_approx(CatView.SIDE_M, 0.01)
		assert_float(door.z - local.z).is_equal_approx(CatView.OUT_M, 0.01)
		# de frente para a rua (−z do modelo), torto no máximo meio radiano
		var front := Footprint.front_direction(record.rotation)
		assert_float((-place.basis.z).normalized().dot(Vector3(front.x, 0.0, front.y))).is_greater(cos(0.5))
		assert_float(place.origin.y).is_greater_equal(grid.height_at(place.origin.x, place.origin.z) - 0.001)
	assert_int(count).is_greater(0)


func test_no_cat_where_the_dog_lives() -> void:
	_houses(&"workers", 20)
	for id: int in _sim.world.building_ids():
		var record := _sim.world.building(id)
		if record.is_house() and id % AnimalView.DOG_EVERY == 0:
			assert_object(CatView.spot(_sim, record)).is_null()


func test_the_glance_comes_and_goes() -> void:
	var turned := 0
	var sides: Dictionary[float, bool] = {}
	for step: int in 600:
		var angle := CatView.glance(4242, step * 0.1)
		assert_float(absf(angle)).is_less_equal(CatView.LOOK_RAD + 0.0001)
		if absf(angle) > CatView.LOOK_RAD * 0.5:
			turned += 1
			sides[signf(angle)] = true
	assert_int(turned).is_greater(0)
	assert_int(turned).is_less(300)
	# olha para os dois lados com o tempo
	assert_int(sides.size()).is_equal(2)


func test_the_cat_is_small() -> void:
	var body := CatView.body_mesh().get_aabb()
	var head := CatView.head_mesh().get_aabb()
	assert_float(body.position.y).is_greater_equal(-0.001)
	assert_float(CatView.NECK.y + head.end.y).is_between(0.25, 0.4)
	assert_float(body.size.x).is_less(0.3)
