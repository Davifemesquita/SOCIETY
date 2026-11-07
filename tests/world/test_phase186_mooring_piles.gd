extends GdUnitTestSuite
## Estacas de atracação (Fase 186): diante do entreposto e na ponta do píer, na água funda o bastante, do lado do mar; nada nos
## outros prédios; o feixe tem as estacas acima da água e o pé dentro dela.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _place(def_id: StringName) -> int:
	var grid := _sim.world.island(0)
	var found := SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	assert_bool(result.ok()).is_true()
	return result.placed[0]


func test_piles_stand_in_the_water_off_the_trading_post() -> void:
	var post := _place(&"trading_post")
	var record := _sim.world.building(post)
	var def := _sim.def_of(record)
	var piles := MooringPileView.spots(_sim.world, record, def, _config.cell_size_m)
	assert_int(piles.size()).is_greater(0)
	var grid := _sim.world.island(0)
	var center := grid.rect_world(Footprint.rect(record.origin, def.size, record.rotation))
	var out := HarborView.seaward(_sim.world, center, Footprint.rect(record.origin, def.size, record.rotation),
			_config.cell_size_m, record.rotation)
	for place: Transform3D in piles:
		assert_bool(HarborView.afloat(_sim.world, place.origin)).is_true()
		assert_float(place.origin.y).is_equal(0.0)
		# do lado do mar do entreposto
		assert_float((place.origin - center).dot(out)).is_greater(0.0)


func test_no_piles_by_other_buildings() -> void:
	var lumberjack := BuildingRecord.new(9, &"lumberjack", 0, Vector2i(10, 10), 0)
	var def := _sim.def_of(lumberjack)
	assert_array(MooringPileView.spots(_sim.world, lumberjack, def, _config.cell_size_m)).is_empty()


func test_the_cluster_rises_out_of_the_water_from_below() -> void:
	var box := MooringPileView.cluster_mesh().get_aabb()
	assert_float(box.position.y).is_equal_approx(MooringPileView.FOOT_M, 0.01)
	assert_float(box.end.y).is_between(1.4, 2.2)
	assert_float(maxf(box.size.x, box.size.z)).is_less(1.5)
