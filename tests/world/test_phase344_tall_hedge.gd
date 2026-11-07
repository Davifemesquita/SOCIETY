extends GdUnitTestSuite
## Sebe alta (Fase 344): a sebe entre as fazendas mais alta e irregular (a malha com massas de tamanhos diferentes, cada lanço de uma
## altura) e, de vez em quando, uma moita alta como uma árvore pequena.


func test_the_hedge_piece_is_taller_and_lumpy() -> void:
	var box := CropView.hedge_mesh().get_aabb()
	# era ~0,84 m
	assert_float(box.end.y).is_greater(1.1)
	# um pouco mais que o metro do lanço: as massas emendam com as vizinhas
	assert_float(box.size.x).is_between(0.9, 1.6)


func test_the_pieces_vary_and_some_grow_into_small_trees() -> void:
	var sim := SimFixture.simulation()
	var view: CropView = auto_free(CropView.new())
	add_child(view)
	view.setup(sim)
	var grid := sim.world.island(SimFixture.ISLAND)
	var hedges: Array = []
	var walls: Array = []
	for y: int in 6:
		view._border_pieces(grid, Vector2i(20, 20 + y * 3), Vector2i(1, 0), false, hedges, walls)
		view._border_pieces(grid, Vector2i(30, 20 + y * 3), Vector2i(0, 1), false, hedges, walls)
		view._border_pieces(grid, Vector2i(40, 20 + y * 3), Vector2i(-1, 0), false, hedges, walls)
		view._border_pieces(grid, Vector2i(50, 20 + y * 3), Vector2i(0, -1), false, hedges, walls)
	var low := INF
	var high := 0.0
	var trees := 0
	for item: Array in hedges:
		var place: Transform3D = item[0]
		var height := place.basis.y.length()
		low = minf(low, height)
		high = maxf(high, height)
		if is_equal_approx(height, CropView.HEDGE_TREE_SCALE.y):
			trees += 1
	assert_float(high - low).is_greater(0.4)
	assert_int(trees).is_greater(0)
	assert_int(trees).is_less(hedges.size() / 3)
