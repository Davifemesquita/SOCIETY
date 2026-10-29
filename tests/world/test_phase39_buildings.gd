extends GdUnitTestSuite
## Prédios assentados (Fase 39): a variação visual sai do id, do tipo e da rotação, nunca muda lote, porta nem andares;
## casas em fila não repetem a altura do telhado; toda janela tem vidro; o entreposto é armazém; a casa de camponeses
## recua das divisas; o prédio no barranco senta no canto mais alto com plinto e degraus; a fachada encostada num
## vizinho escurece; e nada disso mexe na simulação.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.ignore_terrain = true


func _record(id: int, def_id: StringName, tier: StringName = &"workers", rotation: int = 0) -> BuildingRecord:
	var record := BuildingRecord.new(id, def_id, 0, Vector2i(10, 10), rotation)
	# só a casa tem classe (is_house é ter classe)
	if def_id == &"house":
		record.tier = tier
	return record


func _spec(record: BuildingRecord) -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, record, 2.0)


## Triângulos da malha cuja UV cai na célula da paleta (vidro, madeira...).
func _triangles_with_uv(mesh: ArrayMesh, uv: Vector2) -> int:
	var cell := Vector2i(floori(uv.x * 8.0), floori(uv.y * 4.0))
	var arrays := mesh.surface_get_arrays(0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var count := 0
	for i: int in range(0, indices.size(), 3):
		var at := uvs[indices[i]]
		if Vector2i(floori(at.x * 8.0), floori(at.y * 4.0)) == cell:
			count += 1
	return count


func test_the_variation_is_stable_and_never_changes_lot_door_or_floors() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		var base := _spec(_record(1, &"house", tier))
		for id: int in range(1, 40):
			for rotation: int in 4:
				var spec := _spec(_record(id, &"house", tier, rotation))
				var again := _spec(_record(id, &"house", tier, rotation))
				assert_str(spec.key()).is_equal(again.key())
				assert_that(spec.cells).is_equal(base.cells)
				assert_int(spec.floors()).is_equal(base.floors())
				assert_float(spec.height_m).is_equal(base.height_m)
				assert_int(spec.door).is_equal(base.door)
				assert_float(BuildingKit.door_position(spec).z).is_equal_approx(BuildingKit.door_position(base).z, 0.001)
				assert_float(spec.overhang_m).is_between(0.3, 0.5)
				var record := _record(id, &"house", tier, rotation)
				assert_int(BuildingView.palette_of(record)).is_equal(BuildingView.palette_of(_record(id, &"house", tier, rotation)))
				assert_int(BuildingView.palette_of(record)).is_between(0, BuildingView.PALETTES - 1)


func test_houses_in_a_row_never_share_the_ridge_height() -> void:
	# casas construídas em fila têm ids seguidos
	for id: int in range(1, 30):
		var spec := _spec(_record(id, &"house"))
		var next := _spec(_record(id + 1, &"house"))
		assert_float(absf(spec.roof_m - next.roof_m)).override_failure_message("ids %d e %d" % [id, id + 1]).is_greater(0.1)
	# e há casas de três alturas de telhado, beirais diferentes, chaminés e lucarnas
	var ridges: Dictionary[float, bool] = {}
	var overhangs: Dictionary[float, bool] = {}
	var chimneys := 0
	var lucarnes := 0
	for id: int in range(1, 200):
		var spec := _spec(_record(id, &"house", &"artisans"))
		ridges[snappedf(spec.roof_m, 0.01)] = true
		overhangs[spec.overhang_m] = true
		chimneys += int(spec.chimney)
		lucarnes += int(spec.lucarnes > 0)
	assert_int(ridges.size()).is_equal(3)
	assert_int(overhangs.size()).is_equal(3)
	assert_int(chimneys).is_greater(40)
	assert_int(lucarnes).is_greater(20)


func test_the_overhang_reaches_the_mesh() -> void:
	for id: int in range(1, 12):
		var spec := _spec(_record(id, &"house"))
		if spec.roof != BuildingKit.Roof.GABLE_X:
			continue
		var box := BuildingKit.mesh(spec).get_aabb()
		# a cumeeira em x: a água passa da empena pelo beiral
		assert_float(box.end.x).is_greater_equal(spec.size_m().x * 0.5 + spec.overhang_m - 0.01)


func test_every_window_has_glass_and_a_cross_of_wood() -> void:
	for def_id: StringName in [&"house", &"bakery", &"hospital", &"trading_post"]:
		var record := _record(5, def_id)
		var spec := _spec(record)
		var mesh := BuildingKit.mesh(spec)
		var glass := _triangles_with_uv(mesh, BuildingKit.UV_GLASS)
		var windows := BuildingKit.windows(spec).size()
		assert_int(windows).override_failure_message(String(def_id)).is_greater(0)
		assert_int(glass).override_failure_message(String(def_id)).is_equal(windows * 2 + spec.lucarnes * 2)


func test_lucarnes_sit_on_the_roof() -> void:
	var found := false
	for id: int in range(1, 200):
		var spec := _spec(_record(id, &"house", &"artisans"))
		if spec.lucarnes == 0:
			continue
		found = true
		var plain := _spec(_record(id, &"house", &"artisans"))
		plain.lucarnes = 0
		assert_int(BuildingKit.triangles(spec)).is_greater(BuildingKit.triangles(plain))
		# a lucarna não passa da cumeeira
		assert_float(BuildingKit.mesh(spec).get_aabb().end.y).is_less_equal(BuildingKit.mesh(plain).get_aabb().end.y + 0.01)
		break
	assert_bool(found).is_true()


func test_the_trading_post_reads_as_a_storehouse() -> void:
	var spec := _spec(_record(3, &"trading_post"))
	assert_bool(spec.storehouse).is_true()
	assert_int(spec.roof).is_equal(BuildingKit.Roof.GABLE_Z)
	# portas de carga alternadas no térreo e as do sótão sobre a porta
	for index: int in spec.cells.x:
		var expected := "arch" if index % 2 == spec.door_index % 2 else "window"
		assert_str(String(BuildingKit.slot(spec, 0, index, 0))).is_equal(expected)
	for level: int in range(1, spec.floors()):
		assert_str(String(BuildingKit.slot(spec, 0, spec.door_index, level))).is_equal("plain")
	var warehouse := _spec(_record(4, &"warehouse"))
	assert_bool(warehouse.storehouse).is_false()


func test_peasant_houses_step_back_from_the_side_lines() -> void:
	var cottage := _spec(_record(7, &"house", &"peasants"))
	var lot := cottage.cells.x * cottage.cell_m
	var hall := cottage.hall()
	assert_float(hall.size_m().x).is_equal_approx(lot - BuildingKit.INSET_M - BuildingKit.YARD_SIDE_GAP_M * 2.0, 0.001)
	# duas casas vizinhas ficam a mais de um metro uma da outra
	assert_float(lot - hall.size_m().x).is_greater(1.2)
	# a cerca segue na borda do lote e a porta no meio
	assert_float(BuildingKit.mesh(cottage).get_aabb().size.x).is_greater(lot - 0.5)
	assert_float(BuildingKit.door_position(cottage).x).is_equal_approx(0.0, 0.001)


## Ilha com rampa: a altura cai MAX_DROP_M por célula para −z (a frente da casa de rotação 0).
func _sloped_island(drop_per_cell: float) -> IslandGrid:
	var grid := _sim.world.island(0)
	grid.init_terrain()
	for y: int in grid.size.y + 1:
		for x: int in grid.size.x + 1:
			grid.corner_heights[y * (grid.size.x + 1) + x] = 2.0 + y * drop_per_cell
	grid.invalidate_heights()
	return grid


func test_a_house_on_a_slope_sits_on_its_highest_corner_with_plinth_and_steps() -> void:
	var grid := _sloped_island(0.15)
	var house := SimFixture.place(_sim, &"house", Vector2i(20, 20), 0)
	_sim.world.building(house).tier = &"workers"
	var flat := SimFixture.place(_sim, &"house", Vector2i(40, 20), 0)
	_sim.world.building(flat).tier = &"workers"
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, 2.0)
	var record := _sim.world.building(house)
	var area := Footprint.rect(record.origin, Vector2i(3, 3), 0)
	var corners := BuildingKit.corner_range(grid, area)
	assert_float(corners.y - corners.x).is_equal_approx(0.45, 0.001)
	var root := view.building_node(house)
	assert_float(root.position.y).is_equal_approx(corners.y, 0.001)
	var plinth := view.plinth_of(house)
	assert_bool(plinth.is_empty()).is_false()
	var mesh: ArrayMesh = plinth[0]
	var place: Transform3D = plinth[1]
	assert_float(place.origin.y).is_equal_approx(corners.y, 0.001)
	# a pedra desce até abaixo do canto mais baixo
	assert_float(mesh.get_aabb().position.y).is_less_equal(corners.x - corners.y - BuildingKit.PLINTH_BELOW_M + 0.06)
	# a frente (−z) é o lado baixo: degraus saem da fachada
	var spec := BuildingKit.spec_for(_sim, record, 2.0)
	assert_float(mesh.get_aabb().position.z).is_less(-spec.size_m().y * 0.5 - BuildingKit.STEP_TREAD_M)
	# todos os plintos numa malha só
	view.rebuild_plinths()
	var layer := view.get_node(^"Plinths") as MeshInstance3D
	var joined := layer.mesh as ArrayMesh
	assert_int(joined.surface_get_array_len(0)).is_greater_equal(mesh.surface_get_array_len(0))
	# a janela acesa acompanha o piso
	var windows := WindowLightsView.building_windows(_sim, record)
	var lowest := INF
	for window: Transform3D in windows:
		lowest = minf(lowest, window.origin.y)
	assert_float(lowest).is_greater(corners.y)
	# no plano não há plinto
	var level_island := _sim.world.island(0)
	for y: int in level_island.size.y + 1:
		for x: int in range(38, 45):
			level_island.corner_heights[y * (level_island.size.x + 1) + x] = 5.0
	level_island.invalidate_heights()
	view.rebuild()
	assert_bool(view.plinth_of(flat).is_empty()).is_true()
	assert_int(view.plinth_count()).is_equal(1)
	remove_child(view)


func test_steps_follow_the_drop_at_the_door() -> void:
	assert_int(BuildingKit.steps_for(0.0)).is_equal(0)
	assert_int(BuildingKit.steps_for(0.1)).is_equal(0)
	assert_int(BuildingKit.steps_for(0.4)).is_between(1, 3)
	assert_int(BuildingKit.steps_for(3.0)).is_equal(BuildingKit.MAX_STEPS)
	var spec := _spec(_record(2, &"house"))
	# a mesma forma e as mesmas medidas (arredondadas) dividem a malha
	assert_object(BuildingKit.plinth(spec, 0.81, 0.4)).is_same(BuildingKit.plinth(spec, 0.8, 0.41))


func test_a_wall_facing_a_neighbour_gets_the_contact_shade() -> void:
	var left := SimFixture.place(_sim, &"house", Vector2i(10, 10), 0)
	var right := SimFixture.place(_sim, &"house", Vector2i(13, 10), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, 2.0)
	var model := view.building_node(left).get_node(^"Model") as MeshInstance3D
	var shade: Vector4 = model.get_instance_shader_parameter(&"side_shade")
	# a fachada +X da casa da esquerda (rotação 0) dá para a vizinha inteira; as outras para o vazio
	assert_float(shade.y).is_equal_approx(1.0, 0.001)
	assert_float(shade.x + shade.z + shade.w).is_equal(0.0)
	# na vizinha, a mesma divisa é a fachada −X
	var turned := BuildingView.side_shade(_sim, _sim.world.building(right))
	assert_float(turned.w).is_equal_approx(1.0, 0.001)
	_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(13, 10), Vector2i(1, 1))))
	shade = model.get_instance_shader_parameter(&"side_shade")
	assert_float(shade.y).is_equal(0.0)
	# o campo não faz sombra
	SimFixture.place(_sim, &"field", Vector2i(13, 10), 0)
	assert_float(BuildingView.side_shade(_sim, _sim.world.building(left)).y).is_equal(0.0)
	remove_child(view)


func test_palettes_and_the_inverted_trim_reach_the_instance() -> void:
	var seen: Dictionary[int, bool] = {}
	var inverted := 0
	for id: int in range(1, 120):
		var record := _record(id, &"house", &"artisans")
		seen[BuildingView.palette_of(record)] = true
		inverted += int(BuildingView.inverted(record, BuildingMaterials.Wall.PLASTER))
		# madeira nunca é invertida
		assert_bool(BuildingView.inverted(record, BuildingMaterials.Wall.WOOD)).is_false()
	assert_int(seen.size()).is_equal(BuildingView.PALETTES)
	assert_int(inverted).is_between(10, 45)
	# a paleta 0 é o tom de antes
	var color := Color(0.6, 0.5, 0.4)
	assert_bool(BuildingView.palette_wall(color, 0, true).is_equal_approx(color)).is_true()
	assert_bool(BuildingView.palette_wall(color, 2, true).is_equal_approx(color)).is_false()


func test_the_view_does_not_touch_the_simulation() -> void:
	_sloped_island(0.1)
	for x: int in range(2, 60, 3):
		SimFixture.place(_sim, &"house", Vector2i(x, 20), 0)
	SimFixture.place(_sim, &"trading_post", Vector2i(10, 30), 0)
	var state := var_to_str(_sim.world.to_dict())
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, 2.0)
	view.rebuild()
	assert_str(var_to_str(_sim.world.to_dict())).is_equal(state)
	remove_child(view)


func test_varied_houses_build_in_reasonable_time() -> void:
	var started := Time.get_ticks_msec()
	var before := BuildingKit.cached_meshes()
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		for id: int in range(1, 121):
			BuildingKit.mesh(_spec(_record(id, &"house", tier)))
	var elapsed := Time.get_ticks_msec() - started
	var made := BuildingKit.cached_meshes() - before
	print("Fase 39: 600 casas variadas em %d ms, %d malhas novas no cache" % [elapsed, made])
	# a variação cabe em 3 telhados × 3 degraus × 2 janelas por classe, com e sem a ala (Fase 96), e com e sem a loja de
	# toldo nos artesãos e engenheiros (Fase 101)
	assert_int(made).is_less_equal(5 * 18 * 2 + 2 * 18 * 2)
