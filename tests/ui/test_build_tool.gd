extends GdUnitTestSuite
## Ferramenta de construção por células: construir, traçar estrada, demolir e selecionar.

const HOUSE := &"placeholder_house"

var _sim: Simulation
var _tool: BuildTool


func before_test() -> void:
	var config := GameConfig.new()
	config.main_island_size_cells = Vector2i(60, 60)
	_sim = Simulation.new(config, BuildingCatalog.get_default())
	_tool = auto_free(BuildTool.new())
	_tool.setup(_sim, null, config.cell_size_m)


func _house() -> BuildingDef:
	return _sim.catalog.find(HOUSE)


func test_click_builds_centered_on_cursor_and_stays_in_mode() -> void:
	_tool.start_building(_house())
	_tool.press(Vector2i(10, 10))
	_tool.release(Vector2i(10, 10))
	assert_int(_sim.world.island(0).building_at(Vector2i(9, 9))).is_equal(1)
	assert_int(_tool.mode).is_equal(BuildTool.Mode.BUILDING)
	_tool.press(Vector2i(20, 10))
	assert_int(_sim.world.buildings.size()).is_equal(2)


func test_rotation_changes_the_entrance() -> void:
	_tool.start_building(_house())
	_tool.rotate_building()
	_tool.press(Vector2i(10, 10))
	var record := _sim.world.building(1)
	assert_int(record.rotation).is_equal(1)


func test_invalid_preview_reports_reason_and_refuses() -> void:
	var reasons: Array[StringName] = []
	_tool.refused.connect(func(reason: StringName) -> void: reasons.append(reason))
	_tool.start_building(_house())
	_tool.hover(Vector2i(0, 0))
	assert_str(_tool.preview_reason()).is_equal(PlacementRules.OUT_OF_ISLAND)
	_tool.press(Vector2i(0, 0))
	assert_array(reasons).is_equal([PlacementRules.OUT_OF_ISLAND])
	assert_int(_sim.world.buildings.size()).is_equal(0)


func test_road_is_dragged_as_an_l() -> void:
	_tool.start_road()
	_tool.press(Vector2i(2, 2))
	_tool.hover(Vector2i(8, 5))
	assert_int(_tool.road_cells().size()).is_equal(10)
	_tool.release(Vector2i(8, 5))
	assert_int(_sim.world.island(0).road_cells().size()).is_equal(10)
	assert_bool(_tool.dragging).is_false()


func test_road_preview_through_building_is_red() -> void:
	_tool.start_building(_house())
	_tool.press(Vector2i(10, 10))
	_tool.start_road()
	_tool.press(Vector2i(5, 10))
	_tool.hover(Vector2i(15, 10))
	assert_str(_tool.preview_reason()).is_equal(PlacementRules.OCCUPIED)


func test_demolish_drag_clears_area() -> void:
	_tool.start_building(_house())
	_tool.press(Vector2i(10, 10))
	_tool.press(Vector2i(20, 10))
	_tool.start_demolish()
	_tool.press(Vector2i(8, 8))
	_tool.release(Vector2i(22, 9))
	assert_int(_sim.world.buildings.size()).is_equal(0)


func test_escape_cancels_drag_then_mode_then_selection() -> void:
	_tool.start_road()
	_tool.press(Vector2i(2, 2))
	_tool.cancel()
	assert_bool(_tool.dragging).is_false()
	assert_int(_tool.mode).is_equal(BuildTool.Mode.ROAD)
	_tool.cancel()
	assert_int(_tool.mode).is_equal(BuildTool.Mode.NONE)


func test_click_without_tool_selects_building() -> void:
	_tool.start_building(_house())
	_tool.press(Vector2i(10, 10))
	_tool.cancel()
	_tool.press(Vector2i(10, 10))
	assert_int(_tool.selected_id).is_equal(1)
	_tool.press(Vector2i(30, 30))
	assert_int(_tool.selected_id).is_equal(0)


func test_demolishing_selected_building_clears_selection() -> void:
	_tool.start_building(_house())
	_tool.press(Vector2i(10, 10))
	_tool.cancel()
	_tool.press(Vector2i(10, 10))
	_tool.start_demolish()
	_tool.press(Vector2i(10, 10))
	_tool.release(Vector2i(10, 10))
	assert_int(_tool.selected_id).is_equal(0)


func test_preview_is_readable_when_mode_changes() -> void:
	var seen: Array[StringName] = []
	_tool.changed.connect(func() -> void:
		if _tool.mode == BuildTool.Mode.BUILDING:
			seen.append(_tool.preview_reason())
			assert_int(_tool.building_rect().size.x).is_equal(3))
	_tool.hover(Vector2i(10, 10))
	_tool.start_building(_house())
	assert_array(seen).is_equal([PlacementRules.OK])
