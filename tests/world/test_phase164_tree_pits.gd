extends GdUnitTestSuite
## Caldeira das árvores (Fase 164): cada árvore da alameda ganha a caldeira no pé, no mesmo lugar dela e alinhada com a rua; a
## caldeira cabe na célula, é baixa e deixa o furo do tronco livre.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 30))
	_sim.free_build = true
	_sim.ignore_terrain = true


func test_every_avenue_tree_gets_its_pit() -> void:
	var view: AvenueView = auto_free(AvenueView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.pit_places.size()).is_equal(0)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(5, 10), Vector2i(40, 10)), true))
	view._process(0.0)
	var cells := AvenueView.cells(_sim.world, 0)
	assert_int(view.pit_places.size()).is_equal(cells.size())
	var grid := _sim.world.island(0)
	for place: Transform3D in view.pit_places:
		assert_bool(cells.has(grid.world_to_cell(place.origin))).is_true()
		# alinhada com a grade
		assert_bool(place.basis.is_equal_approx(Basis.IDENTITY)).is_true()


func test_the_pit_fits_the_cell_low_with_room_for_the_trunk() -> void:
	var mesh := AvenueView.pit_mesh()
	var box := mesh.get_aabb()
	var half := _sim.config.cell_size_m * 0.5
	assert_float(maxf(absf(box.position.x), absf(box.end.x))).is_less(half)
	assert_float(maxf(absf(box.position.z), absf(box.end.z))).is_less(half)
	assert_float(box.end.y).is_less(0.15)
	# nenhum vértice da grade no furo do tronco (o meio, até 10 cm)
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertex: Vector3 in vertices:
		if vertex.y > 0.035:
			assert_float(maxf(absf(vertex.x), absf(vertex.z))).is_greater(0.1)
