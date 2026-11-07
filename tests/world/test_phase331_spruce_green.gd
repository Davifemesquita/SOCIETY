extends GdUnitTestSuite
## Abeto sem ciano (Fase 331): as agulhas do pinheiro e do abeto não têm mais azul que vermelho (com a saturação da cor viva, o azul
## a mais saía ciano), o abeto segue mais escuro que o pinheiro, e o tom de longe das coníferas (Fase 308) escurece sem azular muito.


func test_the_needles_lean_to_olive_not_cyan() -> void:
	for needle: Color in [TreeModel.PINE_NEEDLE, TreeModel.SPRUCE_NEEDLE]:
		assert_float(needle.b).is_less_equal(needle.r)
		assert_float(needle.g).is_greater(needle.r * 1.6)
		# o matiz no verde amarelado (o ciano fica acima de 0,4)
		assert_float(needle.h).is_between(0.25, 0.33)
	assert_float(TreeModel.SPRUCE_NEEDLE.get_luminance()).is_less(TreeModel.PINE_NEEDLE.get_luminance())


func test_the_far_conifers_darken_without_turning_blue() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/foliage.gdshaderinc")
	var start := code.find("uniform vec3 far_cool_tint = vec3(")
	assert_int(start).is_greater(0)
	var inside := code.substr(start + "uniform vec3 far_cool_tint = vec3(".length())
	var parts := inside.substr(0, inside.find(")")).split(",")
	var tint := Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	# mais escuro
	assert_float(tint.y).is_less(0.8)
	# o azul quase no verde (era 0,88 contra 0,72)
	assert_float(tint.z / tint.y).is_less(1.1)
