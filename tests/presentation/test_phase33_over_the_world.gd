extends GdUnitTestSuite
## Por cima do mundo (Fase 33): a grade fica no chão e só perto do cursor (as células destacadas é que atravessam), a
## prévia mostra o modelo do prédio com listras quando não pode, e os ícones de estado iguais viram um só de longe.


func test_grid_lines_keep_the_depth_test_and_only_highlighted_cells_cross() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 40))
	var overlay: DebugOverlay = auto_free(DebugOverlay.new())
	overlay.setup(sim, sim.config.cell_size_m, sim.config.build_grid_radius_m)
	overlay.grid_visible = true
	assert_object(overlay.material_override).is_same(overlay.lines_material())
	assert_object(overlay.material_overlay).is_null()
	# as linhas nunca vão para o raio-X: era assim que a grade da ilha toda passava por cima das copas
	assert_str(overlay.lines_material().shader.code).not_contains("depth_test_disabled")
	assert_bool(overlay.lines_material().get_shader_parameter(&"show_lines")).is_true()
	var cells := Image.create_empty(40, 40, false, Image.FORMAT_RGBA8)
	cells.set_pixel(5, 5, Color.ORANGE)
	overlay.show_custom(cells)
	assert_object(overlay.material_override).is_same(overlay.lines_material())
	assert_object(overlay.material_overlay).is_same(overlay.cells_material())
	assert_str(overlay.cells_material().shader.code).contains("depth_test_disabled")
	assert_bool(overlay.cells_material().get_shader_parameter(&"show_lines")).is_false()
	# sem a ferramenta, o destaque fica e as linhas somem
	overlay.grid_visible = false
	assert_bool(overlay.visible).is_true()
	assert_bool(overlay.lines_material().get_shader_parameter(&"show_lines")).is_false()
	overlay.clear_custom()
	assert_object(overlay.material_overlay).is_null()
	assert_bool(overlay.visible).is_false()


func test_grid_lines_follow_the_cursor() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 40))
	var overlay: DebugOverlay = auto_free(DebugOverlay.new())
	overlay.setup(sim, sim.config.cell_size_m, sim.config.build_grid_radius_m)
	assert_float(overlay.lines_material().get_shader_parameter(&"focus_radius_m")).is_equal(sim.config.build_grid_radius_m)
	overlay.set_focus(Vector3(12.0, 3.0, 34.0))
	assert_vector(overlay.lines_material().get_shader_parameter(&"focus_point")).is_equal(Vector2(12.0, 34.0))


func test_preview_shows_the_building_model_and_stripes_when_refused() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 40))
	var tool: BuildTool = auto_free(BuildTool.new())
	tool.setup(sim, null, sim.config.cell_size_m)
	var preview: BuildPreviewView = auto_free(BuildPreviewView.new())
	preview.setup(tool, sim.config.cell_size_m, sim)
	tool.start_building(sim.data.building(&"house"))
	tool.hover(Vector2i(10, 10))
	assert_bool(preview.shows_model()).is_equal(BuildingKit.available())
	assert_bool(preview.is_striped()).is_false()
	# outro prédio no lugar: não pode, e a prévia diz isso pelo padrão, não só pela cor
	SimFixture.place(sim, &"house", tool.building_origin(), tool.rotation)
	assert_bool(preview.is_striped()).is_true()
	tool.start_demolish()
	assert_bool(preview.is_striped()).is_true()
	assert_bool(preview.shows_model()).is_false()


func test_far_status_icons_merge_by_reason_and_square() -> void:
	var config := GameConfig.new()
	var points: Dictionary[int, Vector3] = {}
	var keys: Dictionary[int, String] = {}
	# uma fila de oito casas sem estrada, de 6 em 6 m, e um lenhador sem árvores no meio delas
	for index: int in 8:
		points[index + 1] = Vector3(index * 6.0, 8.0, 0.0)
		keys[index + 1] = "LABEL_NO_ROAD"
	points[20] = Vector3(10.0, 8.0, 0.0)
	keys[20] = "LABEL_NO_TREES"
	# perto: cada um, inteiro
	var near := StatusIconRule.alphas(points, keys, Vector3(20.0, 40.0, 30.0), config)
	assert_int(near.size()).is_equal(points.size())
	for building_id: int in near:
		assert_float(near[building_id]).is_equal(1.0)
	# a 110 m: um ícone por motivo em cada quadrado, esmaecido
	var camera := Vector3(20.0, 80.0, 75.0)
	var far := StatusIconRule.alphas(points, keys, camera, config)
	assert_int(far.size()).is_less(5)
	assert_bool(far.has(20)).is_true()
	var no_road := far.keys().filter(func(building_id: int) -> bool: return keys[building_id] == "LABEL_NO_ROAD")
	assert_int(no_road.size()).is_between(1, 2)
	for building_id: int in far:
		assert_float(far[building_id]).is_less(1.0)
		assert_float(far[building_id]).is_greater_equal(config.status_icon_min_alpha)
	# o do cursor e o selecionado sempre aparecem; com a camada do mapa, todos
	var always := StatusIconRule.alphas(points, keys, camera, config, [5, 6])
	assert_float(always.get(5, 0.0)).is_equal(1.0)
	assert_float(always.get(6, 0.0)).is_equal(1.0)
	assert_int(StatusIconRule.alphas(points, keys, camera, config, [], true).size()).is_equal(points.size())
	# bem longe, o agregado não some: fica em min_alpha
	assert_float(StatusIconRule.fade(5000.0, config)).is_equal_approx(config.status_icon_min_alpha, 0.0001)


func test_building_view_applies_the_icon_rule() -> void:
	var sim := SimFixture.simulation(Vector2i(80, 40))
	var houses: Array[int] = []
	for index: int in 6:
		houses.append(SimFixture.place(sim, &"house", Vector2i(4 + index * 3, 10)))
	var view: BuildingView = auto_free(BuildingView.new())
	view.setup(sim, sim.config.cell_size_m)
	view.refresh_labels()
	var center := Vector3(25.0, 0.0, 22.0)
	view.apply_icon_rule(center + Vector3(0.0, 30.0, 10.0))
	for house_id: int in houses:
		assert_object(view.status_icon(house_id)).override_failure_message("casa %d sem ícone de perto" % house_id).is_not_null()
	view.apply_icon_rule(center + Vector3(0.0, 250.0, 150.0))
	var shown := houses.filter(func(house_id: int) -> bool: return view.status_icon(house_id) != null)
	assert_int(shown.size()).is_between(1, 2)
	var first: int = shown[0]
	assert_float(view.status_icon(first).modulate.a).is_less(1.0)
	view.hovered_id = houses[5]
	view.apply_icon_rule(center + Vector3(0.0, 250.0, 150.0))
	assert_object(view.status_icon(houses[5])).is_not_null()
	view.show_all_icons = true
	view.apply_icon_rule(center + Vector3(0.0, 250.0, 150.0))
	for house_id: int in houses:
		assert_object(view.status_icon(house_id)).is_not_null()
