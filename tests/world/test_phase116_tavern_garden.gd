extends GdUnitTestSuite
## Mesas da taverna (Fase 116): em volta da taverna, até MAX_TABLES células livres encostadas nela, as mais perto da
## frente primeiro; o recheio as deixa limpas; uma estrada tira a mesa da célula; os guarda-sóis fecham à noite.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _tavern() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"tavern", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"tavern", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_tables_sit_on_free_cells_around_the_tavern() -> void:
	var record := _tavern()
	var grid := _sim.world.island(0)
	var def := _sim.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var cells := TavernGardenView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_greater(0)
	assert_int(cells.size()).is_less_equal(TavernGardenView.MAX_TABLES)
	for cell: Vector2i in cells:
		assert_bool(area.grow(1).has_point(cell)).is_true()
		assert_bool(area.has_point(cell)).is_false()
		assert_int(grid.building_at(cell)).is_equal(0)
		assert_bool(grid.has_road(cell)).is_false()
		assert_int(cells[cell]).is_equal(record.id)


func test_the_scatter_leaves_the_tables_alone() -> void:
	_tavern()
	var cells := TavernGardenView.cells(_sim.world, _sim.data, 0)
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var clear: Dictionary = context[0]
	for cell: Vector2i in cells:
		assert_bool(clear.has(cell)).is_true()


func test_a_road_takes_the_table_away() -> void:
	_tavern()
	var cells := TavernGardenView.cells(_sim.world, _sim.data, 0)
	var first: Vector2i = cells.keys()[0]
	_sim.world.island(0).set_road(first, IslandGrid.Road.DIRT)
	assert_bool(TavernGardenView.cells(_sim.world, _sim.data, 0).has(first)).is_false()


func test_the_view_draws_the_tables_and_furls_at_night() -> void:
	_tavern()
	var view: TavernGardenView = auto_free(TavernGardenView.new())
	add_child(view)
	view.setup(_sim)
	var count := TavernGardenView.cells(_sim.world, _sim.data, 0).size()
	assert_int(view.table_count()).is_equal(count)
	view.set_furled(true)
	assert_bool(view.is_furled()).is_true()
	assert_bool((view.get_node("Furled") as Node3D).visible).is_true()
	assert_bool((view.get_node("CanopyTint") as Node3D).visible).is_false()
	view.set_furled(false)
	assert_bool((view.get_node("CanopyWhite") as Node3D).visible).is_true()


func test_the_canopy_alternates_white_and_colored_gores() -> void:
	var white := TavernGardenView.canopy_mesh(false)
	var tint := TavernGardenView.canopy_mesh(true)
	assert_int(white.surface_get_array_len(0)).is_equal(tint.surface_get_array_len(0))
	assert_int(white.surface_get_array_len(0)).is_greater(0)
