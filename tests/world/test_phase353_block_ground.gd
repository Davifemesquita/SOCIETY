extends GdUnitTestSuite
## Miolo da quadra (Fase 353): o chão de vila das temperadas cresce mais em volta das casas, o bastante para cobrir o miolo entre duas
## casas com um lote livre entre elas (3 células), e a máscara se refaz com folga para ele.


func test_the_town_ground_covers_the_gap_between_houses() -> void:
	var config := GameConfig.get_default()
	# duas casas com um vão de 3 células: os dois chãos se encontram no meio
	assert_float(RoadMask.TOWN_YARD_REACH_M * 2.0).is_greater_equal(config.cell_size_m * 3.0)
	assert_float(RoadMask.TOWN_YARD_STRENGTH).is_greater(0.8)
	# a máscara refeita em volta da obra alcança o chão crescido
	assert_float(RoadMask.MARGIN_CELLS * config.cell_size_m).is_greater(RoadMask.TOWN_YARD_REACH_M + RoadMask.TOWN_YARD_RAGGED_M)
