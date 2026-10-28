extends GdUnitTestSuite
## Tanques da usina a petróleo (Fase 78): a usina a petróleo deixa a forma da usina a carvão (o galpão com o lanternim) e
## ganha o pátio da frente com dois tanques verticais dentro de um dique baixo, a escada e o tubo até o galpão, nas
## fileiras de trás. Só apresentação.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _spec(def_id: StringName) -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, BuildingRecord.new(5, def_id, 0, Vector2i(10, 10), 0), 2.0)


func test_the_oil_station_has_a_tank_yard_and_the_coal_station_keeps_its_hall() -> void:
	var spec := _spec(&"oil_power_station")
	assert_int(spec.silhouette).is_equal(BuildingDef.Silhouette.TANKFARM)
	assert_int(spec.court_rows).is_equal(BuildingKit.TANKFARM_ROWS)
	assert_int(_spec(&"power_station").silhouette).is_equal(BuildingDef.Silhouette.CLERESTORY)
	assert_int(_spec(&"power_station").court_rows).is_equal(0)
	# os tanques e o resto acrescentam peças à forma sem o pátio
	var plain := _spec(&"oil_power_station")
	plain.silhouette = BuildingDef.Silhouette.NONE
	assert_int(BuildingKit.triangles(spec)).is_greater(BuildingKit.triangles(plain))


func test_the_tanks_fit_the_yard_and_leave_the_door_path_free() -> void:
	var spec := _spec(&"oil_power_station")
	var tanks := BuildingKit.tank_layout(spec)
	assert_int(tanks.size()).is_equal(2)
	var size := spec.size_m()
	var front := -size.y * 0.5
	var yard_end := front + spec.court_rows * spec.cell_m
	for tank: Array in tanks:
		var base: Vector3 = tank[0]
		var radius: float = tank[1]
		var height: float = tank[2]
		# dentro do pátio, entre o dique da frente e o galpão, e dentro do lote dos lados
		assert_float(base.z - radius).is_greater(front + 0.2)
		assert_float(base.z + radius).is_less(yard_end)
		assert_float(absf(base.x) + radius).is_less(size.x * 0.5 - 0.2)
		# o caminho da porta (no meio da frente) livre
		assert_float(absf(base.x) - radius).is_greater(0.8)
		# mais altos que o dique, mais baixos que o galpão
		assert_float(height).is_greater(BuildingKit.TANKFARM_BUND_M * 4.0)
		assert_float(height).is_less_equal(minf(spec.height_m, BuildingKit.TANK_MAX_M))
	# um de cada lado, iguais
	var a: Vector3 = tanks[0][0]
	var b: Vector3 = tanks[1][0]
	assert_float(a.x).is_equal_approx(-b.x, 0.001)
	assert_float(a.z).is_equal_approx(b.z, 0.001)


func test_no_yard_means_no_tanks() -> void:
	var spec := _spec(&"oil_power_station")
	spec.court_rows = 0
	assert_int(BuildingKit.tank_layout(spec).size()).is_equal(0)
