extends GdUnitTestSuite
## Raso verde (Fase 359): a plataforma rasa das temperadas verde sobre o fundo (o verde acima do azul), não turquesa; a das tropicais
## segue a da WaterView.


func test_the_temperate_shallows_are_green() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/water.gdshader")
	var prefix := "uniform vec4 cold_shelf : source_color = vec4("
	var at := code.find(prefix)
	assert_int(at).is_greater(0)
	var parts := code.substr(at + prefix.length(), 40).split(")")[0].split(",")
	var shelf := Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	assert_float(shelf.g).is_greater(shelf.b + 0.04)
	# mais escura que a turquesa de antes
	assert_float(shelf.get_luminance()).is_less(Color(0.19, 0.52, 0.53).get_luminance())
