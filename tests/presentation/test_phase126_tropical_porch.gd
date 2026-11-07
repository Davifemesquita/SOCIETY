extends GdUnitTestSuite
## Alpendre tropical (Fase 126): as casas dos operários e artesãos de dois andares nas ilhas tropicais ganham a varanda na
## fileira da frente (sem enxaimel saliente nem toldo); nas temperadas e nos camponeses (o quintal) nada muda.

var _config: GameConfig
var _sim: Simulation
var _tropical := -1


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	for index: int in _sim.world.islands.size():
		if _sim.world.is_tropical(index, _sim.data):
			_tropical = index


func _spec(island: int, tier: StringName, id: int = 7) -> BuildingKit.Spec:
	var record := BuildingRecord.new(id, &"house", island, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func test_tropical_workers_and_artisans_get_the_porch() -> void:
	assert_int(_tropical).is_greater_equal(0)
	for tier: StringName in [&"workers", &"artisans"]:
		for id: int in range(1, 12):
			var spec := _spec(_tropical, tier, id)
			assert_int(spec.silhouette).is_equal(BuildingDef.Silhouette.VERANDA)
			assert_int(spec.court_rows).is_equal(1)
			assert_bool(spec.jetty).is_false()
			assert_int(spec.awning).is_equal(0)
			assert_int(spec.wing).is_equal(0)


func test_temperate_houses_and_peasants_stay_as_they_were() -> void:
	for tier: StringName in [&"workers", &"artisans"]:
		var spec := _spec(0, tier)
		assert_int(spec.silhouette).is_equal(BuildingDef.Silhouette.NONE)
		assert_int(spec.court_rows).is_equal(0)
	var peasants := _spec(_tropical, &"peasants")
	assert_int(peasants.trim).is_equal(TierDef.HouseTrim.YARD)
	assert_int(peasants.silhouette).is_equal(BuildingDef.Silhouette.NONE)


func test_the_porch_is_drawn_in_front_of_the_house() -> void:
	var spec := _spec(_tropical, &"workers")
	var box := BuildingKit.veranda_box(spec)
	# a varanda vai da frente da área até a parede do corpo, que recua uma fileira
	assert_float(box.size.z).is_greater(spec.cell_m * 0.6)
	var mesh := BuildingKit.mesh(spec)
	var plain := spec._copy()
	plain.silhouette = BuildingDef.Silhouette.NONE
	assert_int(mesh.surface_get_array_len(0)).is_greater(BuildingKit.mesh(plain).surface_get_array_len(0))
