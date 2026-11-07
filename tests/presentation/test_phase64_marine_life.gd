extends GdUnitTestSuite
## Vida no mar (Fase 64): as malhas da baleia e do golfinho no tamanho, os lugares no mar aberto (baleia) e em águas
## médias (golfinho) pelo campo da costa, a baleia que sobe, sopra, mergulha com a cauda erguida e some, e o golfinho
## que salta em arco e volta para o fundo.

const SIDE := 300
const SPACING := 2.0
## Ilha redonda no meio do campo: terra até 60 m do centro, depois água cada vez mais longe da costa.
const CENTER := Vector2(300.0, 300.0)


func _coast() -> CoastField:
	var field := CoastField.new()
	field.spacing = SPACING
	field.size = Vector2i(SIDE, SIDE)
	field.max_m = 64.0
	field.distances.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			var r := (Vector2(x, y) * SPACING).distance_to(CENTER)
			field.distances[y * SIDE + x] = clampf(60.0 - r, -64.0, 64.0)
	return field


func test_the_meshes_have_the_right_size() -> void:
	var whale := MarineLifeView.whale_mesh().get_aabb()
	var dolphin := MarineLifeView.dolphin_mesh().get_aabb()
	assert_float(whale.size.z).is_between(MarineLifeView.WHALE_LENGTH_M, MarineLifeView.WHALE_LENGTH_M * 1.25)
	assert_float(whale.size.x).is_greater(3.0)
	assert_float(dolphin.size.z).is_between(MarineLifeView.DOLPHIN_LENGTH_M, MarineLifeView.DOLPHIN_LENGTH_M * 1.3)
	# o golfinho tem a nadadeira dorsal: mais alto em cima que embaixo
	assert_float(dolphin.end.y).is_greater(-dolphin.position.y + 0.2)


func test_sites_follow_the_coast_distance() -> void:
	var field := _coast()
	var area := Rect2(Vector2.ZERO, Vector2(SIDE, SIDE) * SPACING)
	var whales := MarineLifeView.sites(field, area, 4, -INF, MarineLifeView.WHALE_COAST_M, 7)
	var dolphins := MarineLifeView.sites(field, area, 3, MarineLifeView.DOLPHIN_COAST_M.x, MarineLifeView.DOLPHIN_COAST_M.y, 7)
	assert_int(whales.size()).is_equal(4)
	assert_int(dolphins.size()).is_equal(3)
	for site: Vector3 in whales:
		assert_float(field.at(site.x, site.z)).is_less_equal(MarineLifeView.WHALE_COAST_M)
	for site: Vector3 in dolphins:
		assert_float(field.at(site.x, site.z)).is_between(MarineLifeView.DOLPHIN_COAST_M.x, MarineLifeView.DOLPHIN_COAST_M.y)
	# a mesma semente dá os mesmos lugares
	assert_array(MarineLifeView.sites(field, area, 4, -INF, MarineLifeView.WHALE_COAST_M, 7)).is_equal(whales)


func test_the_whale_surfaces_dives_tail_up_and_disappears() -> void:
	var site := Vector3(1000.0, 0.0, 1000.0)
	var head := Vector3(0.0, 0.0, MarineLifeView.WHALE_LENGTH_M * 0.4)
	var tail := Vector3(0.0, 0.0, -MarineLifeView.WHALE_LENGTH_M * 0.5)
	# à tona: dorso de fora (o topo do corpo acima d'água), nivelada
	var up := MarineLifeView.whale_pose(site, 0, 2.0)
	assert_float(up.origin.y).is_between(-1.0, -0.4)
	assert_float(absf((up * head).y - (up * tail).y)).is_less(0.5)
	# mergulhando: a cauda acima da cabeça
	var dive := MarineLifeView.whale_pose(site, 0, MarineLifeView.WHALE_SURFACE_S + MarineLifeView.WHALE_DIVE_S * 0.8)
	assert_float((dive * tail).y).is_greater((dive * head).y + 4.0)
	assert_float((dive * tail).y).is_greater(0.0)
	# no fundo, sumida
	var deep := MarineLifeView.whale_pose(site, 0, MarineLifeView.WHALE_CYCLE_S * 0.7)
	assert_float(deep.basis.determinant()).is_equal(0.0)
	# nada no círculo em volta do lugar
	assert_float(Vector2(up.origin.x - site.x, up.origin.z - site.z).length()).is_less(MarineLifeView.WHALE_CIRCLE_M + 15.0)


func test_the_dolphin_jumps_in_an_arc() -> void:
	var site := Vector3(500.0, 0.0, 500.0)
	var start := -1.0
	for step: int in 400:
		var time := step * 0.01
		if MarineLifeView.dolphin_pose(site, 0, 0, time).basis.determinant() != 0.0:
			start = time
			break
	assert_float(start).is_greater_equal(0.0)
	var rising := MarineLifeView.dolphin_pose(site, 0, 0, start + MarineLifeView.DOLPHIN_JUMP_S * 0.2)
	var top := MarineLifeView.dolphin_pose(site, 0, 0, start + MarineLifeView.DOLPHIN_JUMP_S * 0.5)
	var falling := MarineLifeView.dolphin_pose(site, 0, 0, start + MarineLifeView.DOLPHIN_JUMP_S * 0.8)
	assert_float(top.origin.y).is_greater(MarineLifeView.DOLPHIN_JUMP_M * 0.8)
	# o nariz (+z) aponta para cima na subida e para baixo na descida
	assert_float(rising.basis.z.y).is_greater(0.1)
	assert_float(falling.basis.z.y).is_less(-0.1)
	assert_float(MarineLifeView.dolphin_pose(site, 0, 0, start + MarineLifeView.DOLPHIN_JUMP_S + 0.5).basis.determinant()).is_equal(0.0)


func test_the_view_places_the_animals_and_the_spout_fires_on_surfacing() -> void:
	var view: MarineLifeView = auto_free(MarineLifeView.new())
	add_child(view)
	view.setup(_coast(), Rect2(Vector2(150.0, 150.0), Vector2(300.0, 300.0)), 1840)
	assert_int(view.whale_count()).is_equal(MarineLifeView.WHALES)
	assert_int(view.pod_count()).is_equal(MarineLifeView.DOLPHIN_PODS)
	# a baleia 0 sobe no começo do ciclo: depois de um ciclo inteiro, o esguicho sai de novo
	view.advance(MarineLifeView.WHALE_CYCLE_S - 0.5)
	view.advance(1.0)
	assert_bool(view.spouting(0)).is_true()
	assert_float(view.whale_transform(0).basis.determinant()).is_not_equal(0.0)
	remove_child(view)
