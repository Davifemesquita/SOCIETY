extends GdUnitTestSuite
## Velocípede encostado (Fase 154): só nas casas dos artesãos, uma a cada BIKE_EVERY pelo id; ele fica diante da fachada da
## frente, fora da célula da porta, com as rodas no chão e deitado para a parede.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


## Casa do tier dado com id no resto certo (as outras ficam sem bicicleta).
func _house(tier: StringName, rotation: int = 2) -> BuildingRecord:
	for attempt: int in VelocipedeView.BIKE_EVERY:
		var id := SimFixture.place(_sim, &"house", Vector2i(10 + _sim.world.buildings.size() * 4, 20), rotation)
		var record := _sim.world.building(id)
		record.tier = tier
		if posmod(id, VelocipedeView.BIKE_EVERY) == VelocipedeView.BIKE_REST:
			return record
	return null


func test_only_some_artisan_houses_get_a_bike() -> void:
	var record := _house(&"artisans")
	assert_object(record).is_not_null()
	assert_bool(VelocipedeView.spot(_sim, record) is Transform3D).is_true()
	for tier: StringName in [&"peasants", &"workers", &"engineers", &"investors"]:
		var other := _house(tier)
		assert_bool(VelocipedeView.spot(_sim, other) == null).is_true()
	# o artesão de outro resto não tem
	var id := SimFixture.place(_sim, &"house", Vector2i(10 + _sim.world.buildings.size() * 4, 20), 2)
	var plain := _sim.world.building(id)
	plain.tier = &"artisans"
	if posmod(id, VelocipedeView.BIKE_EVERY) != VelocipedeView.BIKE_REST:
		assert_bool(VelocipedeView.spot(_sim, plain) == null).is_true()


func test_the_bike_leans_on_the_front_wall_beside_the_door() -> void:
	for rotation: int in 4:
		var record := _house(&"artisans", rotation)
		var place: Transform3D = VelocipedeView.spot(_sim, record)
		var grid := _sim.world.island(0)
		var front := Footprint.front_direction(rotation)
		var out := Vector3(front.x, 0.0, front.y)
		var center := grid.rect_world(Footprint.rect(record.origin, Vector2i(3, 3), rotation))
		# as rodas no chão, diante da fachada da frente
		assert_float(place.origin.y).is_equal_approx(BuildingKit.seat(grid, Footprint.rect(record.origin, Vector2i(3, 3),
				rotation)).y, 0.02)
		assert_float((place.origin - center).dot(out)).is_greater(0.0)
		# fora da célula da porta
		var entrance := grid.cell_world(Footprint.entrance_cell(record.origin, Vector2i(3, 3), rotation))
		var along := Vector3(-out.z, 0.0, out.x)
		assert_float(absf((place.origin - entrance).dot(along))).is_greater(grid.cell_size * 0.5)
		# deitada para a parede: o alto (+Y) pende para dentro (−out)
		assert_float(place.basis.y.normalized().dot(-out)).is_greater(0.1)
		# inteira na célula ao lado da porta (de ponta a ponta)
		var box := VelocipedeView.bike_mesh().get_aabb()
		assert_float(absf(box.position.x + box.end.x)).is_less(0.05)
		assert_float(box.size.x).is_less(grid.cell_size - 0.1)
