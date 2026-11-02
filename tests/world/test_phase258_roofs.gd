extends GdUnitTestSuite
## Telhado e parede com cor (Fase 258): todo telhado tira a cor da tabela do material e da paleta (não mais da parede
## escurecida, que dava rosa-acinzentado), a tinta pesa mais que a textura cinza e o reboco das classes de cima é quente.


func test_every_roof_takes_its_color_from_the_material_table() -> void:
	var gray := Color(0.5, 0.5, 0.5)
	for layer: int in [BuildingMaterials.Roof.TILES, BuildingMaterials.Roof.PLANKS]:
		var tints: Array = BuildingView.ROOF_TINTS[layer]
		assert_int(tints.size()).is_equal(BuildingView.PALETTES)
		for palette: int in BuildingView.PALETTES:
			var roof := BuildingView.palette_roof(gray, layer, palette)
			var expected: Color = tints[palette]
			assert_bool(roof.is_equal_approx(expected)).is_true()
			assert_float(roof.a).is_equal_approx(1.0, 0.0001)
	# as telhas: vermelhos, laranjas e marrons de terracota (um azul sobre a textura de telha saía lilás)
	for tile: Color in BuildingView.ROOF_TINTS[BuildingMaterials.Roof.TILES]:
		assert_float(tile.r).is_greater(tile.g * 1.6)
		assert_float(tile.g).is_greater_equal(tile.b)
		assert_float(tile.s).is_greater(0.5)
	# as tábuas: marrons quentes
	for plank: Color in BuildingView.ROOF_TINTS[BuildingMaterials.Roof.PLANKS]:
		assert_float(plank.r).is_greater(plank.b * 1.3)


func test_the_paint_outweighs_the_gray_texture() -> void:
	var code := (load("res://shaders/building_kit.gdshader") as Shader).code
	assert_str(code).contains("uniform float tint_strength = 0.68")
	assert_str(code).contains("uniform float roof_tint_strength = 0.85")
	assert_str(code).contains("wall ? tint_strength : roof_tint_strength")


func test_the_upper_classes_have_warm_plaster() -> void:
	var data := GameData.get_default()
	for tier_id: StringName in [&"artisans", &"engineers", &"investors"]:
		var color := data.tier(tier_id).house_color
		# quente: o vermelho bem acima do azul (o dos engenheiros era 0,58 contra 0,5, um cinza)
		assert_float(color.r - color.b).override_failure_message(String(tier_id)).is_greater(0.18)
