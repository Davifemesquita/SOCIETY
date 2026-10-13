extends GdUnitTestSuite
## Custo, desbloqueio e terreno ao construir; estrada cobrada por célula nova; devolução ao
## demolir; pausa, bloqueio de upgrade e nível de imposto.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = false
	_sim.world.money = 10000.0
	SimFixture.give(_sim, &"planks", 20.0)


func _place(def_id: StringName, origin: Vector2i, rotation: int = 0) -> CommandResult:
	return _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))


func test_building_charges_money_and_materials() -> void:
	assert_bool(_place(&"sawmill", Vector2i(10, 10)).ok()).is_true()
	assert_float(_sim.world.money).is_equal(10000.0 - 200.0)
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(17.0)


func test_missing_materials_refuse_and_charge_nothing() -> void:
	SimFixture.give(_sim, &"planks", 2.0)
	assert_str(_place(&"sawmill", Vector2i(10, 10)).reason).is_equal(PlacementRules.NO_MATERIALS)
	assert_float(_sim.world.money).is_equal(10000.0)
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(2.0)


func test_balance_may_go_negative_down_to_the_limit() -> void:
	_sim.world.money = -9850.0
	assert_bool(_place(&"lumberjack", Vector2i(10, 10)).ok()).is_true()
	assert_str(_place(&"lumberjack", Vector2i(20, 10)).reason).is_equal(PlacementRules.NO_MONEY)


func test_locked_building_needs_population() -> void:
	assert_str(_place(&"weavery", Vector2i(10, 10)).reason).is_equal(PlacementRules.LOCKED)
	_sim.free_build = true
	SimFixture.house(_sim, 30, 30, &"peasants", 10.0)
	SimFixture.house(_sim, 33, 30, &"peasants", 10.0)
	SimFixture.house(_sim, 36, 30, &"peasants", 10.0)
	_sim.free_build = false
	assert_bool(_place(&"weavery", Vector2i(10, 10)).ok()).is_true()


func test_brickworks_needs_150_workers_like_the_spec() -> void:
	_sim.free_build = true
	for i: int in 7:
		SimFixture.house(_sim, 3 + i * 3, 30, &"workers", 20.0)
	_sim.free_build = false
	assert_int(_sim.world.population(&"workers")).is_equal(140)
	assert_str(_place(&"brickworks", Vector2i(60, 10)).reason).is_equal(PlacementRules.LOCKED)
	_sim.free_build = true
	SimFixture.house(_sim, 30, 30, &"workers", 10.0)
	_sim.free_build = false
	assert_bool(_place(&"brickworks", Vector2i(60, 10)).ok()).is_true()


func test_fishery_needs_the_coast() -> void:
	assert_str(_place(&"fishery", Vector2i(10, 10)).reason).is_equal(PlacementRules.NEEDS_COAST)
	assert_bool(_place(&"fishery", Vector2i(10, 0)).ok()).is_true()
	assert_bool(_place(&"fishery", Vector2i(117, 20)).ok()).is_true()


func test_farm_needs_fertility_of_the_island() -> void:
	var base := GameData.get_default()
	var dry := GameData.new()
	dry.goods = base.goods
	dry.tiers = base.tiers
	dry.buildings = base.buildings
	var profile := IslandProfileDef.new()
	profile.id = &"seca"
	profile.fertilities = [&"wheat"]
	dry.island_profiles = [profile]
	var sim := Simulation.new(_sim.config, dry)
	sim.free_build = true
	assert_str(sim.execute(PlaceBuildingCommand.new(0, &"hop_farm", Vector2i(10, 10), 0)).reason).is_equal(PlacementRules.NO_FERTILITY)
	assert_bool(sim.execute(PlaceBuildingCommand.new(0, &"wheat_farm", Vector2i(10, 10), 0)).ok()).is_true()


func test_road_charges_only_new_cells() -> void:
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(0, 5), Vector2i(9, 5))))
	assert_float(_sim.world.money).is_equal(10000.0 - 10 * 5)
	_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(Vector2i(0, 5), Vector2i(14, 5))))
	assert_float(_sim.world.money).is_equal(10000.0 - 15 * 5)


func test_demolish_returns_half_the_materials() -> void:
	_place(&"sawmill", Vector2i(10, 10))
	_sim.execute(DemolishCommand.new(0, Rect2i(10, 10, 1, 1)))
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal(17.0 + 1.0)


func test_pause_upgrade_block_and_tax_level() -> void:
	var sawmill := _place(&"sawmill", Vector2i(10, 10)).placed[0]
	assert_bool(_sim.execute(SetPausedCommand.new(sawmill, true)).ok()).is_true()
	assert_bool(_sim.world.building(sawmill).paused).is_true()
	var house := _place(&"house", Vector2i(30, 10)).placed[0]
	assert_bool(_sim.execute(SetPausedCommand.new(house, true)).ok()).is_false()
	assert_bool(_sim.execute(SetUpgradeBlockedCommand.new(house, true)).ok()).is_true()
	assert_bool(_sim.world.building(house).upgrade_blocked).is_true()
	assert_bool(_sim.execute(SetTaxLevelCommand.new(&"peasants", WorldState.TaxLevel.HIGH)).ok()).is_true()
	assert_int(_sim.world.tax_level(&"peasants")).is_equal(WorldState.TaxLevel.HIGH)
	assert_bool(_sim.execute(SetTaxLevelCommand.new(&"peasants", 7)).ok()).is_false()


## Desde a Fase 6 as tábuas vêm no navio inicial e descem no primeiro entreposto
## (test_colonization.gd confere a descarga).
func test_new_world_starts_with_money_and_planks() -> void:
	var fresh := Simulation.new(GameConfig.get_default(), GameData.get_default())
	assert_float(fresh.world.money).is_equal(50000.0)
	assert_float(fresh.world.player_ships()[0].tons_of(&"planks")).is_equal(40.0)
