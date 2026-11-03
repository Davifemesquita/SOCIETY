extends GdUnitTestSuite
## Blocos caídos (Fase 311): no pé de cada rocha de falésia, de 2 a 4 blocos meio dentro da água (o topo pouco acima dela, o pé
## abaixo), perto do primeiro canto de mar abaixo da rocha; as rochas de falésia de antes não mudam.

const SIDE := 40
const SPACING := 2.0
const SEA := -8.0
const PLATEAU := 4.0


func _region() -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			heights[y * SIDE + x] = PLATEAU if x >= 5 and x <= 34 and y >= 5 and y <= 20 else SEA
	return heights


func _of_kind(entries: Array, kind: int) -> Array:
	return entries.filter(func(entry: Array) -> bool: return entry[2] == kind)


func test_fallen_blocks_lie_half_in_the_water_at_the_foot() -> void:
	var entries := RockView.places(_region(), SIDE, Vector2.ZERO, SPACING, null, 2.0, 7)
	var cliffs := _of_kind(entries, RockView.Kind.CLIFF)
	var talus := _of_kind(entries, RockView.Kind.TALUS)
	assert_int(talus.size()).is_between(cliffs.size() * RockView.TALUS_BLOCKS.x, cliffs.size() * RockView.TALUS_BLOCKS.y)
	for entry: Array in talus:
		var place: Transform3D = entry[1]
		var top := place.origin.y + place.basis.y.length()
		assert_float(place.origin.y).is_less(0.0)
		assert_float(top).is_between(0.0, RockView.TALUS_TOP_M.y + 0.5)
		# fora do planalto, junto da borda dele
		var cell := Vector2(place.origin.x, place.origin.z) / SPACING
		var on_plateau := cell.x > 5.5 and cell.x < 33.5 and cell.y > 5.5 and cell.y < 19.5
		assert_bool(on_plateau).is_false()
		var near_edge := cell.x > 1.0 and cell.x < 38.0 and cell.y > 1.0 and cell.y < 24.0
		assert_bool(near_edge).is_true()


func test_the_cliff_rocks_stay_where_they_were() -> void:
	# os blocos vêm depois da rocha de cima no mesmo sorteio: a lista das rochas de falésia é a mesma, na mesma ordem e lugar
	var entries := RockView.places(_region(), SIDE, Vector2.ZERO, SPACING, null, 2.0, 7)
	var cliffs := _of_kind(entries, RockView.Kind.CLIFF)
	assert_int(cliffs.size()).is_greater(8)
	for entry: Array in cliffs:
		var place: Transform3D = entry[1]
		assert_float(place.origin.y + place.basis.y.length()).is_less_equal(PLATEAU - RockView.CLIFF_BELOW_TOP_M + 0.001)
	assert_int(RockView.Kind.TALUS).is_greater(RockView.Kind.CLIFF)
