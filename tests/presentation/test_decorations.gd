extends GdUnitTestSuite
## Decoração na tela (Fase 16): cada peça no MultiMesh do tipo dela, as malhas com a base no chão e dentro da
## área do prédio, e o jato de cada praça com chafariz (some com a praça).

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 30))


func _view() -> DecorationView:
	var view: DecorationView = auto_free(DecorationView.new())
	add_child(view)
	view.setup(_sim)
	return view


func test_every_decoration_mesh_stands_on_the_ground_inside_its_area() -> void:
	for def: BuildingDef in _sim.data.buildings:
		if not def.is_decoration():
			continue
		var box := DecorationView.mesh_for(def, _sim.config.cell_size_m).get_aabb()
		assert_float(box.position.y).override_failure_message(String(def.id)).is_greater_equal(-0.01)
		var half := Vector2(def.size) * _sim.config.cell_size_m * 0.5
		assert_float(absf(box.position.x)).override_failure_message(String(def.id)).is_less_equal(half.x + 0.3)
		assert_float(absf(box.position.z)).override_failure_message(String(def.id)).is_less_equal(half.y + 0.3)


func test_pieces_and_fountain_jets_follow_the_buildings() -> void:
	var view := _view()
	SimFixture.place(_sim, &"planted_tree", Vector2i(5, 5), 0)
	SimFixture.place(_sim, &"park_bench", Vector2i(7, 5), 1)
	SimFixture.place(_sim, &"fountain_square", Vector2i(10, 10), 0)
	view.rebuild()
	assert_int(view.piece_count()).is_equal(3)
	assert_int(view.piece_count(&"fountain_square")).is_equal(1)
	assert_int(view.jet_count()).is_equal(1)
	_sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(10, 10), Vector2i(3, 3))))
	view.rebuild()
	assert_int(view.jet_count()).is_equal(0)
	assert_int(view.piece_count()).is_equal(2)


func test_the_fountain_square_comes_with_the_workers() -> void:
	var def := _sim.data.building(&"fountain_square")
	assert_str(String(def.unlock_tier)).is_equal("workers")
	assert_float(def.beauty).is_greater(_sim.data.building(&"planted_tree").beauty * 2.0)
