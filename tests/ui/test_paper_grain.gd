extends GdUnitTestSuite
## Papel envelhecido (Fase 21): as linhas do vergê, as manchas de ferrugem e a borda gasta do `PaperGrain`,
## no papel da interface (com as cantoneiras gravadas) e por cima da carta do arquipélago.

const SIDE := 128


func test_laid_lines_darken_every_few_rows_and_chain_lines_every_few_columns() -> void:
	var paper := UiPalette.PAPER
	# um pixel fora das linhas e sem ferrugem fica como estava
	var plain := Vector2i(1, 1)
	while PaperGrain.foxing(plain.x, plain.y, 7) > 0.0:
		plain.x += PaperGrain.CHAIN_PX
	assert_bool(PaperGrain.age(paper, plain.x, plain.y, 7).is_equal_approx(paper)).is_true()
	var laid := PaperGrain.age(paper, plain.x, plain.y - 1, 7)
	assert_float(laid.get_luminance()).is_less(paper.get_luminance())
	var chain := PaperGrain.age(paper, 0, plain.y, 7)
	assert_float(chain.get_luminance()).is_less(paper.get_luminance())


func test_foxing_is_a_few_round_spots_darker_at_the_rim() -> void:
	var spotted := 0
	var strongest := 0.0
	for y: int in 256:
		for x: int in 256:
			var fox := PaperGrain.foxing(x, y, 1840)
			assert_float(fox).is_between(0.0, 1.0)
			if fox > 0.0:
				spotted += 1
				strongest = maxf(strongest, fox)
	# poucas manchas: algumas, mas bem menos de um vigésimo do papel
	assert_int(spotted).is_greater(10)
	assert_int(spotted).is_less(256 * 256 / 20)
	assert_float(strongest).is_greater(0.8)
	# a mesma semente dá as mesmas manchas, e outra semente, outras
	var same := 0
	var other := 0
	for y: int in 256:
		for x: int in 256:
			if PaperGrain.foxing(x, y, 1840) > 0.0:
				same += 1 if PaperGrain.foxing(x, y, 1840) > 0.0 else 0
				other += 1 if PaperGrain.foxing(x, y, 1841) > 0.0 else 0
	assert_int(same).is_equal(spotted)
	assert_int(other).is_less(spotted)


func test_the_overlay_wears_the_edges_and_leaves_the_middle_almost_clear() -> void:
	var image := PaperGrain.overlay(SIDE, 1840)
	assert_vector(Vector2(image.get_size())).is_equal(Vector2(SIDE, SIDE))
	var edge := 0.0
	var middle := 0.0
	for i: int in SIDE:
		edge += image.get_pixel(i, 0).a + image.get_pixel(0, i).a
		middle += image.get_pixel(i, SIDE / 2 + 1).a + image.get_pixel(SIDE / 2 + 1, i).a
	assert_float(edge / (SIDE * 2)).is_greater(PaperGrain.WORN_DARK * 0.5)
	assert_float(middle / (SIDE * 2)).is_less(0.12)
	# determinística
	assert_bool(image.get_data() == PaperGrain.overlay(SIDE, 1840).get_data()).is_true()


func test_the_interface_paper_has_the_grain_and_engraved_brass_corners() -> void:
	var frame := ThemeBuilder.PAPER_FRAME_PX
	var image := ThemeBuilder.paper_image(192, frame, 1840)
	# o grão: no miolo, alguma linha de vergê mais escura que a de baixo
	var darker := 0
	for x: int in range(frame * 2, 192 - frame * 2):
		if image.get_pixel(x, 96).get_luminance() < image.get_pixel(x, 97).get_luminance():
			darker += 1
	assert_int(darker).is_greater((192 - frame * 4) / 2)
	# a cantoneira de cima à esquerda: o prego escuro no meio e o filete do anel mais escuro que a chapa
	var plate := frame * 0.36
	var center := Vector2i(frame / 2, frame / 2)
	assert_float(image.get_pixelv(center).get_luminance()).is_less(UiPalette.GOLD.get_luminance())
	var ring := center + Vector2i(roundi(plate * ThemeBuilder.CORNER_RING), 0)
	var inside := center + Vector2i(roundi(plate * 0.45), 0)
	assert_float(image.get_pixelv(ring).get_luminance()).is_less(image.get_pixelv(inside).get_luminance())


func test_the_archipelago_map_draws_the_same_grain_once() -> void:
	var grain := ArchipelagoMap.grain()
	assert_object(grain).is_not_null()
	assert_vector(Vector2(grain.get_size())).is_equal(Vector2(ArchipelagoMap.GRAIN_PX, ArchipelagoMap.GRAIN_PX))
	assert_object(ArchipelagoMap.grain()).is_same(grain)
