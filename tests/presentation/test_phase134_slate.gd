extends GdUnitTestSuite
## Ardósia (Fase 134): os serviços de pedra da lista têm ardósia; as casas e as fábricas não; com tela, o shader do kit
## compila com os parâmetros novos.


func test_the_slate_list_is_made_of_stone_services() -> void:
	var data := GameData.get_default()
	for id: StringName in BuildingView.SLATE_ROOFS:
		var def := data.building(id)
		assert_object(def).is_not_null()
		assert_bool(def.kind != BuildingDef.Kind.PRODUCTION).is_true()
	assert_bool(BuildingView.SLATE_ROOFS.has(&"house")).is_false()
	assert_bool(BuildingView.SLATE_ROOFS.has(&"lumberjack")).is_false()


func test_the_kit_shader_has_the_slate_parameters() -> void:
	var shader := load("res://shaders/building_kit.gdshader") as Shader
	var names: Array[String] = []
	for entry: Dictionary in shader.get_shader_uniform_list(true):
		var raw: String = entry["name"]
		names.append(raw)
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	assert_bool(names.has("slate_color")).is_true()
	assert_bool(names.has("thatch_color")).is_true()
