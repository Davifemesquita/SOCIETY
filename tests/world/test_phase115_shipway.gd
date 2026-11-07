extends GdUnitTestSuite
## Carreira do estaleiro (Fase 115): a rampa sai da beira do estaleiro do lado do mar, desce e acaba na água funda, sem
## prédio nem estrada no caminho; o casco em obra só aparece com encomenda, cresce com o progresso e some quando ela sai.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _shipyard() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"shipyard", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"shipyard", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func _order(record: BuildingRecord, progress: float) -> void:
	var order := ShipyardState.Order.new()
	order.def_id = &"merchant_ship"
	order.progress = progress
	_sim.world.shipyard_state.orders[record.id] = order


func test_the_ramp_runs_down_into_deep_water() -> void:
	var record := _shipyard()
	var plan := ShipwayView.site(_sim, record)
	assert_bool(plan.is_empty()).is_false()
	var length: float = plan["length"]
	var mouth := ShipwayView.ramp_point(plan, 0.0)
	var tip := ShipwayView.ramp_point(plan, length)
	# desce da boca à ponta, e a ponta está na água funda
	assert_float(tip.y).is_less(mouth.y)
	assert_float(tip.y).is_less(0.0)
	assert_bool(HarborView.afloat(_sim.world, tip)).is_true()
	# a boca fica na beira do estaleiro
	var def := _sim.def_of(record)
	var grid := _sim.world.island(0)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var half := maxf(area.size.x, area.size.y) * _config.cell_size_m * 0.5
	assert_float(Vector2(mouth.x - center.x, mouth.z - center.z).length()).is_less_equal(half + 0.01)


func test_the_hull_grows_with_the_order() -> void:
	var counts: Array[int] = []
	for progress: float in [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]:
		var mesh := ShipwayView.hull_mesh(12.8, progress)
		counts.append(mesh.surface_get_array_len(0))
	for i: int in range(1, counts.size()):
		var before: int = counts[i - 1]
		assert_int(counts[i]).is_greater_equal(before)
	# de pouco (só a quilha) a muito (cavername, costado e borda)
	var first: int = counts[0]
	assert_int(counts[-1]).is_greater(first * 10)


func test_the_hull_points_close_at_the_bow_and_stay_open_at_the_stern() -> void:
	var length := 16.0
	assert_float(ShipwayView.hull_point(1.0, PI * 0.5, length).x).is_less(0.01)
	assert_float(ShipwayView.hull_point(0.0, PI * 0.5, length).x).is_greater(1.0)
	# a borda sobe nas pontas
	var depth := length * ShipwayView.BEAM_RATIO * ShipwayView.DEPTH_RATIO
	assert_float(ShipwayView.sheer(0.0, depth)).is_greater(ShipwayView.sheer(0.5, depth))


func test_the_view_shows_the_hull_only_while_the_order_runs() -> void:
	var record := _shipyard()
	var view: ShipwayView = auto_free(ShipwayView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.ramp_count()).is_equal(1)
	assert_object(view.hull_of(record.id)).is_null()
	_order(record, 0.2)
	view.refresh_hulls()
	var hull := view.hull_of(record.id)
	assert_object(hull).is_not_null()
	var small := (hull.mesh as ArrayMesh).surface_get_array_len(0)
	_order(record, 0.8)
	view.refresh_hulls()
	assert_int((view.hull_of(record.id).mesh as ArrayMesh).surface_get_array_len(0)).is_greater(small)
	# a popa fica para o lado do mar: mais baixa que a proa
	var placed := view.hull_of(record.id).transform
	assert_float(placed.origin.y).is_less((placed * Vector3(0.0, 0.0, 12.8)).y)
	_sim.world.shipyard_state.forget(record.id)
	view.refresh_hulls()
	assert_object(view.hull_of(record.id)).is_null()


func test_no_ramp_when_something_is_in_the_way() -> void:
	var record := _shipyard()
	var plan := ShipwayView.site(_sim, record)
	var grid := _sim.world.island(0)
	# uma estrada na linha da rampa, ainda em terra, tira a carreira
	var direction: Vector3 = plan["direction"]
	var cell := grid.world_to_cell(ShipwayView.ramp_point(plan, 0.6))
	var blocked := false
	for meters: float in [0.6, 1.5, 2.5, 3.5]:
		cell = grid.world_to_cell(ShipwayView.ramp_point(plan, meters) + direction * 0.0)
		if grid.in_bounds(cell) and grid.is_land(cell) and grid.building_at(cell) == 0:
			grid.set_road(cell, IslandGrid.Road.DIRT)
			blocked = true
			break
	if not blocked:
		return
	assert_bool(ShipwayView.site(_sim, record).is_empty()).is_true()
