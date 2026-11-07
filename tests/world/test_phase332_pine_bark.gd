extends GdUnitTestSuite
## Casca sem laranja (Fase 332): o alto do tronco do pinheiro-silvestre é castanho-avermelhado, não laranja (com a saturação da cor
## viva os troncos saíam como palitos laranja no meio da mata), e segue mais claro e mais quente que o pé do tronco.


func test_the_upper_pine_bark_is_subdued() -> void:
	var upper := TreeModel.PINE_UPPER_BARK
	assert_float(upper.s).is_less(0.55)
	assert_float(upper.r / upper.g).is_less(1.5)
	assert_float(upper.get_luminance()).is_greater(TreeModel.PINE_BARK.get_luminance())
	assert_float(upper.r - upper.b).is_greater(TreeModel.PINE_BARK.r - TreeModel.PINE_BARK.b)
