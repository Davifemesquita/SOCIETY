extends GdUnitTestSuite
## Campos em colcha (Fase 40): o contorno da terra lavrada fica dentro do lote e ondula igual dos dois lados da divisa;
## vizinhos alinhados têm fileiras em direções diferentes; cor determinística por campo; sebe uma vez por aresta com a
## porteira, muro de pedra no lote em encosta; trilhas no pasto na máscara do terreno; nada mexe na simulação.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.ignore_terrain = true


func _view() -> CropView:
	var view: CropView = auto_free(CropView.new())
	add_child(view)
	view.setup(_sim)
	return view


func _lot(field_id: int) -> Rect2:
	var record := _sim.world.building(field_id)
	var area := Footprint.rect(record.origin, Vector2i(3, 3), record.rotation)
	var grid := _sim.world.island(0)
	return Rect2(grid.origin_m + Vector2(area.position) * grid.cell_size, Vector2(area.size) * grid.cell_size)


func test_the_outline_stays_inside_the_lot_and_wiggles() -> void:
	var field := SimFixture.place(_sim, &"field", Vector2i(10, 10), 0)
	var view := _view()
	var record := _sim.world.building(field)
	var outline := view.field_outline(record, _sim.def_of(record))
	var lot := _lot(field)
	var insets: Dictionary[float, bool] = {}
	assert_int(outline.size()).is_greater(20)
	for p: Vector2 in outline:
		assert_bool(lot.grow(-CropView.FIELD_INSET_M + 0.001).has_point(p)).override_failure_message("%s" % p).is_true()
		assert_bool(lot.grow(-(CropView.FIELD_INSET_M + CropView.FIELD_WIGGLE_M) - 0.001).has_point(p)).is_false()
		insets[snappedf(minf(p.y - lot.position.y, lot.end.y - p.y), 0.02)] = true
	# não é um quadrado recuado: o recuo muda ao longo da divisa
	assert_int(insets.size()).is_greater(4)


func test_neighbours_wiggle_the_same_on_both_sides_of_the_shared_line() -> void:
	var left := SimFixture.place(_sim, &"field", Vector2i(10, 10), 0)
	var right := SimFixture.place(_sim, &"field", Vector2i(13, 10), 0)
	var view := _view()
	var line := _lot(left).end.x
	var from_left: Dictionary[float, float] = {}
	var a := _sim.world.building(left)
	for p: Vector2 in view.field_outline(a, _sim.def_of(a)):
		if p.x > line - 1.0:
			from_left[snappedf(p.y, 0.001)] = line - p.x
	var matched := 0
	var b := _sim.world.building(right)
	for p: Vector2 in view.field_outline(b, _sim.def_of(b)):
		var key := snappedf(p.y, 0.001)
		if p.x < line + 1.0 and from_left.has(key):
			assert_float(p.x - line).is_equal_approx(from_left[key], 0.001)
			matched += 1
	assert_int(matched).is_greater(5)


func test_aligned_neighbours_never_run_their_rows_the_same_way() -> void:
	var center := BuildingRecord.new(1, &"field", 0, Vector2i(10, 10), 0)
	for step: Vector2i in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
		var other := BuildingRecord.new(2, &"field", 0, Vector2i(10, 10) + step, 0)
		assert_bool(CropView.rows_along_x(other)).is_not_equal(CropView.rows_along_x(center))
	# e a direção chega às leiras (lidas da conta, não do MultiMesh: sem tela ele devolve zeros)
	var view := _view()
	var counts: Array[Vector2i] = []
	for origin: Vector2i in [Vector2i(10, 24), Vector2i(13, 24)]:
		var record := _sim.world.building(SimFixture.place(_sim, &"field", origin, 0))
		var along := Vector2i.ZERO
		for place: Transform3D in view._furrow_places(record, _sim.def_of(record), 0.75):
			if absf(place.basis.x.x) > absf(place.basis.x.z):
				along.x += 1
			else:
				along.y += 1
		counts.append(along)
	# o primeiro campo corre num sentido (mais as duas leiras da cabeceira, de través), o vizinho no outro
	assert_bool((counts[0].x > counts[0].y) != (counts[1].x > counts[1].y)).is_true()


func test_field_colours_are_stable_and_varied() -> void:
	var soils: Dictionary[Color, bool] = {}
	for id: int in range(1, 40):
		assert_bool(CropView.field_soil(id).is_equal_approx(CropView.field_soil(id))).is_true()
		assert_bool(CropView.field_shade(id).is_equal_approx(CropView.field_shade(id))).is_true()
		soils[CropView.field_soil(id)] = true
	assert_int(soils.size()).is_greater_equal(3)


func test_hedges_run_once_per_edge_with_a_gate() -> void:
	SimFixture.place(_sim, &"field", Vector2i(10, 10), 0)
	var view := _view()
	var pieces := roundi(_sim.config.cell_size_m / CropView.BORDER_PIECE_M)
	# 12 divisas de célula em volta, menos a da porteira
	assert_int(view.hedge_count()).is_equal(11 * pieces)
	assert_int(view.wall_count()).is_equal(0)
	# o vizinho encostado: a divisa comum (3 arestas) sai uma vez só
	SimFixture.place(_sim, &"field", Vector2i(13, 10), 0)
	view.rebuild()
	assert_int(view.hedge_count()).is_equal((24 - 3 - 2) * pieces)
	# as peças ficam na linha da divisa, no chão (da conta: sem tela o MultiMesh devolve zeros)
	var grid := _sim.world.island(0)
	var hedges: Array = []
	var walls: Array = []
	var seen: Dictionary[Vector3i, bool] = {}
	var record := _sim.world.building(grid.building_at(Vector2i(10, 10)))
	view._add_borders(record, _sim.def_of(record), seen, hedges, walls)
	assert_int(hedges.size()).is_equal(11 * pieces)
	for item: Array in hedges:
		var place: Transform3D = item[0]
		var local := (Vector2(place.origin.x, place.origin.z) - grid.origin_m) / grid.cell_size
		var on_line := absf(local.x - roundf(local.x)) < 0.01 or absf(local.y - roundf(local.y)) < 0.01
		assert_bool(on_line).is_true()


func test_the_fields_of_one_farm_share_one_hedge_around_them() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(59, 20))
	SimFixture.place(_sim, &"potato_farm", Vector2i(10, 21), 0)
	var a := SimFixture.place(_sim, &"field", Vector2i(10, 24), 0)
	var b := SimFixture.place(_sim, &"field", Vector2i(13, 24), 0)
	var owners := _sim.derived_state().module_owner
	assert_int(owners.get(a, 0)).is_not_equal(0)
	assert_int(owners.get(a, 0)).is_equal(owners.get(b, 0))
	var view := _view()
	var hedges: Array = []
	var seen: Dictionary[Vector3i, bool] = {}
	for id: int in [a, b]:
		var record := _sim.world.building(id)
		view._add_borders(record, _sim.def_of(record), seen, hedges, [])
	# nenhuma peça na divisa entre os dois (x = 13 células)
	var grid := _sim.world.island(0)
	for item: Array in hedges:
		var place: Transform3D = item[0]
		var local_x := (place.origin.x - grid.origin_m.x) / grid.cell_size
		assert_float(absf(local_x - 13.0)).is_greater(0.01)


func test_a_field_on_a_slope_gets_a_dry_stone_wall() -> void:
	var grid := _sim.world.island(0)
	grid.init_terrain()
	for y: int in grid.size.y + 1:
		for x: int in grid.size.x + 1:
			grid.corner_heights[y * (grid.size.x + 1) + x] = 2.0 + y * 0.15
	grid.invalidate_heights()
	SimFixture.place(_sim, &"field", Vector2i(10, 10), 0)
	var view := _view()
	assert_int(view.hedge_count()).is_equal(0)
	assert_int(view.wall_count()).is_greater(0)
	# a terra segue o terreno
	var mesh := view.soil_mesh()
	for vertex: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		assert_float(vertex.y).is_equal_approx(grid.height_at(vertex.x, vertex.z) + CropView.SOIL_M, 0.001)


func test_fields_and_pastures_lose_their_boxes() -> void:
	var field := SimFixture.place(_sim, &"field", Vector2i(10, 10), 0)
	var pasture := SimFixture.place(_sim, &"pasture", Vector2i(20, 10), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, 2.0)
	for id: int in [field, pasture]:
		assert_int(view.building_node(id).find_children("*", "MeshInstance3D", true, false).size()).is_equal(0)
	remove_child(view)


func test_pastures_wear_trails_into_the_terrain_mask() -> void:
	var grid := _sim.world.island(0)
	grid.init_terrain()
	for i: int in grid.corner_heights.size():
		grid.corner_heights[i] = 1.2
	grid.invalidate_heights()
	var pasture := SimFixture.place(_sim, &"pasture", Vector2i(20, 10), 0)
	var mask := RoadMask.new(_sim.world, _sim.data, 0, 4, 1.6)
	var trail: PackedVector2Array = RoadMask.trails(_sim.world, _sim.data, 0)[pasture]
	assert_int(trail.size()).is_equal(3)
	# no meio do caminho da porteira ao centro e do centro ao canto
	assert_float(mask.channel_at(trail[0].lerp(trail[1], 0.5), 2)).is_greater(0.5)
	assert_float(mask.channel_at(trail[1].lerp(trail[2], 0.5), 2)).is_greater(0.5)
	# o pasto demolido leva a trilha
	_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(21, 11), Vector2i.ONE)))
	mask.refresh()
	assert_float(mask.channel_at(trail[1].lerp(trail[2], 0.5), 2)).is_equal(0.0)


func test_the_view_does_not_touch_the_simulation() -> void:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(59, 20))
	SimFixture.place(_sim, &"wheat_farm", Vector2i(10, 21), 0)
	for x: int in range(10, 40, 3):
		SimFixture.place(_sim, &"field", Vector2i(x, 26), 0)
	SimFixture.place(_sim, &"pasture", Vector2i(40, 10), 0)
	var state := var_to_str(_sim.world.to_dict())
	var started := Time.get_ticks_msec()
	var view := _view()
	view.rebuild()
	print("Fase 40: %d campos em %d ms" % [10, Time.get_ticks_msec() - started])
	assert_str(var_to_str(_sim.world.to_dict())).is_equal(state)
