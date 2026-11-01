extends GdUnitTestSuite
## Hera nas paredes (Fase 185): os serviços de pedra têm a hera cheia; uma parte das casas dos artesãos para cima tem menos; as
## casas dos camponeses e operários, as fábricas e tudo nas ilhas tropicais ficam sem; com tela, o shader do kit compila com os
## parâmetros da hera.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _house(tier: StringName, id: int) -> BuildingRecord:
	var record := BuildingRecord.new(id, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return record


func test_stone_services_are_covered() -> void:
	for def_id: StringName in BuildingView.IVY_SERVICES:
		var record := BuildingRecord.new(5, def_id, 0, Vector2i(10, 10), 0)
		assert_float(BuildingView.ivy_of(_sim, record)).override_failure_message(String(def_id)) \
				.is_equal(BuildingView.IVY_FULL)
	var lumberjack := BuildingRecord.new(6, &"lumberjack", 0, Vector2i(20, 10), 0)
	assert_float(BuildingView.ivy_of(_sim, lumberjack)).is_equal(0.0)


func test_some_older_houses_have_less_ivy() -> void:
	for tier: StringName in [&"artisans", &"engineers", &"investors"]:
		var with_ivy := 0
		for id: int in range(1, 41):
			var ivy := BuildingView.ivy_of(_sim, _house(tier, id))
			assert_bool(ivy == 0.0 or ivy == BuildingView.IVY_HOUSE).is_true()
			if ivy > 0.0:
				with_ivy += 1
		# uma a cada IVY_HOUSE_EVERY, mais ou menos
		assert_int(with_ivy).is_between(3, 20)
	for tier: StringName in [&"peasants", &"workers"]:
		for id: int in range(1, 41):
			assert_float(BuildingView.ivy_of(_sim, _house(tier, id))).is_equal(0.0)


func test_no_ivy_on_tropical_islands() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([60])
	config.tropical_island_sizes_cells = PackedInt32Array([60])
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, config,
			GameData.get_default()))
	var tropical := -1
	for island_id: int in sim.world.islands.size():
		if sim.world.is_tropical(island_id, sim.data):
			tropical = island_id
	assert_int(tropical).is_greater(0)
	var church := BuildingRecord.new(5, &"church", tropical, Vector2i(10, 10), 0)
	assert_float(BuildingView.ivy_of(sim, church)).is_equal(0.0)


func test_the_kit_shader_has_the_ivy_parameters() -> void:
	var shader := load("res://shaders/building_kit.gdshader") as Shader
	var names: Array[String] = []
	for entry: Dictionary in shader.get_shader_uniform_list(true):
		var raw: String = entry["name"]
		names.append(raw)
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	# (o "ivy" é parâmetro de instância: não entra na lista, como o "thatch")
	for wanted: String in ["ivy_dark", "ivy_light", "ivy_reach_m"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
