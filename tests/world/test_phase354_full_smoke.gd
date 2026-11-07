extends GdUnitTestSuite
## Fumaça cheia (Fase 354): mais casas soltando fumaça ao meio-dia, a fumaça mais cheia, mais alta e maior, e vista de mais longe.


func test_the_smoke_is_fuller_and_seen_from_further() -> void:
	assert_float(ChimneySmokeView.BASE_AMOUNT).is_greater_equal(0.5)
	assert_float(ChimneySmokeView.FADE_BEGIN_M).is_greater_equal(220.0)
	assert_float(ChimneySmokeView.FADE_END_M).is_greater(ChimneySmokeView.FADE_BEGIN_M + 100.0)
	var code := FileAccess.get_file_as_string("res://shaders/chimney_smoke.gdshader")
	for line: String in ["uniform float alpha = 0.65;", "uniform float end_size_m = 3.2;", "uniform float rise_m = 5.0;"]:
		assert_str(code).contains(line)
