extends GdUnitTestSuite
## Pombal (Fase 191): nas fazendas do resto certo, na célula do canto da frente, fora do lote, livre; nada nas outras fazendas
## nem na ilha plana; os pombos pousam no telhadinho e no poleiro; o pombal é alto.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


func test_the_right_farms_get_a_dovecote_at_the_front_corner() -> void:
	var grid := _sim.world.island(0)
	var center := grid.size / 2
	var got := 0
	for k: int in 6:
		var origin := center + Vector2i(-20 + k * 8, 0)
		var result := _sim.execute(PlaceBuildingCommand.new(0, &"sheep_farm", origin, 0))
		if not result.ok():
			continue
		var id: int = result.placed[0]
		var record := _sim.world.building(id)
		var found: Variant = DovecoteView.spot(_sim, record)
		if posmod(id, DovecoteView.DOVECOTE_EVERY) != DovecoteView.DOVECOTE_REST:
			assert_object(found).is_null()
			continue
		if found == null:
			continue
		var place: Transform3D = found
		var cell := grid.world_to_cell(place.origin)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		assert_bool(area.has_point(cell)).is_false()
		assert_bool(area.grow(1).has_point(cell)).is_true()
		got += 1
	assert_int(got).is_greater(0)


func test_no_dovecote_by_other_buildings_or_on_the_flat_island() -> void:
	var lumberjack := BuildingRecord.new(2, &"lumberjack", 0, Vector2i(10, 10), 0)
	assert_object(DovecoteView.spot(_sim, lumberjack)).is_null()
	var flat := SimFixture.simulation(Vector2i(60, 40))
	flat.free_build = true
	flat.ignore_terrain = true
	var id := SimFixture.place(flat, &"sheep_farm", Vector2i(10, 10), 0)
	assert_object(DovecoteView.spot(flat, flat.world.building(id))).is_null()


func test_pigeons_perch_on_the_roof_and_ledges() -> void:
	var box := DovecoteView.dovecote_mesh().get_aabb()
	assert_float(box.end.y).is_equal_approx(DovecoteView.POLE_M + DovecoteView.HOUSE_HALF.y * 2.0 + DovecoteView.ROOF_M, 0.02)
	for perch: Vector3 in DovecoteView.PERCHES:
		assert_float(perch.y).is_greater(DovecoteView.POLE_M)
		assert_float(perch.y).is_less_equal(box.end.y + 0.01)
