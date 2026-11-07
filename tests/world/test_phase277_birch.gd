extends GdUnitTestSuite
## Bétula (Fase 277): a espécie nova no fim do enum, de pé no chão, no tamanho e no orçamento das outras, com o tronco branco
## (o pé escuro e as manchas pretas só de perto), mais fina que o carvalho; e a mata escolhendo bétula mais na beira e na terra
## baixa, com carvalho e faia no resto.

const BIRCH := TreeModel.Species.BIRCH


func _triangles(mesh: ArrayMesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	return points.size() / 3


func _colors(mesh: ArrayMesh) -> PackedColorArray:
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]


func test_the_birch_is_the_last_species() -> void:
	assert_int(BIRCH).is_greater(TreeModel.Species.NORWAY_SPRUCE)


func test_the_birch_stands_on_the_ground_in_its_size_and_budget() -> void:
	for variant: int in TreeModel.VARIANTS:
		var mesh := TreeModel.mesh(BIRCH, variant)
		var box := mesh.get_aabb()
		assert_float(box.position.y).is_between(-0.2, 0.01)
		assert_float(box.end.y).is_between(7.5, 10.0)
		assert_int(_triangles(mesh)).is_between(300, 800)
		var far := TreeModel.mesh(BIRCH, variant, TreeModel.DETAIL_FAR)
		assert_int(_triangles(far)).is_less(_triangles(mesh) / 3)
		assert_float(far.get_aabb().end.y).is_equal_approx(box.end.y, box.end.y * 0.1)
		# mais fina que o carvalho
		assert_float(maxf(box.size.x, box.size.z)).is_less(TreeModel.mesh(TreeModel.Species.OAK, 0).get_aabb().size.x)


func test_the_trunk_is_white_with_black_marks_near() -> void:
	var near := _colors(TreeModel.mesh(BIRCH, 0))
	var white := 0
	var marks := 0
	for color: Color in near:
		if color.r > 0.8 and color.g > 0.8 and color.b > 0.75:
			white += 1
		elif _is_mark(color):
			marks += 1
	assert_int(white).is_greater(20)
	# seis vértices por mancha
	assert_int(marks).is_equal(TreeModel.BIRCH_MARKS * 6)
	var far_marks := 0
	for color: Color in _colors(TreeModel.mesh(BIRCH, 0, TreeModel.DETAIL_FAR)):
		if _is_mark(color):
			far_marks += 1
	assert_int(far_marks).is_equal(0)


func test_the_forest_picks_birch_mostly_at_the_edge_and_low() -> void:
	assert_int(TreeView.BROADLEAF[4][0]).is_equal(BIRCH)
	var edge := 0
	var low := 0
	var inside := 0
	var kinds := {}
	for i: int in 2000:
		var seed_value := hash([0, i, 0])
		if TreeView.BROADLEAF[TreeView.broadleaf_pick(seed_value, 1, 8.0)][0] == BIRCH:
			edge += 1
		if TreeView.BROADLEAF[TreeView.broadleaf_pick(seed_value, 3, 2.0)][0] == BIRCH:
			low += 1
		var pick := TreeView.broadleaf_pick(seed_value, 3, 8.0)
		kinds[pick] = true
		if TreeView.BROADLEAF[pick][0] == BIRCH:
			inside += 1
	assert_int(edge).is_between(650, 950)
	assert_int(low).is_between(380, 620)
	assert_int(inside).is_between(100, 320)
	# as seis folhosas aparecem
	assert_int(kinds.size()).is_equal(6)


## A cor da malha volta em 8 bits por canal: compara com folga.
func _is_mark(color: Color) -> bool:
	var mark := TreeModel.BIRCH_MARK
	return absf(color.r - mark.r) < 0.01 and absf(color.g - mark.g) < 0.01 and absf(color.b - mark.b) < 0.01
