extends GdUnitTestSuite
## Chapa ondulada (Fase 138): as fábricas da lista existem e são de produção, fora da lista da ardósia; as casas e os
## serviços não têm; com tela, o shader do kit compila com os parâmetros novos.


func test_the_iron_list_is_made_of_factories() -> void:
	var data := GameData.get_default()
	for id: StringName in BuildingView.IRON_ROOFS:
		var def := data.building(id)
		assert_object(def).is_not_null()
		assert_int(def.kind).is_equal(BuildingDef.Kind.PRODUCTION)
		assert_bool(BuildingView.SLATE_ROOFS.has(id)).is_false()
	# todas as de fumaça pesada estão nela
	for def: BuildingDef in data.buildings:
		if def.smoke == BuildingDef.Smoke.HEAVY:
			assert_bool(BuildingView.IRON_ROOFS.has(def.id)).is_true()
	assert_bool(BuildingView.IRON_ROOFS.has(&"house")).is_false()
	assert_bool(BuildingView.IRON_ROOFS.has(&"church")).is_false()


func test_the_kit_shader_has_the_iron_sheet_parameters() -> void:
	var shader := load("res://shaders/building_kit.gdshader") as Shader
	var names: Array[String] = []
	for entry: Dictionary in shader.get_shader_uniform_list(true):
		var raw: String = entry["name"]
		names.append(raw)
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	assert_bool(names.has("sheet_color")).is_true()
	assert_bool(names.has("rust_color")).is_true()
	assert_bool(names.has("corrugation_m")).is_true()
