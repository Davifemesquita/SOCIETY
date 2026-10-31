extends GdUnitTestSuite
## Galinhas no quintal (Fase 135): o quintal é a fileira da frente do lote nas quatro rotações; as galinhas ficam dentro
## dele, andam e bicam o chão; só as casas de classe com quintal cercado, uma a cada CHICKEN_EVERY, têm galinhas.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


## Casa de camponeses com id múltiplo de CHICKEN_EVERY (a de id ímpar fica sem galinhas).
func _house_with_chickens(origin: Vector2i, rotation: int, tier: StringName = &"peasants") -> int:
	var id := SimFixture.place(_sim, &"house", origin, rotation)
	if posmod(id, ChickenView.CHICKEN_EVERY) != 0:
		# a de id ímpar fica (sem galinhas) e a seguinte vai logo abaixo
		id = SimFixture.place(_sim, &"house", origin + Vector2i(0, 4), rotation)
	_sim.world.building(id).tier = tier
	return id


func test_the_yard_is_the_front_row_of_the_lot() -> void:
	for rotation: int in 4:
		var size := Vector2i(3, 3)
		var origin := Vector2i(10, 10)
		var area := Footprint.rect(origin, size, rotation)
		var row := ChickenView.yard_row(origin, size, rotation)
		assert_int(row.get_area()).is_equal(3)
		assert_bool(area.encloses(row)).is_true()
		# encosta na frente: a célula da entrada fica logo fora dele
		var entrance := Footprint.entrance_cell(origin, size, rotation)
		assert_bool(row.has_point(entrance - Footprint.front_direction(rotation))).is_true()


func test_the_hens_stay_in_the_yard_walk_and_peck() -> void:
	var id := _house_with_chickens(Vector2i(20, 10), 2)
	var yards := ChickenView.yards(_sim)
	assert_int(yards.size()).is_equal(1)
	var yard: Array = yards[0]
	var low: Vector2 = yard[1]
	var high: Vector2 = yard[2]
	var grid := _sim.world.island(0)
	var record := _sim.world.building(id)
	var row := ChickenView.yard_row(record.origin, Vector2i(3, 3), record.rotation)
	var lot := Rect2(grid.origin_m + Vector2(row.position) * grid.cell_size, Vector2(row.size) * grid.cell_size)
	for i: int in ChickenView.HENS:
		var moved := false
		var pecked := false
		var first := ChickenView.pose(grid, yard, i, 0.0).origin
		for step: int in 400:
			var place := ChickenView.pose(grid, yard, i, step * 0.25)
			var point := Vector2(place.origin.x, place.origin.z)
			assert_bool(point.x >= low.x - 0.001 and point.x <= high.x + 0.001).is_true()
			assert_bool(point.y >= low.y - 0.001 and point.y <= high.y + 0.001).is_true()
			assert_bool(lot.has_point(point)).is_true()
			# cada uma no trecho dela: juntas, uma atravessava a outra
			assert_bool(ChickenView.patch(yard, i).grow(0.001).has_point(point)).is_true()
			if place.origin.distance_to(first) > 0.3:
				moved = true
			# bicando, a frente (−Z) aponta para baixo
			if (-place.basis.z).normalized().y < -0.3:
				pecked = true
		assert_bool(moved).is_true()
		assert_bool(pecked).is_true()


func test_only_yard_houses_have_chickens() -> void:
	_house_with_chickens(Vector2i(20, 10), 2, &"workers")
	assert_int(ChickenView.yards(_sim).size()).is_equal(0)
	SimFixture.place(_sim, &"bakery", Vector2i(40, 10))
	assert_int(ChickenView.yards(_sim).size()).is_equal(0)
	_house_with_chickens(Vector2i(60, 10), 0)
	assert_int(ChickenView.yards(_sim).size()).is_equal(1)


func test_the_rooster_is_bigger_and_rust_coloured() -> void:
	var yard := [0, Vector2(0.0, 0.0), Vector2(4.0, 1.0), 1234, true]
	assert_that(ChickenView.plumage(yard, 0)).is_equal(ChickenView.ROOSTER)
	assert_bool(ChickenView.PLUMAGES.has(ChickenView.plumage(yard, 1))).is_true()
	var grid := _sim.world.island(0)
	var rooster := ChickenView.pose(grid, yard, 0, 0.0).basis.get_scale().x
	var hen := ChickenView.pose(grid, yard, 1, 0.0).basis.get_scale().x
	assert_float(rooster).is_greater(hen)


func test_the_view_draws_three_hens_per_yard() -> void:
	_house_with_chickens(Vector2i(20, 10), 2)
	_house_with_chickens(Vector2i(40, 10), 2)
	var view: ChickenView = auto_free(ChickenView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.chicken_count()).is_equal(2 * ChickenView.HENS)
