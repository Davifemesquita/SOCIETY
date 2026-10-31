extends GdUnitTestSuite
## Cerca de estacas (Fase 143): as casas dos operários ganham a cerca na frente (a forma muda e tem mais triângulos), as
## das outras classes não; a cerca fica na faixa da frente, com o vão da porta.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _spec(tier: StringName) -> BuildingKit.Spec:
	var id := SimFixture.house(_sim, 20 + _sim.world.buildings.size() * 4, 12, tier, 5.0)
	return BuildingKit.spec_for(_sim, _sim.world.building(id), _sim.world.island(0).cell_size)


func test_only_the_workers_get_the_picket_fence() -> void:
	assert_bool(_spec(&"workers").picket).is_true()
	for tier: StringName in [&"peasants", &"artisans", &"engineers", &"investors"]:
		assert_bool(_spec(tier).picket).is_false()


func test_the_fence_changes_the_shape_and_adds_triangles() -> void:
	var with_fence := _spec(&"workers")
	var without := _spec(&"workers")
	without.picket = false
	assert_str(with_fence.key()).is_not_equal(without.key())
	assert_int(BuildingKit.triangles(with_fence)).is_greater(BuildingKit.triangles(without))


func test_the_fence_leaves_the_door_open() -> void:
	var spec := _spec(&"workers")
	var spans := BuildingKit.front_railing_spans(spec)
	var size := spec.size_m()
	var step := size.x / spec.cells.x
	var door_x := -size.x * 0.5 + step * (spec.door_index + 0.5)
	for span: Vector2 in spans:
		assert_bool(door_x > span.x and door_x < span.y).is_false()
	# na faixa entre a parede e a divisa da frente
	assert_float(BuildingKit.front_railing_z(spec)).is_less(-size.y * 0.5)
