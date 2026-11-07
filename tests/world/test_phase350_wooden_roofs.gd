extends GdUnitTestSuite
## Telhado de madeira (Fase 350): mais casas do povo de telhado de tábuas (dois terços dos operários, um terço dos artesãos), metade
## no cinza e metade no marrom; o shader escolhe o tom pelo valor do parâmetro.


func test_the_shares_and_the_tones() -> void:
	assert_int(BuildingView.SHINGLE_SIXTHS[&"workers"]).is_equal(4)
	assert_int(BuildingView.SHINGLE_SIXTHS[&"artisans"]).is_equal(2)
	var code := FileAccess.get_file_as_string("res://shaders/building_kit.gdshader")
	assert_str(code).contains("shingle > 1.5 ? shingle_brown.rgb : shingle_color.rgb")
	var view := FileAccess.get_file_as_string("res://presentation/building_view.gd")
	assert_str(view).contains("static func shingle_tone(")
