extends GdUnitTestSuite
## Postes e fogueiras (Fase 13): postes só na rua calçada, na beira da calçada; fogueira atrás de
## parte das casas de camponeses, só com a célula de trás livre; luz de verdade só de noite e perto.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _view() -> LampView:
	var view: LampView = auto_free(LampView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	return view


func _pave(from: Vector2i, to: Vector2i) -> void:
	var grid := _sim.world.island(SimFixture.ISLAND)
	for cell: Vector2i in RoadPath.l_path(from, to):
		grid.set_road(cell, IslandGrid.Road.PAVED)


func test_lamps_stand_by_paved_streets_only() -> void:
	SimFixture.road(_sim, Vector2i(0, 5), Vector2i(79, 5))
	var view := _view()
	assert_int(view.lamp_count()).is_equal(0)
	_pave(Vector2i(0, 20), Vector2i(79, 20))
	view.rebuild()
	# uma a cada LAMP_EVERY células da rua reta
	assert_int(view.lamp_count()).is_between(80 / LampView.LAMP_EVERY - 1, 80 / LampView.LAMP_EVERY + 1)
	var grid := _sim.world.island(SimFixture.ISLAND)
	for point: Vector3 in view.lamp_points():
		var street := grid.cell_world(Vector2i(0, 20))
		# na beira da rua, fora da faixa do meio
		assert_float(absf(point.z - street.z)).is_between(LampView.LAMP_OFFSET_M - 0.01, LampView.LAMP_OFFSET_M + 0.01)
		assert_float(point.y).is_greater(2.0)


func test_bonfires_burn_behind_some_peasant_houses_with_room() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var peasants: Array[int] = []
	for i: int in 9:
		peasants.append(SimFixture.house(_sim, 2 + i * 3, 10, &"peasants", 5.0))
	var workers := SimFixture.house(_sim, 40, 10, &"workers", 5.0)
	var view := _view()
	var expected := peasants.filter(func(id: int) -> bool: return id % LampView.BONFIRE_EVERY == 0).size()
	assert_int(expected).is_greater(0)
	assert_int(view.bonfire_count()).is_equal(expected)
	var grid := _sim.world.island(SimFixture.ISLAND)
	for point: Vector3 in view.fire_points():
		var cell := Vector2i(floori(point.x / 2.0), floori(point.z / 2.0))
		assert_int(grid.building_at(cell)).is_equal(0)
		assert_bool(grid.has_road(cell)).is_false()
	assert_object(LampView.bonfire_spot(_sim, _sim.world.building(workers))).is_not_null()
	# com campo atrás não tem fogueira
	var house := _sim.world.building(peasants[0])
	var spot: Variant = LampView.bonfire_spot(_sim, house)
	assert_bool(spot is Vector3).is_true()
	var behind_point: Vector3 = spot
	# as casas da fixture olham para +Z (rotação 2): a célula de trás é a de cima do campo de 3 × 3
	SimFixture.place(_sim, &"field", Vector2i(floori(behind_point.x / 2.0) - 1, floori(behind_point.z / 2.0) - 2), 0)
	assert_object(LampView.bonfire_spot(_sim, house)).is_null()


func test_real_lights_only_at_night_and_close() -> void:
	_pave(Vector2i(0, 20), Vector2i(79, 20))
	var view := _view()
	var above := Vector3(40.0, 40.0, 70.0)
	var down := (Vector3(40.0, 0.0, 40.0) - above).normalized()
	view.place_lights(above, down, 1.0)
	assert_int(view.lit_lights()).is_equal(mini(LampView.LIGHTS, view.lamp_count()))
	view.place_lights(above, down, 0.0)
	assert_int(view.lit_lights()).is_equal(0)
	var far := Vector3(40.0, 400.0, 400.0)
	view.place_lights(far, (Vector3(40.0, 0.0, 40.0) - far).normalized(), 1.0)
	assert_int(view.lit_lights()).is_equal(0)


func test_new_streets_light_up_without_rebuilding_by_hand() -> void:
	var view := _view()
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(79, 20))
	_sim.execute(BuildRoadCommand.new(SimFixture.ISLAND, RoadPath.l_path(Vector2i(0, 20), Vector2i(79, 20)), true))
	await await_idle_frame()
	await await_idle_frame()
	assert_int(view.lamp_count()).is_greater(0)


func test_the_cast_iron_post_holds_the_glass_in_its_lantern() -> void:
	var post := LampView.post_mesh().get_aabb()
	assert_float(post.position.y).is_equal_approx(0.0, 0.01)
	assert_float(post.end.y).is_equal_approx(LampView.LAMP_HEIGHT_M, 0.01)
	# o vidro fica dentro dos montantes e debaixo do chapéu
	var glass := LampView.glass_mesh().get_aabb()
	assert_float(glass.position.y).is_greater(LampView.LAMP_HEIGHT_M * 0.75)
	assert_float(glass.end.y).is_less(post.end.y)
	assert_float(glass.size.x).is_less_equal(post.size.x)
	# a travessa da escada é a parte mais larga do poste
	assert_float(post.size.x).is_between(0.6, 0.7)
	assert_int((LampView.post_mesh().surface_get_material(0) as StandardMaterial3D).albedo_color.to_rgba32()) \
			.is_equal(LampView.IRON_COLOR.to_rgba32())


## Fase 24: o ornamento fundido — caneluras no fuste e as duas volutas debaixo da travessa da escada.
func test_the_post_has_a_fluted_shaft_and_scrolls_under_the_ladder_bar() -> void:
	# na seção do fuste o raio alterna o cheio e o fundo da canelura
	var radii := {}
	for vertex: Vector3 in LampView.fluted_shaft(0.0, 1.0, 0.1, 0.1).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		radii[snappedf(Vector2(vertex.x, vertex.z).length(), 0.001)] = true
	assert_array(radii.keys()).contains_exactly_in_any_order([0.1, snappedf(0.1 * (1.0 - LampView.FLUTE_DEPTH), 0.001)])
	# a voluta sai do fuste, chega debaixo da ponta da travessa e se enrola para dentro dela
	var points := LampView.volute_points(2.0)
	assert_float(points[0].x).is_less(0.07)
	assert_float(points[0].y).is_less(1.7)
	var highest := -INF
	for point: Vector2 in points:
		highest = maxf(highest, point.y)
		assert_float(point.x).is_between(0.0, 0.31)
	assert_float(highest).is_equal_approx(2.0, 0.001)
	assert_float(points[points.size() - 1].y).is_less(2.0)
	# as duas volutas estão no poste: há ferro debaixo da travessa, longe do fuste, dos dois lados
	var glass_low := LampView.LAMP_HEIGHT_M * (LampView.GLASS_HEIGHT - LampView.GLASS_SPAN * 0.5)
	var left := false
	var right := false
	for vertex: Vector3 in LampView.post_mesh().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if vertex.y < glass_low - 0.3 and absf(vertex.x) > 0.15:
			left = left or vertex.x < 0.0
			right = right or vertex.x > 0.0
	assert_bool(left and right).is_true()
	# o fuste é desenhado: algum triângulo do poste usa o fundo de canelura do alto do fuste
	var arrays := LampView.post_mesh().surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var groove := 0.045 * (1.0 - LampView.FLUTE_DEPTH)
	var drawn := false
	for index: int in arrays[Mesh.ARRAY_INDEX]:
		var vertex := vertices[index]
		if absf(vertex.y - (glass_low - 0.3)) < 0.01 and absf(Vector2(vertex.x, vertex.z).length() - groove) < 0.001:
			drawn = true
			break
	assert_bool(drawn).is_true()


## Fase 26: base e capitel torneados — o perfil girado em LATHE_SIDES faces, com o toro da base saltando sobre a
## escócia e o equino do capitel abrindo debaixo do colar do lampião.
func test_the_post_has_a_turned_base_and_a_capital() -> void:
	# cada ponto do perfil vira um anel de LATHE_SIDES vértices no raio dele
	var turned := LampView.lathe(LampView.BASE_PROFILE)
	var rings := {}
	for vertex: Vector3 in turned.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		rings[Vector2(snappedf(Vector2(vertex.x, vertex.z).length(), 0.001), snappedf(vertex.y, 0.001))] = true
	for point: Vector2 in LampView.BASE_PROFILE:
		var key := Vector2(snappedf(point.x, 0.001), snappedf(point.y, 0.001))
		assert_bool(rings.has(key)).override_failure_message(str(point)).is_true()
	# o toro (o mais largo acima do plinto) passa da escócia logo acima dele
	var torus := 0.0
	var scotia := INF
	for point: Vector2 in LampView.BASE_PROFILE:
		if point.y > 0.085 and point.y < 0.145:
			torus = maxf(torus, point.x)
		elif point.y >= 0.145 and point.y <= 0.17:
			scotia = minf(scotia, point.x)
	assert_float(torus).is_greater(scotia + 0.03)
	# no poste: a base acaba no raio do pé do fuste, e o capitel abre além do colar de antes (0,08) debaixo
	# do colar do lampião
	assert_float(LampView.BASE_PROFILE[LampView.BASE_PROFILE.size() - 1].x).is_equal_approx(0.065, 0.001)
	var glass_low := LampView.LAMP_HEIGHT_M * (LampView.GLASS_HEIGHT - LampView.GLASS_SPAN * 0.5)
	var widest := 0.0
	for vertex: Vector3 in LampView.post_mesh().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if vertex.y > glass_low - 0.32 and vertex.y < glass_low - 0.22 and absf(vertex.z) > 0.02:
			widest = maxf(widest, Vector2(vertex.x, vertex.z).length())
	assert_float(widest).is_greater(0.09)
