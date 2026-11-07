extends GdUnitTestSuite
## Roupa sobre a rua (Fase 192): o varal atravessa a rua de uma célula entre duas casas de operários frente a frente, no alto,
## de uma fachada à outra; nada sem a casa do outro lado, com ela de costas ou de outra classe.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true
	SimFixture.road(_sim, Vector2i(2, 10), Vector2i(70, 10))


## Uma casa de cada lado da rua em y = 10, a de cima virada para baixo e a de baixo virada para cima; devolve [cima, baixo].
func _pair(x: int, tier: StringName = &"workers", below_rotation: int = 0) -> Array[int]:
	var above := SimFixture.place(_sim, &"house", Vector2i(x, 7), 2)
	var below := SimFixture.place(_sim, &"house", Vector2i(x, 11), below_rotation)
	for id: int in [above, below]:
		_sim.world.building(id).tier = tier
	return [above, below]


func test_a_line_crosses_the_street_between_facing_worker_houses() -> void:
	for x: int in [4, 8, 12, 16]:
		_pair(x)
	var found := StreetLaundryView.lines(_sim)
	assert_int(found.size()).is_greater(0)
	var grid := _sim.world.island(SimFixture.ISLAND)
	for line: Array in found:
		var a: Vector3 = line[0]
		var b: Vector3 = line[1]
		# atravessa a rua de lado a lado (a largura de uma célula), na mesma coluna, no alto
		assert_float(a.distance_to(b)).is_equal_approx(grid.cell_size, 0.05)
		assert_float(absf(a.x - b.x)).is_less(0.01)
		assert_float(a.y - grid.height_at(a.x, a.z)).is_equal_approx(StreetLaundryView.HEIGHT_M, 0.01)
		var road := grid.world_to_cell((a + b) * 0.5)
		assert_bool(grid.has_road(road)).is_true()


func test_no_line_without_a_facing_worker_house() -> void:
	_pair(4, &"artisans")
	_pair(12, &"workers", 2)
	assert_array(StreetLaundryView.lines(_sim)).is_empty()
	# uma casa sozinha também não
	SimFixture.place(_sim, &"house", Vector2i(20, 7), 2)
	assert_array(StreetLaundryView.lines(_sim)).is_empty()


func test_the_view_draws_rope_and_clothes() -> void:
	for x: int in [4, 8, 12, 16]:
		_pair(x)
	var view: StreetLaundryView = auto_free(StreetLaundryView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.line_count()).is_greater(0)
