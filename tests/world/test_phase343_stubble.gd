extends GdUnitTestSuite
## Restolho e fardos (Fase 343): depois da colheita do cereal as leiras são de restolho claro, que some na terra em STUBBLE_STEPS
## degraus, e os sacos da colheita ficam no campo e vão sendo levados; as outras culturas seguem como antes.


func test_the_grain_field_is_stubble_right_after_the_harvest() -> void:
	var stubble := CropView.furrow_color_at(BuildingDef.Crop.GRAIN, 0)
	assert_bool(stubble.is_equal_approx(CropView.STUBBLE)).is_true()
	assert_float(stubble.get_luminance()).is_greater(CropView.FRESH_SOIL.get_luminance() * 2.0)
	# sumindo, sem degrau, até a cor de sempre
	var last := stubble.get_luminance()
	for step: int in range(1, CropView.STUBBLE_STEPS + 1):
		var now := CropView.furrow_color_at(BuildingDef.Crop.GRAIN, step).get_luminance()
		assert_float(now).is_less(last)
		last = now
	# as outras culturas sem restolho
	assert_bool(CropView.furrow_color_at(BuildingDef.Crop.TUBER, 0).is_equal_approx(CropView.FRESH_SOIL)).is_true()


func test_the_sacks_are_carried_away_after_the_harvest() -> void:
	assert_int(CropView.left_after_harvest(0)).is_equal(CropView.HARVEST_SPOTS)
	assert_int(CropView.left_after_harvest(CropView.STUBBLE_STEPS)).is_equal(0)
	var last := CropView.HARVEST_SPOTS
	for step: int in CropView.STUBBLE_STEPS + 1:
		var left := CropView.left_after_harvest(step)
		assert_int(left).is_less_equal(last)
		last = left
	# o restolho acaba antes de a colheita seguinte começar a aparecer
	assert_int(CropView.STUBBLE_STEPS).is_less(CropView.HARVEST_FROM)
