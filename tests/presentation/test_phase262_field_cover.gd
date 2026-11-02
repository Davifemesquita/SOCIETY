extends GdUnitTestSuite
## Campos coloridos (Fase 262): as leiras ganham a cor da plantação conforme ela cresce, até COVER_MAX no degrau cheio; o
## cereal vai do verde ao dourado e as outras plantas ficam no verde delas.


func test_the_furrows_take_the_crop_color_as_it_grows() -> void:
	# recém-lavrado: só a terra úmida
	assert_bool(CropView.furrow_color_at(BuildingDef.Crop.TUBER, 0).is_equal_approx(CropView.FRESH_SOIL)).is_true()
	# no degrau cheio, COVER_MAX da cobertura sobre a terra seca
	var full := CropView.furrow_color_at(BuildingDef.Crop.TUBER, CropView.GROWTH_STEPS)
	var expected := CropView.DRY_SOIL.lerp(CropView.CROP_COVER[BuildingDef.Crop.TUBER], CropView.COVER_MAX)
	assert_bool(full.is_equal_approx(expected)).is_true()
	assert_float(full.g).is_greater(full.r)
	assert_float(CropView.COVER_MAX).is_between(0.5, 0.9)


func test_the_cereal_turns_from_green_to_gold() -> void:
	var young := CropView.furrow_color_at(BuildingDef.Crop.GRAIN, CropView.GROWTH_STEPS / 3)
	var ripe := CropView.furrow_color_at(BuildingDef.Crop.GRAIN, CropView.GROWTH_STEPS)
	# verde no começo, dourado no fim (o vermelho passa do verde)
	assert_float(young.g).is_greater(young.r)
	assert_float(ripe.r).is_greater(ripe.g)
	assert_float(ripe.r).is_greater(ripe.b * 1.5)


func test_every_crop_has_a_green_cover() -> void:
	for crop: int in [BuildingDef.Crop.TUBER, BuildingDef.Crop.HOPS, BuildingDef.Crop.VINE, BuildingDef.Crop.CANE,
			BuildingDef.Crop.BUSH, BuildingDef.Crop.BROADLEAF]:
		var cover: Color = CropView.CROP_COVER[crop]
		assert_float(cover.g).override_failure_message(str(crop)).is_greater(cover.r)
		assert_float(cover.g).is_greater(cover.b * 2.0)
