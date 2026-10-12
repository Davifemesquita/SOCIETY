extends GdUnitTestSuite
## O catálogo de prédios carrega, é válido e todo nome tem tradução.


func test_catalog_loads_and_is_valid() -> void:
	var catalog := BuildingCatalog.get_default()
	assert_int(catalog.buildings.size()).is_equal(3)
	assert_array(Array(catalog.validate())).is_empty()


func test_placeholder_sizes() -> void:
	var catalog := BuildingCatalog.get_default()
	assert_vector(catalog.find(&"placeholder_house").size).is_equal(Vector2i(3, 3))
	assert_vector(catalog.find(&"placeholder_workshop").size).is_equal(Vector2i(4, 4))
	assert_vector(catalog.find(&"placeholder_factory").size).is_equal(Vector2i(6, 6))


func test_every_name_key_is_translated() -> void:
	for def: BuildingDef in BuildingCatalog.get_default().buildings:
		assert_str(TranslationServer.translate(def.name_key)).is_not_equal(def.name_key)


func test_duplicate_ids_are_reported() -> void:
	var catalog := BuildingCatalog.new()
	var a := BuildingDef.new()
	a.id = &"x"
	a.name_key = "X"
	catalog.buildings = [a, a]
	assert_int(catalog.validate().size()).is_equal(1)
