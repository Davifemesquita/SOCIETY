extends GdUnitTestSuite
## Jazidas à vista (Fase 128): cada mancha de jazida livre ganha um afloramento no meio e pedras do minério sobre ela, na
## cor do bem; a mina em cima tira tudo daquela mancha; a ilha plana não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_each_free_patch_gets_one_outcrop_and_ore_on_it() -> void:
	var grid := _sim.world.island(0)
	var patches := DepositView.patches(grid)
	assert_int(patches.size()).is_greater(0)
	var entries := DepositView.places(_sim.world, 0)
	var outcrops := entries.filter(func(entry: Array) -> bool: return entry[0] == DepositView.Kind.OUTCROP)
	assert_int(outcrops.size()).is_equal(patches.size())
	for entry: Array in entries:
		if entry[0] != DepositView.Kind.ORE:
			continue
		var place: Transform3D = entry[1]
		var cell := grid.world_to_cell(place.origin)
		assert_bool(grid.deposit_at(cell) != &"").is_true()
		var color: Color = entry[2]
		var expected: Color = DepositView.ORE_COLORS.get(grid.deposit_at(cell), DepositView.ORE_DEFAULT)
		# o tom varia em volta da cor do bem
		assert_float(absf(color.h - expected.h)).is_less(0.1)


func test_a_mine_takes_its_patch_away() -> void:
	var grid := _sim.world.island(0)
	var before := DepositView.places(_sim.world, 0).filter(func(entry: Array) -> bool:
		return entry[0] == DepositView.Kind.OUTCROP).size()
	var mine := &""
	for def_id: StringName in [&"iron_mine", &"coal_mine"]:
		if not SiteFinder.find(_sim, def_id, 0, grid.size / 2).is_empty():
			mine = def_id
			break
	if mine == &"":
		return
	var found: Array = SiteFinder.find(_sim, mine, 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, mine, origin, rotation)).ok()).is_true()
	var after := DepositView.places(_sim.world, 0).filter(func(entry: Array) -> bool:
		return entry[0] == DepositView.Kind.OUTCROP).size()
	assert_int(after).is_equal(before - 1)


func test_no_deposits_on_the_flat_island() -> void:
	var sim := SimFixture.simulation()
	assert_int(DepositView.places(sim.world, 0).size()).is_equal(0)
