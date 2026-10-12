extends GdUnitTestSuite
## Critérios de pronto da Fase 1 que dá para provar sem tela:
## 50 prédios ligados por estradas, e salvar e carregar sem diferença.

const HOUSE := &"placeholder_house"
const SaveSystemScript := preload("res://core/save_system.gd")
const TEST_DIR := "user://test_saves_phase1"

var _sim: Simulation


func before_test() -> void:
	_sim = Simulation.new(GameConfig.get_default(), BuildingCatalog.get_default())


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
	DirAccess.remove_absolute(TEST_DIR)


func test_fifty_buildings_share_one_road_network() -> void:
	var ids := TownLayout.build(_sim, 50, HOUSE)
	assert_int(ids.size()).is_equal(50)
	var grid := _sim.world.island(Simulation.MAIN_ISLAND)
	var labels := RoadNetwork.components(grid)
	var networks := PackedInt32Array()
	for building_id: int in ids:
		var record := _sim.world.building(building_id)
		var touching := RoadNetwork.access_labels(grid, labels, record, _sim.def_of(record))
		assert_int(touching.size()).override_failure_message("prédio %d sem estrada" % building_id).is_greater(0)
		for label: int in touching:
			if not networks.has(label):
				networks.append(label)
	assert_int(networks.size()).is_equal(1)


func test_save_and_load_world_without_difference() -> void:
	TownLayout.build(_sim, 50, HOUSE)
	_sim.execute(DemolishCommand.new(Simulation.MAIN_ISLAND, Rect2i(4, 3, 2, 2)))
	var saves: SaveSystemScript = auto_free(SaveSystemScript.new())
	saves.save_dir = TEST_DIR
	assert_int(saves.save_game("criterio", {"world": _sim.world.to_dict()})).is_equal(OK)
	var loaded := saves.load_game("criterio")
	var world_data: Dictionary = loaded["world"]
	var restored := WorldState.from_dict(world_data, _sim.catalog)
	assert_object(restored).is_not_null()
	assert_dict(restored.to_dict()).is_equal(_sim.world.to_dict())
	var grid := _sim.world.island(Simulation.MAIN_ISLAND)
	var restored_grid := restored.island(Simulation.MAIN_ISLAND)
	assert_bool(restored_grid.occupancy == grid.occupancy).is_true()
	assert_bool(restored_grid.roads == grid.roads).is_true()
	assert_int(restored.next_building_id).is_equal(_sim.world.next_building_id)


func test_inconsistent_save_is_rejected() -> void:
	TownLayout.build(_sim, 3, HOUSE)
	var data := _sim.world.to_dict()
	var buildings: Array = data["buildings"]
	var first: Dictionary = buildings[0]
	var overlapping := first.duplicate()
	overlapping["id"] = 999
	buildings.append(overlapping)
	data["next_building_id"] = 1000
	assert_object(WorldState.from_dict(data, _sim.catalog)).is_null()


func test_save_with_wrong_types_is_rejected() -> void:
	assert_object(WorldState.from_dict({"islands": "x", "buildings": [], "next_building_id": 1}, _sim.catalog)).is_null()
	var data := _sim.world.to_dict()
	data["next_building_id"] = 1.5
	assert_object(WorldState.from_dict(data, _sim.catalog)).is_null()
	var bad_def := _sim.world.to_dict()
	var bad_buildings: Array = bad_def["buildings"]
	bad_buildings.append({"id": 5, "def": &"nao_existe", "island": 0, "origin": Vector2i(1, 1), "rotation": 0})
	bad_def["next_building_id"] = 6
	assert_object(WorldState.from_dict(bad_def, _sim.catalog)).is_null()
