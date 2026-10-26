extends GdUnitTestSuite
## Calçamento e esquinas (Fase 46): a grade dual — a tabela dos 16 casos (máscara de 4 bits → peça e giro), a sela
## decidida pela conectividade da simulação, o canto de fora arredondado e o de dentro com concordância, o meio-fio dentro
## das peças, a atualização só dos cantos em volta da estrada nova e a RoadView sem ladrilho no paralelepípedo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(40, 30))
	_sim.free_build = true


func _pave(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		_sim.world.island(0).set_road(cell, IslandGrid.Road.PAVED)


func _view() -> RoadView:
	var view: RoadView = auto_free(RoadView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	return view


func test_the_sixteen_cases_map_to_six_pieces_and_a_turn() -> void:
	var expected := {
		0: Vector2i(PavedDual.Piece.EMPTY, 0), 15: Vector2i(PavedDual.Piece.FULL, 0),
		1: Vector2i(PavedDual.Piece.OUTER, 0), 2: Vector2i(PavedDual.Piece.OUTER, 1), 4: Vector2i(PavedDual.Piece.OUTER, 2),
		8: Vector2i(PavedDual.Piece.OUTER, 3),
		3: Vector2i(PavedDual.Piece.EDGE, 0), 6: Vector2i(PavedDual.Piece.EDGE, 1), 12: Vector2i(PavedDual.Piece.EDGE, 2),
		9: Vector2i(PavedDual.Piece.EDGE, 3),
		5: Vector2i(PavedDual.Piece.SADDLE, 0), 10: Vector2i(PavedDual.Piece.SADDLE, 1),
		7: Vector2i(PavedDual.Piece.INNER, 0), 14: Vector2i(PavedDual.Piece.INNER, 1), 13: Vector2i(PavedDual.Piece.INNER, 2),
		11: Vector2i(PavedDual.Piece.INNER, 3),
	}
	var pieces: Dictionary[int, bool] = {}
	for mask: int in 16:
		var found := PavedDual.case_of(mask)
		assert_that(found).override_failure_message("máscara %d" % mask).is_equal(expected[mask])
		pieces[found.x] = true
	assert_int(pieces.size()).is_equal(6)


func test_the_saddle_follows_the_simulation_connectivity() -> void:
	# a diagonal pura (a simulação liga as duas): a sela vira faixa
	_pave(RoadPath.diagonal_path(Vector2i(10, 10), Vector2i(12, 12)))
	var grid := _sim.world.island(0)
	var corner := Vector2i(11, 11)
	var mask := PavedDual.mask_at(grid, corner)
	assert_int(PavedDual.case_of(mask).x).is_equal(PavedDual.Piece.SADDLE)
	assert_bool(PavedDual.saddle_linked(grid, corner, mask)).is_equal(RoadNetwork.linked_diagonal(grid, Vector2i(10, 10),
			Vector2i(11, 11)))
	assert_bool(PavedDual.saddle_linked(grid, corner, mask)).is_true()
	# duas células só encostadas pela quina, sem a diagonal da simulação: dois cantos de fora
	var other := SimFixture.simulation(Vector2i(20, 20))
	var loose := other.world.island(0)
	loose.set_road(Vector2i(5, 5), IslandGrid.Road.PAVED)
	loose.set_road(Vector2i(6, 6), IslandGrid.Road.PAVED)
	loose.set_road(Vector2i(6, 5), IslandGrid.Road.DIRT)
	var loose_mask := PavedDual.mask_at(loose, Vector2i(6, 6))
	assert_int(PavedDual.case_of(loose_mask).x).is_equal(PavedDual.Piece.SADDLE)
	assert_bool(PavedDual.saddle_linked(loose, Vector2i(6, 6), loose_mask)).is_equal(
			RoadNetwork.linked_diagonal(loose, Vector2i(5, 5), Vector2i(6, 6)))


func test_a_pure_diagonal_is_one_straight_band() -> void:
	# a diagonal pura: as selas são faixas e os cantos de fora das células do meio seguem a mesma reta (sem gomos)
	_pave(RoadPath.diagonal_path(Vector2i(10, 10), Vector2i(20, 20)))
	var grid := _sim.world.island(0)
	var h := grid.cell_size * 0.5
	var line_point := grid.origin_m + Vector2(10.5, 10.5) * grid.cell_size
	var across := Vector2(-1.0, 1.0).normalized()
	var widest := 0.0
	var chamfers := 0
	for y: int in range(12, 19):
		for x: int in range(12, 19):
			var corner := Vector2i(x, y)
			var mask := PavedDual.mask_at(grid, corner)
			if mask == 0:
				continue
			if PavedDual.case_of(mask).x == PavedDual.Piece.OUTER:
				chamfers += 1
			var vertices: PackedVector3Array = PavedDual.corner_geometry(grid, corner)[0]
			for vertex: Vector3 in vertices:
				widest = maxf(widest, absf((Vector2(vertex.x, vertex.z) - line_point).dot(across)))
	assert_int(chamfers).is_greater(0)
	# a meia largura da faixa (mais a meia largura do meio-fio): nada passa da reta
	assert_float(widest).is_less_equal(h * 0.95 + 0.01)


func test_outer_corners_are_round_and_inner_corners_filled() -> void:
	# um L de paralelepípedo: o canto de fora e o de dentro
	_pave(RoadPath.l_path(Vector2i(5, 5), Vector2i(10, 5)))
	_pave(RoadPath.l_path(Vector2i(5, 5), Vector2i(5, 10)))
	var grid := _sim.world.island(0)
	var h := grid.cell_size * 0.5
	# o canto de fora do L (em cima à esquerda da célula 5,5): sem calçamento junto da quina, a peça é arredondada
	var outer := Vector2i(5, 5)
	assert_int(PavedDual.case_of(PavedDual.mask_at(grid, outer)).x).is_equal(PavedDual.Piece.OUTER)
	var corner_point := grid.origin_m + Vector2(outer) * grid.cell_size
	var outer_part := PavedDual.corner_geometry(grid, outer)
	var nearest := INF
	for vertex: Vector3 in outer_part[0]:
		nearest = minf(nearest, Vector2(vertex.x, vertex.z).distance_to(corner_point))
	# a quina seca ficaria a zero; o arredondamento afasta o calçamento dela
	assert_float(nearest).is_greater(h * PavedDual.ROUND * 0.25)
	# o canto de dentro (embaixo à direita da célula 5,5): a concordância entra no quarto vazio
	var inner := Vector2i(6, 6)
	assert_int(PavedDual.case_of(PavedDual.mask_at(grid, inner)).x).is_equal(PavedDual.Piece.INNER)
	var inner_part := PavedDual.corner_geometry(grid, inner)
	var empty_quarter := Rect2(grid.origin_m + Vector2(inner) * grid.cell_size, Vector2(h, h))
	var filleted := 0
	for vertex: Vector3 in inner_part[0]:
		if empty_quarter.grow(-0.01).has_point(Vector2(vertex.x, vertex.z)):
			filleted += 1
	assert_int(filleted).is_greater(0)


func test_the_curb_and_gutter_live_inside_the_pieces() -> void:
	_pave(RoadPath.l_path(Vector2i(5, 5), Vector2i(10, 5)))
	var grid := _sim.world.island(0)
	var curbs := 0
	var gutters := 0
	for x: int in range(5, 12):
		for y: int in range(5, 7):
			var part := PavedDual.corner_geometry(grid, Vector2i(x, y))
			var colors: PackedColorArray = part[1]
			var vertices: PackedVector3Array = part[0]
			var center := grid.origin_m + Vector2(x, y) * grid.cell_size
			for k: int in colors.size():
				if colors[k].b > 0.5:
					curbs += 1
				elif colors[k].r < 1.0:
					gutters += 1
				# tudo dentro da peça (o quadrado de uma célula em volta do canto)
				var local := Vector2(vertices[k].x, vertices[k].z) - center
				assert_float(maxf(absf(local.x), absf(local.y))).is_less_equal(grid.cell_size * 0.5 + 0.01)
	assert_int(curbs).is_greater(0)
	assert_int(gutters).is_greater(0)


func test_a_new_street_redoes_only_the_corners_around_it() -> void:
	_pave(RoadPath.l_path(Vector2i(2, 5), Vector2i(30, 5)))
	var view := _view()
	var full := view.dual_corners_rebuilt
	assert_int(full).is_greater_equal(29 * 2)
	_sim.world.island(0).set_road(Vector2i(20, 20), IslandGrid.Road.PAVED)
	EventBus.roads_changed.emit(0)
	# uma célula nova: os cantos dela com uma célula de folga em volta (4 × 4)
	assert_int(view.dual_corners_rebuilt).is_equal(16)
	# 29 células em fila têm 30 cantos de cada lado; a célula solta, os 4 dela
	assert_int(view.dual_corner_count(0)).is_equal(30 * 2 + 4)


func test_the_road_view_has_no_paved_tiles_and_the_stone_bridge_stays() -> void:
	_pave(RoadPath.l_path(Vector2i(2, 5), Vector2i(10, 5)))
	SimFixture.road(_sim, Vector2i(2, 15), Vector2i(10, 15))
	var view := _view()
	# a terra da ilha plana segue em ladrilho; o paralelepípedo, nenhum
	assert_int(view.tile_count()).is_equal(9)
	assert_int(view.curb_count()).is_equal(0)
	var node := view.get_node(^"Paved_0") as MeshInstance3D
	assert_str((node.material_override as ShaderMaterial).shader.resource_path).is_equal("res://shaders/paved_dual.gdshader")
	# o calçamento fica acima do chão, sob o meio-fio
	var mesh := view.dual_mesh(0)
	var top := -INF
	for vertex: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		top = maxf(top, vertex.y)
	assert_float(top).is_equal_approx(PavedDual.LIFT_M + PavedDual.CURB_HEIGHT_M, 0.001)


func test_a_big_paved_town_meshes_in_reasonable_time() -> void:
	var sim := SimFixture.simulation(Vector2i(160, 160))
	var grid := sim.world.island(0)
	var cells := 0
	for y: int in 160:
		for x: int in 160:
			if x % 6 == 0 or y % 6 == 0:
				grid.set_road(Vector2i(x, y), IslandGrid.Road.PAVED)
				cells += 1
	var view: RoadView = auto_free(RoadView.new())
	add_child(view)
	var started := Time.get_ticks_msec()
	view.setup(sim, sim.config.cell_size_m)
	var full := Time.get_ticks_msec() - started
	grid.set_road(Vector2i(81, 81), IslandGrid.Road.PAVED)
	started = Time.get_ticks_msec()
	EventBus.roads_changed.emit(0)
	var one := Time.get_ticks_msec() - started
	# o resto da RoadView (os ladrilhos da terra e das pontes) também refaz a cada estrada: o mesmo refazer sem mudança
	started = Time.get_ticks_msec()
	view.rebuild()
	var rest := Time.get_ticks_msec() - started
	print("Fase 46: %d células de paralelepípedo em %d ms; uma rua nova em %d ms (o resto da RoadView: %d ms)" % [cells,
			full, one, rest])
	assert_int(one - rest).is_less(60)
	remove_child(view)
