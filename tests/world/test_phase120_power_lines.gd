extends GdUnitTestSuite
## Postes e fios (Fase 120): só com usina; os postes ficam nas ruas até o raio dela, nunca na célula do poste de gás, na
## beira da rua; cada ligação tem dois fios que caem entre os isoladores; demolir a usina tira os postes.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _street(from: Vector2i, to: Vector2i, paved: bool = true) -> void:
	assert_bool(_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(from, to), paved)).ok()).is_true()


func _plant(origin: Vector2i) -> BuildingRecord:
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"power_station", origin, 0))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_no_poles_without_a_power_station() -> void:
	_street(Vector2i(10, 20), Vector2i(40, 20))
	assert_int(PowerLineView.poles(_sim.world, _sim.data).size()).is_equal(0)


func test_poles_line_the_streets_near_the_plant() -> void:
	_street(Vector2i(10, 20), Vector2i(40, 20))
	var plant := _plant(Vector2i(20, 14))
	var spots := PowerLineView.poles(_sim.world, _sim.data)
	assert_int(spots.size()).is_greater(3)
	var grid := _sim.world.island(0)
	var def := _sim.def_of(plant)
	var reach := Footprint.rect(plant.origin, def.size, plant.rotation).grow(def.power_radius_cells)
	for spot: Vector3 in spots:
		# na beira da rua: a célula do pé é a da rua ou a do lado dela, dentro do raio
		var cell := grid.world_to_cell(spot)
		assert_bool(reach.grow(1).has_point(cell)).is_true()
		# a célula de rua do poste (a dele ou a vizinha) é do resto do poste, nunca do poste de gás (resto 0 de x + 3y)
		var road := Vector2i(-1, -1)
		for step: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next := cell + step
			if grid.has_road(next) and posmod(next.x + 3 * next.y, PowerLineView.POLE_EVERY) == PowerLineView.POLE_REST:
				road = next
		assert_bool(road.x >= 0).is_true()
		assert_int(posmod(road.x + 3 * road.y, LampView.LAMP_EVERY)).is_not_equal(0)


func test_each_link_has_two_sagging_wires() -> void:
	_street(Vector2i(10, 20), Vector2i(40, 20))
	_plant(Vector2i(20, 14))
	var view: PowerLineView = auto_free(PowerLineView.new())
	add_child(view)
	view.setup(_sim)
	var spots := PowerLineView.poles(_sim.world, _sim.data)
	var pairs := PowerLineView.links(spots, _sim.world)
	assert_int(view.pole_count()).is_equal(spots.size())
	assert_int(view.wire_count()).is_equal(pairs.size() * 2)
	assert_int(pairs.size()).is_greater_equal(spots.size() - 1)
	for pair: Vector2i in pairs:
		var a := spots[pair.x]
		var b := spots[pair.y]
		assert_float(Vector2(a.x - b.x, a.z - b.z).length()).is_less_equal(PowerLineView.LINK_M)
		var span := HarborView.rope_span(a, b, PowerLineView.WIRE_SAG)
		assert_float(span[span.size() / 2].y).is_less((a.y + b.y) * 0.5)


func test_the_arm_crosses_the_line() -> void:
	var spots: Array[Vector3] = [Vector3(0.0, 0.0, 0.0), Vector3(8.0, 0.0, 0.0), Vector3(16.0, 0.0, 0.0)]
	var pairs := PowerLineView.links(spots)
	var arm := PowerLineView.arm_direction(spots, pairs, 1)
	assert_float(absf(arm.dot(Vector3.RIGHT))).is_less(0.01)


func test_demolishing_the_plant_takes_the_poles_away() -> void:
	_street(Vector2i(10, 20), Vector2i(40, 20))
	var plant := _plant(Vector2i(20, 14))
	var area := Footprint.rect(plant.origin, _sim.def_of(plant).size, plant.rotation)
	assert_bool(_sim.execute(DemolishCommand.new(0, area)).ok()).is_true()
	assert_int(PowerLineView.poles(_sim.world, _sim.data).size()).is_equal(0)


func test_no_wire_through_a_building() -> void:
	var grid := _sim.world.island(0)
	var house := SimFixture.place(_sim, &"house", Vector2i(30, 10))
	var record := _sim.world.building(house)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var west := grid.cell_world(Vector2i(area.position.x - 1, area.position.y + 1))
	var east := grid.cell_world(Vector2i(area.end.x, area.position.y + 1))
	var south := grid.cell_world(Vector2i(area.position.x - 1, area.end.y + 1))
	assert_bool(PowerLineView.clear_span(_sim.world, west, east)).is_false()
	assert_bool(PowerLineView.clear_span(_sim.world, west, south)).is_true()
