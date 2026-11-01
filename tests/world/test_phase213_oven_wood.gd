extends GdUnitTestSuite
## Lenha da padaria (Fase 213): cada padaria tem a pilha de lenha ao lado da boca do forno, encostada na mesma parede e de frente
## para fora dela; as outras fábricas de forno não têm; a pilha é baixa e cabe ao lado da boca.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true


func test_the_wood_leans_on_the_wall_beside_the_oven_mouth() -> void:
	var count := 0
	for rotation: int in 4:
		var id := SimFixture.place(_sim, &"bakery", Vector2i(10 + rotation * 15, 15), rotation)
		var record := _sim.world.building(id)
		var found: Variant = OvenWoodView.spot(_sim, record)
		assert_bool(found is Transform3D).is_true()
		var place: Transform3D = found
		var mouth: Transform3D = FurnaceGlowView.mouth(_sim, record)
		# na mesma parede da boca (a mesma orientação), ALONG_M ao longo dela
		assert_float(place.basis.z.normalized().dot(mouth.basis.z.normalized())).is_greater(0.999)
		var local := mouth.affine_inverse() * place.origin
		assert_float(local.x).is_equal_approx(OvenWoodView.ALONG_M, 0.01)
		assert_float(absf(local.z)).is_less(0.01)
		count += 1
	assert_int(count).is_equal(4)


func test_other_furnaces_have_none() -> void:
	var x := 5
	for def_id: StringName in [&"brickworks", &"glassworks", &"furnace"]:
		var id := SimFixture.place(_sim, def_id, Vector2i(x, 15), 0)
		assert_object(OvenWoodView.spot(_sim, _sim.world.building(id))).is_null()
		x += 15


func test_the_pile_is_low_and_fits_beside_the_mouth() -> void:
	var box := OvenWoodView.wood_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.001)
	assert_float(box.end.y).is_between(1.8, 2.0)
	# não chega na boca (meia largura de 0,55 + o contorno) e sai menos de meio metro da parede
	assert_float(OvenWoodView.ALONG_M + box.position.x).is_greater(FurnaceGlowView.HALF_W + FurnaceGlowView.SURROUND_M)
	assert_float(box.end.z).is_less(0.5)


func test_no_wood_against_a_neighbour_wall() -> void:
	var id := SimFixture.place(_sim, &"bakery", Vector2i(20, 15), 0)
	var record := _sim.world.building(id)
	var mouth: Transform3D = FurnaceGlowView.mouth(_sim, record)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var outside := grid.world_to_cell(mouth * Vector3(OvenWoodView.ALONG_M, 0.0, grid.cell_size * 0.5))
	assert_bool(OvenWoodView.spot(_sim, record) is Transform3D).is_true()
	# um prédio de uma célula (um canteiro) encostado na parede do forno, bem onde a lenha ficaria: ela sai
	var result := _sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND, &"flower_bed", outside, 0))
	assert_bool(result.ok()).is_true()
	assert_int(grid.building_at(outside)).is_not_equal(0)
	assert_object(OvenWoodView.spot(_sim, record)).is_null()
