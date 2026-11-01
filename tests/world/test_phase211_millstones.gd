extends GdUnitTestSuite
## Mós no moinho (Fase 211): cada moinho ganha a célula do meio de um lado (o de −X da frente primeiro), encostada nele; com ela
## bloqueada, vai para o outro lado; outros prédios não têm; o recheio deixa a célula; as mós ficam de pé e cabem na célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_millstones_lean_on_the_side_of_the_mill() -> void:
	var id := SimFixture.place(_sim, &"mill", Vector2i(20, 15), 0)
	var record := _sim.world.building(id)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var found := MillstoneView.sites(_sim.world, _sim.data, 0)
	assert_bool(found.has(id)).is_true()
	var site: Array = found[id]
	var cell: Vector2i = site[0]
	var side: Vector2i = site[1]
	var front := Footprint.front_direction(record.rotation)
	# de lado, não na frente (as pás) nem atrás
	assert_int(side.x * front.x + side.y * front.y).is_equal(0)
	assert_bool(area.has_point(cell)).is_false()
	assert_bool(area.has_point(cell - side)).is_true()


func test_a_blocked_cell_moves_the_millstones() -> void:
	var id := SimFixture.place(_sim, &"mill", Vector2i(20, 15), 0)
	var first: Array = MillstoneView.sites(_sim.world, _sim.data, 0)[id]
	var cell: Vector2i = first[0]
	SimFixture.road(_sim, cell, cell + Vector2i(0, 1))
	var found := MillstoneView.sites(_sim.world, _sim.data, 0)
	assert_bool(found.has(id)).is_true()
	var second: Array = found[id]
	var side_before: Vector2i = first[1]
	var side_after: Vector2i = second[1]
	assert_bool(side_after == -side_before).is_true()


func test_other_buildings_have_none_and_the_scatter_keeps_off() -> void:
	SimFixture.place(_sim, &"bakery", Vector2i(20, 15), 0)
	assert_int(MillstoneView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	SimFixture.place(_sim, &"mill", Vector2i(35, 15), 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var found := MillstoneView.cells(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_equal(1)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()


func test_the_millstones_stand_in_their_cell() -> void:
	var box := MillstoneView.millstone_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.05)
	assert_float(box.end.y).is_between(MillstoneView.STONE_R_M * 1.8, MillstoneView.STONE_R_M * 2.2)
	assert_float(box.size.x).is_less(2.0)
	# encostadas na parede: de −1 m (a parede) até menos de 1 m para fora
	assert_float(box.position.z).is_greater_equal(-1.05)
	assert_float(box.end.z).is_less(1.0)
