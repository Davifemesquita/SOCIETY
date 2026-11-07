extends GdUnitTestSuite
## Leiras marcadas (Fase 340): a terra dos sulcos entre as leiras mais escura e a leira mais estreita, para as fileiras se lerem de
## cima: a leira mais crescida fica bem mais clara que a terra do sulco.


func test_the_furrow_soil_is_dark_and_the_ridges_narrower() -> void:
	assert_float(CropView.FURROW_FILL).is_between(0.5, 0.66)
	for soil: Color in CropView.FIELD_SOILS:
		assert_float(soil.get_luminance()).is_less(0.3)
	# a cor da leira no degrau cheio contra a terra mais clara do sulco
	var lightest := 0.0
	for soil: Color in CropView.FIELD_SOILS:
		lightest = maxf(lightest, soil.get_luminance())
	for crop: int in [BuildingDef.Crop.GRAIN, BuildingDef.Crop.TUBER]:
		var ridge := CropView.furrow_color_at(crop, CropView.GROWTH_STEPS - 1)
		assert_float(ridge.get_luminance()).is_greater(lightest * 1.25)
