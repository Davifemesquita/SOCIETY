extends GdUnitTestSuite
## Reboco sujo (Fase 351): as casas de reboco claro (engenheiros e investidores) num tom sorteado por casa entre quatro, todos menos
## brancos que a cor de antes dos investidores, e distintos entre si.


func test_the_plaster_tones_are_varied_and_not_white() -> void:
	var investors := Color(0.93, 0.87, 0.73)
	for tone: Color in BuildingView.PLASTER_TONES:
		assert_float(tone.get_luminance()).is_less(investors.get_luminance() * 0.9)
	var tones := BuildingView.PLASTER_TONES
	for i: int in tones.size():
		for j: int in range(i + 1, tones.size()):
			var a := tones[i]
			var b := tones[j]
			assert_float(Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()).is_greater(0.07)
	assert_bool(BuildingView.PLASTER_TIERS.has(&"engineers")).is_true()
	assert_bool(BuildingView.PLASTER_TIERS.has(&"investors")).is_true()
	assert_float(BuildingView.PLASTER_MIX).is_between(0.5, 0.9)
