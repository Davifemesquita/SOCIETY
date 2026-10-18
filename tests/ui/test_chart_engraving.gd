extends GdUnitTestSuite
## Carta gravada (Fase 20): litoral a tinta, linhas d'água em volta da costa e hachura na terra junto do mar,
## pela distância com sinal até o litoral.


func _chart() -> SeaChart:
	var sim := SimFixture.simulation(Vector2i(40, 30))
	return sim.harbors().chart


func test_the_coast_distance_is_positive_at_sea_negative_on_land_and_grows_away_from_the_coast() -> void:
	var chart := _chart()
	var field := ArchipelagoMap.coast_distance(chart)
	var land := 0
	for i: int in field.size():
		if chart.navigable[i] == 1:
			assert_float(field[i]).is_greater(0.0)
		else:
			assert_float(field[i]).is_less(0.0)
			land += 1
	assert_int(land).is_greater(0)
	# o canto da carta é mar aberto, longe da ilha
	assert_float(field[0]).is_greater(ArchipelagoMap.WATERLINES[ArchipelagoMap.WATERLINES.size() - 1])


func test_the_engraving_draws_ink_on_the_coast_waterlines_at_sea_and_hatching_on_land() -> void:
	var chart := _chart()
	var image := ArchipelagoMap.engrave(chart)
	assert_vector(Vector2(image.get_size())).is_equal(Vector2(chart.size * ArchipelagoMap.ENGRAVE_SCALE))
	var counts: Dictionary[String, int] = {"coast": 0, "sea_ink": 0, "land_ink": 0, "land": 0, "sea": 0}
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color := image.get_pixel(x, y)
			if color.is_equal_approx(ArchipelagoMap.COAST):
				counts["coast"] += 1
			elif color.is_equal_approx(ArchipelagoMap.LAND):
				counts["land"] += 1
			elif color.is_equal_approx(ArchipelagoMap.SEA) or color.is_equal_approx(ArchipelagoMap.SEA_SHALLOW):
				counts["sea"] += 1
			else:
				var cell := Vector2i(x, y) / ArchipelagoMap.ENGRAVE_SCALE
				var at_sea := chart.navigable[cell.y * chart.size.x + cell.x] == 1
				counts["sea_ink" if at_sea else "land_ink"] += 1
	for key: String in counts:
		assert_int(counts[key]).override_failure_message("sem pixel de %s: %s" % [key, counts]).is_greater(0)
