extends GdUnitTestSuite
## Detalhe das estradas (Fase 14): meio-fio só no paralelepípedo e só nos lados que não dão para outra
## estrada; sulcos de roda na direção da rua de terra.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> RoadView:
	var view: RoadView = auto_free(RoadView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	return view


func test_paved_streets_get_curbs_on_their_open_sides() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(9, 10))
	var view := _view()
	assert_int(view.curb_count()).is_equal(0)
	var grid := _sim.world.island(SimFixture.ISLAND)
	for cell: Vector2i in RoadPath.l_path(Vector2i(0, 20), Vector2i(9, 20)):
		grid.set_road(cell, IslandGrid.Road.PAVED)
	view.rebuild()
	# dez células retas: dois lados cada, mais as duas pontas
	assert_int(view.curb_count()).is_equal(10 * 2 + 2)
	# o meio-fio fica na borda da célula, dentro dela
	var place := RoadView.curb_place(Vector2i(0, 1), _sim.config.cell_size_m)
	assert_float(place.origin.z).is_equal_approx(_sim.config.cell_size_m * 0.5 - RoadView.CURB_WIDTH_M * 0.5, 0.001)
	# Fase 25: o meio-fio tem a largura e a altura da caixa de antes, com as quinas de cima chanfradas
	var curb := RoadView.curb_mesh(_sim.config.cell_size_m)
	var bounds := curb.get_aabb()
	assert_vector(bounds.size).is_equal_approx(Vector3(RoadView.CURB_WIDTH_M,
			RoadView.THICKNESS_M + RoadView.CURB_HEIGHT_M, _sim.config.cell_size_m), Vector3.ONE * 0.001)
	var top_width := 0.0
	var chamfer_normals := 0
	var arrays := curb.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		if is_equal_approx(vertex.y, bounds.end.y):
			top_width = maxf(top_width, absf(vertex.x) * 2.0)
	for normal: Vector3 in normals:
		if absf(normal.x) > 0.3 and normal.y > 0.3:
			chamfer_normals += 1
	assert_float(top_width).is_equal_approx(RoadView.CURB_WIDTH_M - RoadView.CURB_CHAMFER_M * 2.0, 0.001)
	assert_int(chamfer_normals).is_greater(0)
	# o shader do meio-fio usa o mapa de normais: a malha tem tangentes
	var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
	assert_int(tangents.size()).is_greater(0)


func test_dirt_ruts_follow_the_street() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(9, 10))
	SimFixture.road(_sim, Vector2i(5, 11), Vector2i(5, 15))
	var grid := _sim.world.island(SimFixture.ISLAND)
	assert_int(RoadView.ruts(grid, Vector2i(2, 10))).is_equal(RoadView.Ruts.ALONG_X)
	assert_int(RoadView.ruts(grid, Vector2i(5, 13))).is_equal(RoadView.Ruts.ALONG_Z)
	assert_int(RoadView.ruts(grid, Vector2i(5, 10))).is_equal(RoadView.Ruts.BOTH)
	SimFixture.road(_sim, Vector2i(30, 30), Vector2i(30, 30))
	assert_int(RoadView.ruts(grid, Vector2i(30, 30))).is_equal(RoadView.Ruts.NONE)


## Ilha de 20 × 10 plana a 1,2 m com um rio de duas células em x = 8..9 (o canto do meio no leito).
func _river_simulation() -> Simulation:
	var grid := IslandGrid.new(Vector2i(20, 10))
	grid.init_terrain()
	for y: int in 11:
		for x: int in 21:
			grid.corner_heights[grid.corner_index(x, y)] = -1.2 if x == 9 else 1.2
	for y: int in 10:
		for x: int in 20:
			grid.ground[y * 20 + x] = IslandGrid.Ground.RIVER if x == 8 or x == 9 else IslandGrid.Ground.LAND
	var world := WorldState.new()
	world.islands.append(grid)
	var economy := IslandEconomy.new()
	economy.profile_id = &"main_island"
	world.economies.append(economy)
	var sim := Simulation.new(GameConfig.new(), GameData.get_default(), world)
	sim.free_build = true
	return sim


func test_the_bridge_gets_railings_and_piles() -> void:
	_sim = _river_simulation()
	var grid := _sim.world.island(0)
	for cell: Vector2i in RoadPath.l_path(Vector2i(6, 5), Vector2i(11, 5)):
		grid.set_road(cell, IslandGrid.Road.DIRT)
	var view := _view()
	# as duas células da ponte, dois lados abertos cada, duas travessas por lado
	assert_int(view.rail_count()).is_equal(2 * 2 * 2)
	# por lado: o poste do meio, o do canto de trás e a estaca; o canto da frente só no fim da ponte
	assert_int(view.post_count()).is_equal(2 * 2 * 3 + 2)
	assert_bool(RoadView.railed(grid, Vector2i(8, 5), Vector2i(0, 1))).is_true()
	assert_bool(RoadView.railed(grid, Vector2i(8, 5), Vector2i(1, 0))).is_false()
	assert_bool(RoadView.railed(grid, Vector2i(6, 5), Vector2i(0, 1))).is_false()
	assert_int(view.curb_count()).is_equal(0)
	# a de terra não leva nada da ponte de pedra
	assert_int(view.parapet_count()).is_equal(0)
	assert_int(view.arch_count()).is_equal(0)


## Fase 24: a rua de paralelepípedo atravessa o rio por uma ponte de pedra — calçamento por cima, parapeito
## nos lados do rio, um arco por célula e os pilares descendo até o leito; nada de tábua, corrimão nem estaca.
func test_a_paved_street_crosses_the_river_on_a_stone_bridge() -> void:
	_sim = _river_simulation()
	var grid := _sim.world.island(0)
	for cell: Vector2i in RoadPath.l_path(Vector2i(6, 5), Vector2i(11, 5)):
		grid.set_road(cell, IslandGrid.Road.PAVED)
	var view := _view()
	assert_int(view.rail_count()).is_equal(0)
	assert_int(view.post_count()).is_equal(0)
	# duas células de ponte, dois lados abertos cada
	assert_int(view.parapet_count()).is_equal(2 * 2)
	assert_int(view.arch_count()).is_equal(2)
	# meio pilar em cada ponta do arco das duas células (o leito fica abaixo do nascimento)
	assert_int(view.pier_count()).is_equal(2 * 2)
	# o tabuleiro é de paralelepípedo, sem a marca de tábua
	for i: int in view.tile_count():
		var custom := view.multimesh.get_instance_custom_data(i)
		assert_float(custom.r).is_equal(1.0)
		assert_float(custom.g).is_equal(0.0)
	# o arco: a volta abre entre os meios pilares e o fecho fica ARCH_CROWN_M abaixo do tabuleiro
	var size := _sim.config.cell_size_m
	var arch := RoadView.arch_mesh(size)
	var bounds := arch.get_aabb()
	assert_float(bounds.size.x).is_equal_approx(size, 0.001)
	assert_float(bounds.size.y).is_equal_approx(RoadView.arch_rise(size), 0.001)
	var lowest_inside := 0.0
	for vertex: Vector3 in arch.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if absf(vertex.x) < 0.01:
			lowest_inside = minf(lowest_inside, vertex.y)
	assert_float(lowest_inside).is_equal_approx(-RoadView.ARCH_CROWN_M, 0.001)
	# Fase 25: as aduelas saltam da face, nas duas faces, e o fecho salta o dobro e vai até o tabuleiro
	var proud := 0
	var key_proud := 0
	for vertex: Vector3 in arch.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var out := absf(vertex.z) - size * 0.5
		if absf(out - RoadView.VOUSSOIR_PROUD_M) < 0.001:
			proud += 1
		elif absf(out - RoadView.VOUSSOIR_PROUD_M * 2.0) < 0.001 and absf(vertex.y) < 0.001:
			key_proud += 1
	assert_int(proud).is_greater_equal((RoadView.VOUSSOIRS - 1) * 2 * 4)
	assert_int(key_proud).is_greater(0)


func test_a_diagonal_road_gets_a_band_between_the_cells_and_diagonal_ruts() -> void:
	var grid := _sim.world.island(SimFixture.ISLAND)
	for cell: Vector2i in RoadPath.diagonal_path(Vector2i(10, 10), Vector2i(14, 14)):
		grid.set_road(cell, IslandGrid.Road.PAVED)
	var view := _view()
	# as duas pontas e as quatro faixas: as três células do meio da escada só têm as faixas
	assert_int(view.tile_count()).is_equal(2 + 4)
	assert_bool(RoadView.in_diagonal_run(grid, Vector2i(12, 12), RoadView.diagonal_links(grid, Vector2i(12, 12)))).is_true()
	assert_bool(RoadView.in_diagonal_run(grid, Vector2i(10, 10), RoadView.diagonal_links(grid, Vector2i(10, 10)))).is_false()
	assert_int(RoadView.ruts(grid, Vector2i(12, 12))).is_equal(RoadView.Ruts.DIAGONAL_DOWN)
	# a faixa vai do centro de uma célula ao da outra, girada 45°
	var band := RoadView.diagonal_transform(grid, Vector2i(10, 10), Vector2i(1, 1))
	var a := grid.surface_world(Vector2i(10, 10))
	var b := grid.surface_world(Vector2i(11, 11))
	assert_float(band.origin.x).is_equal_approx((a.x + b.x) * 0.5, 0.001)
	assert_float(band.basis.x.length()).is_equal_approx(sqrt(2.0), 0.001)
	assert_float(absf(band.basis.x.normalized().dot(Vector3(1, 0, 1).normalized()))).is_equal_approx(1.0, 0.001)
	# o meio-fio não corta a faixa: só os lados de fora das pontas
	assert_int(view.curb_count()).is_equal(4)


## Fase 19: a terra tem a borda recortada nos lados sem estrada vizinha, com capim ao longo deles; o
## paralelepípedo não tem capim, e nos mesmos lados leva a sarjeta junto do meio-fio de pedra.
func test_dirt_streets_open_their_sides_without_road_and_grow_grass_along_them() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(9, 10))
	SimFixture.road(_sim, Vector2i(5, 11), Vector2i(5, 15))
	var grid := _sim.world.island(SimFixture.ISLAND)
	var none: Array[Vector2i] = []
	assert_int(RoadView.open_edges(grid, Vector2i(2, 10), none)).is_equal(4 | 8)
	assert_int(RoadView.open_edges(grid, Vector2i(0, 10), none)).is_equal(2 | 4 | 8)
	assert_int(RoadView.open_edges(grid, Vector2i(5, 10), none)).is_equal(8)
	var view := _view()
	var sides := 0
	for cell: Vector2i in grid.road_cells():
		for bit: int in RoadView.SIDE_BITS:
			if RoadView.open_edges(grid, cell, none) & bit != 0:
				sides += 1
	assert_int(view.verge_count()).is_equal(sides * RoadView.VERGE_TUFTS)
	for cell: Vector2i in grid.road_cells():
		grid.set_road(cell, IslandGrid.Road.PAVED)
	view.rebuild()
	assert_int(view.verge_count()).is_equal(0)
	# no paralelepípedo os mesmos lados levam a sarjeta (bits no dado da instância) e o meio-fio é de pedra
	var gutters := 0
	for index: int in view.multimesh.instance_count:
		var custom := view.multimesh.get_instance_custom_data(index)
		assert_float(custom.r).is_equal(1.0)
		if custom.b >= RoadView.OPEN_SHIFT:
			gutters += 1
	assert_int(gutters).is_equal(grid.road_cells().size())
	var curb := (view.get_node("Curbs") as MultiMeshInstance3D).multimesh.mesh.surface_get_material(0) as ShaderMaterial
	assert_str(curb.shader.resource_path).is_equal("res://shaders/curb.gdshader")


## Fase 19: na ladeira, o ladrilho inclinado mais a torção passa pelos quatro cantos da célula (os mesmos do
## vizinho: sem degrau entre células).
func test_tiles_pass_through_the_four_corners_of_their_cell_on_a_slope() -> void:
	var grid := IslandGrid.new(Vector2i(6, 6))
	grid.init_terrain()
	grid.flat = false
	for y: int in 7:
		for x: int in 7:
			grid.corner_heights[grid.corner_index(x, y)] = 2.0 + x * 0.3 + y * y * 0.08 + float((x * y) % 3) * 0.2
	grid.invalidate_heights()
	var half := grid.cell_size * 0.5
	var twisted := 0
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(2, 4), Vector2i(4, 2)]:
		var tile := RoadView.tile_transform(grid, cell)
		var twist := RoadView.twist(grid, cell)
		if absf(twist) > 0.05:
			twisted += 1
		for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var local := Vector3((corner.x * 2 - 1) * half, 0.0, (corner.y * 2 - 1) * half)
			var top := (tile * local).y + twist * (corner.x - 0.5) * (corner.y - 0.5)
			assert_float(top - RoadView.LIFT_M - RoadView.THICKNESS_M * 0.5).is_equal_approx(
					grid.corner_height(cell.x + corner.x, cell.y + corner.y), 0.001)
	assert_int(twisted).is_greater(0)


## Fase 20: pedras soltas na terra, fora dos sulcos; o paralelepípedo e a ponte não têm.
func test_dirt_streets_get_loose_stones_off_the_ruts() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(19, 10))
	var grid := _sim.world.island(SimFixture.ISLAND)
	var view := _view()
	var expected := 0
	for cell: Vector2i in grid.road_cells():
		var spots := RoadView.stone_spots(grid, cell, RoadView.ruts(grid, cell))
		assert_int(spots.size()).is_less_equal(RoadView.STONES_MAX)
		expected += spots.size()
		var center := grid.cell_world(cell)
		for spot: Vector3 in spots:
			# a rua corre em x: os sulcos ficam em z = ±rut_offset_m
			var across := absf(spot.z - center.z)
			assert_bool(across < RoadView.RUT_LANE_M.x or across > RoadView.RUT_LANE_M.y) \
					.override_failure_message("pedra no sulco em %s" % cell).is_true()
			assert_float(absf(spot.x - center.x)).is_less_equal(grid.cell_size * 0.5)
	assert_int(expected).is_greater(0)
	assert_int(view.stone_count()).is_equal(expected)
	for cell: Vector2i in grid.road_cells():
		grid.set_road(cell, IslandGrid.Road.PAVED)
	view.rebuild()
	assert_int(view.stone_count()).is_equal(0)
