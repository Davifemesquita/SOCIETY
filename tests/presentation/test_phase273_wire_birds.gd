extends GdUnitTestSuite
## Andorinhas no fio (Fase 273): nos fios dos postes das usinas, um vão a cada SPAN_EVERY, uma fila de andorinhas no alto do fio,
## perto do meio, de lado para ele e virando para um lado ou o outro; refeitas quando a PowerLineView refaz os fios; a andorinha de
## pé com o bico para a frente.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_perches_sit_on_the_middle_of_the_wire() -> void:
	var curve := HarborView.rope_span(Vector3(0.0, 6.0, 0.0), Vector3(9.0, 6.0, 0.0), PowerLineView.WIRE_SAG)
	var perches := WireBirdView.perches(curve, 0)
	assert_int(perches.size()).is_equal(WireBirdView.BIRDS_PER_SPAN)
	for perch: Array in perches:
		var at: Vector3 = perch[0]
		# perto do meio do vão e abaixo das pontas (o fio cai em curva)
		assert_float(absf(at.x - 4.5)).is_less(WireBirdView.GAP_M * WireBirdView.BIRDS_PER_SPAN)
		assert_float(at.y).is_less(6.0)
		# de lado para o fio: a frente (−z girado) perpendicular a x
		var side: float = perch[1]
		var front := Basis(Vector3.UP, side) * Vector3.FORWARD
		assert_float(absf(front.dot(Vector3.RIGHT))).is_less(0.001)
	# o vão que não é da vez fica vazio
	assert_array(WireBirdView.perches(curve, 1)).is_empty()


func test_the_view_follows_the_wires() -> void:
	assert_bool(_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(10, 20), Vector2i(40, 20)), true)).ok()).is_true()
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"power_station", Vector2i(20, 14), 0)).ok()).is_true()
	var lines: PowerLineView = auto_free(PowerLineView.new())
	add_child(lines)
	lines.setup(_sim)
	var birds: WireBirdView = auto_free(WireBirdView.new())
	add_child(birds)
	birds.setup(lines, _sim.config)
	birds.rebuild()
	var expected := 0
	var spans := lines.spans()
	for s: int in spans.size():
		expected += WireBirdView.perches(spans[s], s).size()
	assert_int(spans.size()).is_greater(0)
	assert_int(birds.bird_count()).is_equal(expected)
	assert_int(expected).is_greater(0)


func test_the_swallow_stands_with_the_beak_ahead() -> void:
	var box := WireBirdView.swallow_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_less(0.12)
	assert_float(box.position.z).is_less(-0.06)
	assert_float(box.end.z).is_greater(0.1)
