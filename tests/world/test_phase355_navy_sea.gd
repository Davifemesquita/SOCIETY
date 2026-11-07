extends GdUnitTestSuite
## Marinho (Fase 355): o fundo do mar das temperadas mais escuro e menos azul (de cima, azul-petróleo escuro, como no Anno), ainda com o
## azul acima do vermelho.


func test_the_temperate_deep_is_darker_petrol() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/water.gdshader")
	var prefix := "uniform vec4 cold_deep : source_color = vec4("
	var at := code.find(prefix)
	assert_int(at).is_greater(0)
	var parts := code.substr(at + prefix.length(), 40).split(")")[0].split(",")
	var deep := Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	assert_float(deep.get_luminance()).is_less(Color(0.04, 0.18, 0.29).get_luminance() * 0.8)
	assert_float(deep.b).is_greater(deep.g)
	assert_float(deep.g).is_greater(deep.r * 2.0)
