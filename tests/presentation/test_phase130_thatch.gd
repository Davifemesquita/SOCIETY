extends GdUnitTestSuite
## Telhado de sapê (Fase 130): só as casas dos camponeses têm sapê; as outras casas e os prédios de produção ficam com o
## telhado de antes; com tela, o shader do kit compila com o parâmetro novo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _house(tier: StringName) -> BuildingRecord:
	var record := BuildingRecord.new(3, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return record


func test_only_peasant_houses_are_thatched() -> void:
	assert_bool(BuildingView.thatched(_sim, _house(&"peasants"))).is_true()
	for tier: StringName in [&"workers", &"artisans", &"engineers", &"investors"]:
		assert_bool(BuildingView.thatched(_sim, _house(tier))).is_false()
	var lumberjack := BuildingRecord.new(4, &"lumberjack", 0, Vector2i(20, 10), 0)
	assert_bool(BuildingView.thatched(_sim, lumberjack)).is_false()


func test_the_kit_shader_has_the_thatch_parameter() -> void:
	var shader := load("res://shaders/building_kit.gdshader") as Shader
	var names: Array[String] = []
	for entry: Dictionary in shader.get_shader_uniform_list(true):
		var raw: String = entry["name"]
		names.append(raw)
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	assert_bool(names.has("thatch_color")).is_true()
