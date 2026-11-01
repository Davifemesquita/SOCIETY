extends GdUnitTestSuite
## Banco na porta (Fase 174): só as casas de camponeses do resto certo têm o banco, no quintal cercado da frente, encostado na
## parede ao lado da porta e além dos vasos, virado para a rua; operários não; o banco é baixo e cabe no quintal.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true


func test_the_bench_stands_in_the_front_yard_beside_the_door() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := 0
	for i: int in 9:
		var id := SimFixture.house(_sim, 2 + i * 4, 20, &"peasants", 5.0)
		var record := _sim.world.building(id)
		var found: Variant = DoorBenchView.spot(_sim, record)
		assert_bool(found is Transform3D).is_equal(posmod(id, DoorBenchView.BENCH_EVERY) == DoorBenchView.BENCH_REST)
		if not found is Transform3D:
			continue
		count += 1
		var place: Transform3D = found
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		# dentro do lote, na fileira da frente (o quintal: a rua em y = 20, a casa acima dela, a frente em +y)
		var cell := grid.world_to_cell(place.origin)
		assert_bool(area.has_point(cell)).is_true()
		assert_int(cell.y).is_equal(area.end.y - 1)
		# virado para a rua
		assert_float(place.basis.z.z).is_greater(0.9)
		# além dos vasos da porta
		var door := grid.cell_world(Footprint.entrance_cell(record.origin, _sim.def_of(record).size, record.rotation))
		assert_float(absf(place.origin.x - door.x)).is_greater(YardView.POT_SIDE_M)
	assert_int(count).is_greater(0)


func test_workers_get_no_bench() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	for i: int in 6:
		var id := SimFixture.house(_sim, 2 + i * 4, 20, &"workers", 5.0)
		assert_bool(DoorBenchView.spot(_sim, _sim.world.building(id)) is Transform3D).is_false()


func test_the_bench_is_low_and_fits_the_yard() -> void:
	var box := DoorBenchView.bench_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(0.5)
	assert_float(box.size.x).is_less(_sim.config.cell_size_m * 0.7)
	assert_float(box.size.z).is_less(0.4)
