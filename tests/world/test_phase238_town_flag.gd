extends GdUnitTestSuite
## Bandeira na prefeitura (Fase 238): o mastro sobe do remate da cúpula da prefeitura, acima do telhado; outros prédios não têm;
## a bandeira vai do mastro para +x e fica no alto do mastro.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _place(def_id: StringName) -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found := SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_pole_rises_from_the_dome_of_the_town_hall() -> void:
	var record := _place(&"town_hall")
	var found: Variant = TownFlagView.foot_of(_sim, record)
	assert_bool(found is Vector3).is_true()
	var foot: Vector3 = found
	var grid := _sim.world.island(0)
	var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
	assert_bool(spec.dome).is_true()
	var def := _sim.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	# no meio do prédio, bem acima da cumeeira
	assert_float(Vector2(foot.x - model.origin.x, foot.z - model.origin.z).length()).is_less(0.01)
	assert_float(foot.y - model.origin.y).is_greater(spec.height_m + spec.roof_m + BuildingKit.DRUM_M)
	assert_float(foot.y - model.origin.y).is_equal_approx(BuildingKit.dome_finial(spec).y, 0.01)


func test_other_buildings_have_no_flag() -> void:
	var record := _place(&"theater")
	assert_object(TownFlagView.foot_of(_sim, record)).is_null()


func test_the_flag_hangs_from_the_pole_along_x() -> void:
	var flag := TownFlagView.flag_mesh().get_aabb()
	assert_float(flag.position.x).is_equal_approx(0.0, 0.01)
	assert_float(flag.size.x).is_equal_approx(TownFlagView.FLAG_M.x, 0.01)
	assert_float(flag.size.y).is_equal_approx(TownFlagView.FLAG_M.y, 0.01)
	var pole := TownFlagView.pole_mesh().get_aabb()
	assert_float(pole.end.y).is_greater(TownFlagView.POLE_M)
	# a bandeira fica abaixo da bola dourada e acima do pé
	var top := TownFlagView.POLE_M - TownFlagView.FLAG_BELOW_M
	assert_float(top).is_less(pole.end.y)
	assert_float(top - TownFlagView.FLAG_M.y).is_greater(0.5)
