extends GdUnitTestSuite
## Buxo na porta (Fase 212): só as casas de pórtico (os investidores) têm os dois vasos, um de cada lado da porta, por fora das
## colunas, à frente da parede e no chão; as outras classes não têm; o vaso com o buxo é baixo e estreito.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 5, 20, tier, 5.0))
	return ids


func test_two_pots_flank_the_door_of_the_portico_houses() -> void:
	var grid := _sim.world.island(SimFixture.ISLAND)
	for id: int in _houses(&"investors", 4):
		var record := _sim.world.building(id)
		var found := TopiaryView.places_of(_sim, record)
		assert_int(found.size()).is_equal(2)
		var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
		var hall := spec.hall()
		var door := spec.hall_offset() + BuildingKit._wall_point(hall, 0, hall.door_index, 0)
		var step := hall.size_m().x / hall.cells.x
		var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, _sim.def_of(record).size,
				record.rotation))
		var sides: Array[float] = []
		for place: Transform3D in found:
			var local := model.affine_inverse() * place.origin
			# por fora das colunas do pórtico (a 0,42 da célula) e à frente da parede
			assert_float(absf(local.x - door.x)).is_greater(0.42 * step + 0.2)
			assert_float(door.z - local.z).is_equal_approx(TopiaryView.OUT_M, 0.01)
			sides.append(signf(local.x - door.x))
			assert_float(place.origin.y).is_greater_equal(grid.height_at(place.origin.x, place.origin.z) - 0.001)
		assert_bool(sides.has(1.0) and sides.has(-1.0)).is_true()


func test_other_tiers_have_none() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers"]:
		_sim = SimFixture.simulation(Vector2i(120, 40))
		_sim.free_build = true
		for id: int in _houses(tier, 3):
			assert_int(TopiaryView.places_of(_sim, _sim.world.building(id)).size()).is_equal(0)


func test_the_pot_is_small() -> void:
	var box := TopiaryView.pot_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.001)
	assert_float(box.end.y).is_between(1.0, 1.4)
	assert_float(box.size.x).is_less(0.9)
