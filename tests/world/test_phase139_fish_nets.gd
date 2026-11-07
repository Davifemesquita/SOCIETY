extends GdUnitTestSuite
## Redes de pesca (Fase 139): cada cabana de pesca ganha uma célula livre encostada nela, de um dos lados, mais para o
## mar; com a célula bloqueada, vai para outra; outros prédios não têm; a vista conta as cabanas.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_the_nets_go_beside_the_hut_toward_the_sea() -> void:
	# a ilha plana tem mar em volta: a cabana encostada na borda de cima (y = 0) olha o mar para −z
	var id := SimFixture.place(_sim, &"fishery", Vector2i(20, 0), 0)
	var record := _sim.world.building(id)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var found := FishNetView.sites(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(1)
	var cell: Vector2i = found.keys()[0]
	var site: Array = found[cell]
	var out: Vector3 = site[0]
	assert_vector(out).is_equal_approx(Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.001)
	assert_bool(area.has_point(cell)).is_false()
	assert_bool(area.grow(1).has_point(cell)).is_true()
	# de um lado da cabana, na fileira do mar
	assert_bool(cell.x < area.position.x or cell.x >= area.end.x).is_true()
	assert_int(cell.y).is_equal(area.position.y)
	# as caixas vão para o lado longe da cabana
	var away: float = site[1]
	var beside := 1.0 if cell.x >= area.end.x else -1.0
	assert_float(away).is_equal(beside)


func test_a_taken_cell_moves_the_nets() -> void:
	SimFixture.place(_sim, &"fishery", Vector2i(20, 0), 0)
	var first: Vector2i = FishNetView.sites(_sim.world, _sim.data, 0).keys()[0]
	SimFixture.road(_sim, first, first + Vector2i(0, 1))
	var second: Vector2i = FishNetView.sites(_sim.world, _sim.data, 0).keys()[0]
	assert_bool(second == first).is_false()


func test_other_buildings_have_no_nets() -> void:
	SimFixture.place(_sim, &"lumberjack", Vector2i(20, 10))
	SimFixture.place(_sim, &"pier", Vector2i(40, 0))
	assert_int(FishNetView.sites(_sim.world, _sim.data, 0).size()).is_equal(0)


func test_the_view_counts_the_huts() -> void:
	SimFixture.place(_sim, &"fishery", Vector2i(20, 0))
	SimFixture.place(_sim, &"fishery", Vector2i(40, 0))
	var view: FishNetView = auto_free(FishNetView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.site_count()).is_equal(2)
