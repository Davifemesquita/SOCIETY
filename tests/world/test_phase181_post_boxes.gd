extends GdUnitTestSuite
## Caixa de correio (Fase 181): só nas células de paralelepípedo do desenho certo, fora das dos postes de gás; encostada no lado
## da calçada, virada para a rua; nenhuma na rua de terra; a caixa tem a altura de uma caixa de correio.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _paved_street(y: int) -> void:
	_sim.execute(BuildRoadCommand.new(SimFixture.ISLAND, RoadPath.l_path(Vector2i(2, y), Vector2i(77, y)), true))


func test_boxes_stand_on_the_right_paved_cells_by_the_sidewalk() -> void:
	_paved_street(10)
	_paved_street(25)
	var grid := _sim.world.island(SimFixture.ISLAND)
	var boxes := PostBoxView.spots(grid)
	assert_int(boxes.size()).is_greater(0)
	for place: Transform3D in boxes:
		# o pé fica no lado da calçada, a LAMP_OFFSET_M do meio da célula
		var cell := grid.world_to_cell(place.origin - place.basis.z * 0.01)
		var middle := grid.surface_world(cell)
		var outward := (place.origin - middle)
		outward.y = 0.0
		assert_float(outward.length()).is_equal_approx(LampView.LAMP_OFFSET_M, 0.01)
		assert_bool(grid.is_paved(cell)).is_true()
		assert_int(posmod(cell.x * 7 + cell.y * 13, PostBoxView.POST_EVERY)).is_equal(PostBoxView.POST_REST)
		assert_int(posmod(cell.x + cell.y * 3, LampView.LAMP_EVERY)).is_not_equal(0)
		# a calçada (fora da rua) para o lado do pé, a boca (+Z) para o meio da rua
		var side := Vector2i(roundi(outward.normalized().x), roundi(outward.normalized().z))
		assert_bool(grid.has_road(cell + side)).is_false()
		assert_float(place.basis.z.normalized().dot(-outward.normalized())).is_greater(0.99)


func test_no_box_on_dirt_roads() -> void:
	SimFixture.road(_sim, Vector2i(2, 10), Vector2i(77, 10))
	assert_array(PostBoxView.spots(_sim.world.island(SimFixture.ISLAND))).is_empty()


func test_the_box_is_waist_to_chest_high_and_round() -> void:
	var box := PostBoxView.box_mesh().get_aabb()
	assert_float(box.end.y).is_between(1.1, 1.4)
	assert_float(box.size.x).is_between(PostBoxView.BODY_RADIUS_M * 2.0, PostBoxView.BODY_RADIUS_M * 2.0 + 0.15)
