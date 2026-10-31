extends GdUnitTestSuite
## Chão gasto no pasto (Fase 118): cada pasto tem manchas de terra batida na porteira, no cocho e soltas dentro da cerca,
## pintadas no canal b da máscara das estradas; o cocho fica dentro do pasto, junto da cerca de trás; tirar o pasto apaga as
## manchas.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _pasture() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"pasture", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"pasture", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_trough_sits_inside_by_the_back_fence() -> void:
	var record := _pasture()
	var def := _sim.def_of(record)
	var cell_size := _config.cell_size_m
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var lot := Rect2(Vector2(area.position) * cell_size, Vector2(area.size) * cell_size)
	var trough := RoadMask.trough_of(record, def, cell_size)
	var front := Vector2(Footprint.front_direction(record.rotation))
	# as duas pontas do cocho dentro do pasto
	for end: float in [-1.0, 1.0]:
		assert_bool(lot.grow(-0.2).has_point(trough[0] + trough[1] * end * PastureTroughView.LENGTH_M * 0.5)).is_true()
	# do lado de trás: oposto à porteira
	assert_float((trough[0] - lot.get_center()).dot(front)).is_less(0.0)
	# ao longo da cerca
	assert_float(absf(trough[1].dot(front))).is_less(0.01)


func test_the_patches_are_painted_inside_the_pasture() -> void:
	var record := _pasture()
	var mask := RoadMask.new(_sim.world, _sim.data, 0, 4, 6.0)
	var spots: PackedVector3Array = RoadMask.patches(_sim.world, _sim.data, 0)[record.id]
	assert_int(spots.size()).is_equal(2 + RoadMask.PATCHES_PER_PASTURE)
	for spot: Vector3 in spots:
		assert_float(mask.channel_at(Vector2(spot.x, spot.y), 2)).is_greater(0.5)


func test_removing_the_pasture_clears_the_patches() -> void:
	var record := _pasture()
	var mask := RoadMask.new(_sim.world, _sim.data, 0, 4, 6.0)
	var spots: PackedVector3Array = RoadMask.patches(_sim.world, _sim.data, 0)[record.id]
	var loose := spots[2]
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	assert_bool(_sim.execute(DemolishCommand.new(0, area)).ok()).is_true()
	assert_bool(mask.refresh().size != Vector2i.ZERO).is_true()
	assert_float(mask.channel_at(Vector2(loose.x, loose.y), 2)).is_less(0.1)


func test_the_view_puts_one_trough_per_pasture() -> void:
	_pasture()
	var view: PastureTroughView = auto_free(PastureTroughView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.trough_count()).is_equal(1)
