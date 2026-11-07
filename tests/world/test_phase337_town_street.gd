extends GdUnitTestSuite
## Rua larga na vila (Fase 337): a estrada de terra fica mais estreita no campo e alarga onde passa pelo chão de vila (o canal b da
## máscara das estradas: as portas, os quintais, o pátio das fábricas), até perto de encher a célula entre as casas.

const TERRAIN := "res://shaders/terrain.gdshader"


func test_the_street_widens_in_town() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var half := _float_after(code, "uniform float road_half_width_m = ")
	var widen := _float_after(code, "uniform float road_town_widen_m = ")
	# no campo mais estreita que antes (0,8), na vila perto de encher a célula de 2 m sem passar dela
	assert_float(half).is_less(0.8)
	assert_float(half + widen).is_between(0.95, 1.1)
	var width := code.find("float width = road_half_width_m + road_town_widen_m * smoothstep(0.25, 0.7, roads.b)")
	assert_int(width).is_greater(code.find("vec4 roads = texture(road_mask, road_uv);"))


func test_the_town_yards_reach_the_street() -> void:
	# o quintal das casas cresce mais que a meia célula entre a parede e o meio da estrada encostada nela
	var config := GameConfig.get_default()
	assert_float(RoadMask.TOWN_YARD_REACH_M).is_greater(config.cell_size_m * 0.5)
	assert_float(RoadMask.YARD_REACH_M).is_greater(config.cell_size_m * 0.5)


func _float_after(code: String, prefix: String) -> float:
	var at := code.find(prefix)
	return code.substr(at + prefix.length(), 10).split(";")[0].to_float()
