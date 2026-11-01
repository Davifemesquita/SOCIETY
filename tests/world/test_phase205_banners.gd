extends GdUnitTestSuite
## Estandartes na fachada (Fase 205): os serviços de SERVICES ganham dois estandartes, nas divisas da célula da porta, para fora
## da fachada, com o alto abaixo do andar e o pano acima da porta; as casas e as fábricas não têm; o pano desce do braço.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


func test_two_banners_flank_the_door_of_each_service() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var grid := _sim.world.island(SimFixture.ISLAND)
	var x := 2
	for def_id: StringName in BannerView.SERVICES:
		var size := Footprint.rotated_size(_sim.data.building(def_id).size, 2)
		var id := SimFixture.place(_sim, def_id, Vector2i(x, 20 - size.y), 2)
		x += size.x + 1
		var record := _sim.world.building(id)
		var places := BannerView.places_of(_sim, record)
		assert_int(places.size()).is_equal(2)
		var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
		var hall := spec.hall()
		var door := spec.hall_offset() + BuildingKit._wall_point(hall, 0, hall.door_index, 0)
		var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, _sim.def_of(record).size,
				record.rotation))
		var sides: Array[float] = []
		for place: Transform3D in places:
			var local := model.affine_inverse() * place.origin
			# na divisa da célula da porta, para fora da fachada, com o alto abaixo do andar
			assert_float(absf(local.x - door.x)).is_equal_approx(spec.cell_m * 0.5, 0.01)
			sides.append(signf(local.x - door.x))
			assert_float(door.z - local.z).is_equal_approx(BannerView.ARM_M, 0.01)
			var length := place.basis.y.length() * BannerView.LENGTH_M
			assert_float(length).is_between(BannerView.MIN_LENGTH_M, BannerView.LENGTH_M + 0.001)
			# o pano acaba acima da porta
			assert_float(local.y - length).is_greater_equal(BannerView.DOOR_CLEAR_M - 0.6)
		assert_bool(sides.has(1.0) and sides.has(-1.0)).is_true()


func test_houses_and_works_have_none() -> void:
	var house := SimFixture.place(_sim, &"house", Vector2i(10, 10), 0)
	var bakery := SimFixture.place(_sim, &"bakery", Vector2i(20, 10), 0)
	for id: int in [house, bakery]:
		var record := _sim.world.building(id)
		assert_bool(record.def_id in BannerView.SERVICES).is_false()


func test_the_cloth_hangs_from_the_arm() -> void:
	var box := BannerView.banner_mesh().get_aabb()
	# o braço em cima (y ≥ 0) vai até a parede em +z; o pano desce até −LENGTH_M
	assert_float(box.position.y).is_equal_approx(-BannerView.LENGTH_M, 0.02)
	assert_float(box.end.z).is_greater_equal(BannerView.ARM_M - 0.02)
	assert_float(box.size.x).is_between(BannerView.WIDTH_M, BannerView.WIDTH_M + 0.2)
