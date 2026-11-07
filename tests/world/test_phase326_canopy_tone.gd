extends GdUnitTestSuite
## Mata no tom (Fase 326): as folhosas mais fundas e menos saturadas que as da Fase 256 (a mata virava verde-limão, mais clara
## que o prado), o alto da copa menos amarelo e os tons sorteados por árvore (Fase 305) sem cortar o azul; as coníferas ficam.

const INCLUDE := "res://shaders/foliage.gdshaderinc"
## as cores de antes da fase
const OLD_LEAVES: Array[Color] = [Color(0.37, 0.57, 0.19), Color(0.48, 0.66, 0.22), Color(0.47, 0.65, 0.25),
		Color(0.24, 0.51, 0.15)]
const OLD_SUN := Color(1.06, 1.02, 0.82)


func _leaves() -> Array[Color]:
	return [TreeModel.OAK_LEAF, TreeModel.BEECH_LEAF, TreeModel.BIRCH_LEAF, TreeModel.TROPICAL_LEAF]


func test_broadleaves_are_deeper_and_less_saturated() -> void:
	var leaves := _leaves()
	for i: int in leaves.size():
		var leaf := leaves[i]
		var old := OLD_LEAVES[i]
		assert_float(leaf.v).override_failure_message("brilho %d" % i).is_less(old.v - 0.08)
		assert_float(leaf.s).override_failure_message("saturação %d" % i).is_less(old.s)
		# segue verde: o verde na frente do vermelho e do azul
		assert_float(leaf.g).is_greater(leaf.r * 1.3)
		assert_float(leaf.g).is_greater(leaf.b * 1.8)
	# a bétula segue a mais clara das folhosas
	for leaf: Color in [TreeModel.OAK_LEAF, TreeModel.BEECH_LEAF, TreeModel.TROPICAL_LEAF]:
		assert_float(TreeModel.BIRCH_LEAF.v).is_greater(leaf.v)


func test_the_lit_top_of_the_crown_is_no_longer_lime() -> void:
	# o alto da copa: a cor vezes a luz de cima e o amarelo do sol
	assert_float(TreeModel.CROWN_SUN.b / TreeModel.CROWN_SUN.r).is_greater(OLD_SUN.b / OLD_SUN.r + 0.05)
	var top := Color(TreeModel.OAK_LEAF.r * TreeModel.CROWN_LIGHT * TreeModel.CROWN_SUN.r,
			TreeModel.OAK_LEAF.g * TreeModel.CROWN_LIGHT * TreeModel.CROWN_SUN.g,
			TreeModel.OAK_LEAF.b * TreeModel.CROWN_LIGHT * TreeModel.CROWN_SUN.b)
	assert_float(top.g).is_less(0.55)
	assert_float(top.s).is_less(0.65)


func test_the_tree_tones_keep_the_blue() -> void:
	var code := FileAccess.get_file_as_string(INCLUDE)
	for uniform_name: String in ["tint_dark", "tint_olive", "tint_yellow"]:
		var prefix := "uniform vec3 %s = vec3(" % uniform_name
		var at := code.find(prefix)
		assert_int(at).override_failure_message(prefix).is_greater(0)
		var parts := code.substr(at + prefix.length(), 24).split(")")[0].split(",")
		var tone := Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
		# nenhum tom corta o azul abaixo de 78% do verde (o oliva de antes cortava a 66%, o amarelado a 67%)
		assert_float(tone.z / tone.y).override_failure_message(uniform_name).is_greater(0.78)
	# o amarelado só um pouco mais claro que a cor de sempre
	assert_str(code).contains("uniform vec3 tint_yellow = vec3(1.06, 1.04, 0.86);")


func test_the_conifers_keep_their_colour() -> void:
	# (Fase 331: as coníferas mudaram de propósito, puxadas do ciano para o oliva)
	assert_bool(TreeModel.PINE_NEEDLE.is_equal_approx(Color(0.26, 0.43, 0.17))).is_true()
	assert_bool(TreeModel.SPRUCE_NEEDLE.is_equal_approx(Color(0.17, 0.33, 0.14))).is_true()
