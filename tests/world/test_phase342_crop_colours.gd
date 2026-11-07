extends GdUnitTestSuite
## Cor de cultura (Fase 342): a cobertura de cada cultura distinta das outras (de longe o campo se lê pela cor), e o trigo dourado
## distinto de todas.


func test_each_crop_cover_differs_from_the_others() -> void:
	var colours: Array[Color] = [CropView.CEREAL_GOLD]
	for crop: int in CropView.CROP_COVER:
		var cover: Color = CropView.CROP_COVER[crop]
		colours.append(cover)
	var closest := INF
	for i: int in colours.size():
		for j: int in range(i + 1, colours.size()):
			var a := colours[i]
			var b := colours[j]
			closest = minf(closest, Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length())
	# antes, o par mais perto ficava a 0,05
	assert_float(closest).is_greater(0.08)
	# e o brilho espalhado: do mais escuro ao mais claro, mais que o dobro
	var darkest := INF
	var lightest := 0.0
	for colour: Color in colours:
		darkest = minf(darkest, colour.get_luminance())
		lightest = maxf(lightest, colour.get_luminance())
	assert_float(lightest / darkest).is_greater(2.0)
