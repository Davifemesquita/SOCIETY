extends GdUnitTestSuite
## Construir, estrada e demolir: regras, motivos de recusa e mundo intacto na recusa.

const HOUSE := &"house"
const FACTORY := &"furnace"
const ISLAND := Simulation.MAIN_ISLAND

var _sim: Simulation


func before_test() -> void:
	var config := GameConfig.new()
	config.main_island_size_cells = Vector2i(40, 30)
	_sim = Simulation.new(config, GameData.get_default())
	# geometria e regras de lugar; custo e desbloqueio têm suíte própria (test_economy_commands)
	_sim.free_build = true


func _place(def: StringName, origin: Vector2i, rotation: int = 0) -> CommandResult:
	return _sim.execute(PlaceBuildingCommand.new(ISLAND, def, origin, rotation))


func _road(from: Vector2i, to: Vector2i) -> CommandResult:
	return _sim.execute(BuildRoadCommand.new(ISLAND, RoadPath.l_path(from, to)))


func test_place_fills_cells_with_building_id() -> void:
	var result := _place(HOUSE, Vector2i(5, 5))
	assert_bool(result.ok()).is_true()
	var grid := _sim.world.island(ISLAND)
	var building_id := result.placed[0]
	assert_int(grid.building_at(Vector2i(5, 5))).is_equal(building_id)
	assert_int(grid.building_at(Vector2i(7, 7))).is_equal(building_id)
	assert_int(grid.building_at(Vector2i(8, 7))).is_equal(0)


func test_overlap_is_refused_and_world_untouched() -> void:
	_place(HOUSE, Vector2i(5, 5))
	var before := _sim.world.to_dict()
	assert_str(_place(HOUSE, Vector2i(7, 7)).reason).is_equal(PlacementRules.OCCUPIED)
	assert_dict(_sim.world.to_dict()).is_equal(before)


func test_outside_island_is_refused() -> void:
	assert_str(_place(HOUSE, Vector2i(38, 5)).reason).is_equal(PlacementRules.OUT_OF_ISLAND)
	assert_str(_place(HOUSE, Vector2i(-1, 5)).reason).is_equal(PlacementRules.OUT_OF_ISLAND)


func test_building_over_road_is_refused() -> void:
	_road(Vector2i(0, 6), Vector2i(20, 6))
	assert_str(_place(HOUSE, Vector2i(5, 5)).reason).is_equal(PlacementRules.ON_ROAD)


func test_unknown_building_and_bad_rotation_are_refused() -> void:
	assert_str(_place(&"nao_existe", Vector2i(5, 5)).reason).is_equal(PlacementRules.UNKNOWN_BUILDING)
	assert_str(_place(HOUSE, Vector2i(5, 5), 4).reason).is_equal(PlacementRules.INVALID_ROTATION)


func test_factory_fits_exactly_at_the_island_edge() -> void:
	assert_bool(_place(FACTORY, Vector2i(34, 24), 1).ok()).is_true()
	assert_str(_place(FACTORY, Vector2i(26, 25), 1).reason).is_equal(PlacementRules.OUT_OF_ISLAND)


func test_road_path_is_an_l_without_diagonals() -> void:
	var path := RoadPath.l_path(Vector2i(2, 2), Vector2i(6, 4))
	assert_array(path).is_equal([Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(6, 3), Vector2i(6, 4)])
	for i: int in range(1, path.size()):
		assert_int(absi(path[i].x - path[i - 1].x) + absi(path[i].y - path[i - 1].y)).is_equal(1)


func test_road_through_building_is_refused_whole() -> void:
	_place(HOUSE, Vector2i(5, 5))
	assert_str(_road(Vector2i(0, 6), Vector2i(20, 6)).reason).is_equal(PlacementRules.OCCUPIED)
	assert_bool(_sim.world.island(ISLAND).has_road(Vector2i(0, 6))).is_false()


func test_existing_road_cells_are_not_duplicated() -> void:
	_road(Vector2i(0, 0), Vector2i(10, 0))
	var result := _road(Vector2i(0, 0), Vector2i(10, 0))
	assert_bool(result.ok()).is_true()
	assert_bool(result.roads_changed).is_false()
	assert_int(_sim.world.island(ISLAND).road_cells().size()).is_equal(11)


func test_building_without_road_is_allowed_but_has_no_access() -> void:
	var building_id := _place(HOUSE, Vector2i(5, 5)).placed[0]
	assert_bool(_sim.has_road_access(building_id)).is_false()
	_road(Vector2i(0, 4), Vector2i(10, 4))
	assert_bool(_sim.has_road_access(building_id)).is_true()


func test_road_behind_the_building_does_not_give_access() -> void:
	var building_id := _place(HOUSE, Vector2i(5, 5)).placed[0]
	_road(Vector2i(0, 8), Vector2i(10, 8))
	assert_bool(_sim.has_road_access(building_id)).is_false()


func test_demolish_frees_cells_and_removes_record() -> void:
	var building_id := _place(HOUSE, Vector2i(5, 5)).placed[0]
	var result := _sim.execute(DemolishCommand.new(ISLAND, Rect2i(6, 6, 1, 1)))
	assert_array(result.removed).is_equal([building_id])
	assert_int(_sim.world.island(ISLAND).building_at(Vector2i(5, 5))).is_equal(0)
	assert_object(_sim.world.building(building_id)).is_null()
	assert_bool(_place(HOUSE, Vector2i(5, 5)).ok()).is_true()


func test_demolish_area_takes_roads_and_buildings() -> void:
	_place(HOUSE, Vector2i(5, 5))
	_place(HOUSE, Vector2i(9, 5))
	_road(Vector2i(0, 4), Vector2i(20, 4))
	var result := _sim.execute(DemolishCommand.new(ISLAND, Rect2i(0, 4, 8, 2)))
	assert_int(result.removed.size()).is_equal(1)
	assert_bool(result.roads_changed).is_true()
	assert_bool(_sim.world.island(ISLAND).has_road(Vector2i(7, 4))).is_false()
	assert_bool(_sim.world.island(ISLAND).has_road(Vector2i(8, 4))).is_true()


func test_demolish_cutting_road_splits_network() -> void:
	_road(Vector2i(0, 4), Vector2i(20, 4))
	var grid := _sim.world.island(ISLAND)
	var labels := RoadNetwork.components(grid)
	assert_int(labels[grid.index(Vector2i(0, 4))]).is_equal(labels[grid.index(Vector2i(20, 4))])
	_sim.execute(DemolishCommand.new(ISLAND, Rect2i(10, 4, 1, 1)))
	labels = RoadNetwork.components(grid)
	assert_int(labels[grid.index(Vector2i(0, 4))]).is_not_equal(labels[grid.index(Vector2i(20, 4))])


func test_demolish_nothing_is_refused() -> void:
	assert_str(_sim.execute(DemolishCommand.new(ISLAND, Rect2i(1, 1, 2, 2))).reason).is_equal(&"REASON_NOTHING_TO_DEMOLISH")


func test_ids_are_never_reused() -> void:
	var first := _place(HOUSE, Vector2i(5, 5)).placed[0]
	_sim.execute(DemolishCommand.new(ISLAND, Rect2i(5, 5, 1, 1)))
	assert_int(_place(HOUSE, Vector2i(5, 5)).placed[0]).is_greater(first)


func test_events_announce_changes() -> void:
	var events: Array[String] = []
	var on_placed := func(building_id: int) -> void: events.append("placed %d" % building_id)
	var on_removed := func(building_id: int) -> void: events.append("removed %d" % building_id)
	var on_roads := func(island_id: int) -> void: events.append("roads %d" % island_id)
	EventBus.building_placed.connect(on_placed)
	EventBus.building_removed.connect(on_removed)
	EventBus.roads_changed.connect(on_roads)
	_place(HOUSE, Vector2i(5, 5))
	_place(HOUSE, Vector2i(6, 6))
	_road(Vector2i(0, 0), Vector2i(3, 0))
	_sim.execute(DemolishCommand.new(ISLAND, Rect2i(5, 5, 1, 1)))
	EventBus.building_placed.disconnect(on_placed)
	EventBus.building_removed.disconnect(on_removed)
	EventBus.roads_changed.disconnect(on_roads)
	assert_array(events).is_equal(["placed 1", "roads 0", "removed 1"])
