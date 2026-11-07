extends GdUnitTestSuite
## Cabeceira de capim (Fase 341): a terra lavrada recua mais da divisa (a faixa de capim entre dois campos vizinhos fica de ~0,8 a
## ~1,5 m), e as plantas e as leiras seguem dentro da terra (a margem delas passa do recuo máximo do contorno).


func test_the_grass_band_between_fields_is_wider() -> void:
	assert_float(CropView.FIELD_INSET_M * 2.0).is_greater(0.7)
	assert_float((CropView.FIELD_INSET_M + CropView.FIELD_WIGGLE_M) * 2.0).is_less(1.6)


func test_the_plants_stay_on_the_tilled_soil() -> void:
	assert_float(CropView.MARGIN_M).is_greater(CropView.FIELD_INSET_M + CropView.FIELD_WIGGLE_M)
	assert_float(CropView.HEADLAND_M).is_greater(CropView.FIELD_INSET_M + CropView.FIELD_WIGGLE_M)
