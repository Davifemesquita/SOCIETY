extends GdUnitTestSuite
## Sistema central de ícones e o Theme único (seção 10): todo bem, prédio, classe, necessidade e
## navio tem ícone no atlas; o ícone que falta cai na interrogação; o Theme gravado é o que o
## ThemeBuilder monta e vale para o projeto todo; retratos placeholder existem.


func test_every_definition_has_an_icon() -> void:
	var data := GameData.get_default()
	var missing: Array[String] = []
	var names: Array[String] = []
	for good: GoodDef in data.goods:
		names.append("good_" + good.id)
	for building: BuildingDef in data.buildings:
		names.append("building_" + building.id)
	for tier: TierDef in data.tiers:
		names.append("tier_" + tier.id)
		for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
			names.append("need_" + need.id)
	for ship: ShipDef in data.ships:
		names.append("ship_" + ship.id)
	for state: String in ["no_input", "no_workers", "output_full", "no_road", "no_modules", "paused", "no_warehouse",
			"no_trees", "protest", "disconnected"]:
		names.append("state_" + state)
	for layer: String in MapOverlays.ICONS.values():
		names.append(layer)
	for name: String in names:
		if not Icons.has(name):
			missing.append(name)
	assert_array(missing).is_empty()


func test_icons_are_regions_of_the_atlas() -> void:
	var icon := Icons.good(&"fish") as AtlasTexture
	assert_object(icon).is_not_null()
	assert_vector(icon.region.size).is_equal(Vector2(128, 128))
	assert_object(Icons.good(&"fish")).is_same(icon)
	var image := icon.get_image()
	assert_float(image.get_pixel(64, 64).a).is_greater(0.5)


func test_a_missing_icon_falls_back_to_the_question_mark() -> void:
	var missing := Icons.get_icon("good_inexistente") as AtlasTexture
	var fallback := Icons.get_icon(Icons.MISSING) as AtlasTexture
	assert_object(missing).is_not_null()
	assert_object(missing.region).is_equal(fallback.region)


func test_portraits_exist_for_each_class_and_character() -> void:
	for tier: TierDef in GameData.get_default().tiers:
		assert_object(Icons.portrait("tier_" + tier.id)).is_not_null()
	assert_object(Icons.portrait("advisor")).is_not_null()
	assert_object(Icons.portrait("trader")).is_not_null()


func test_the_project_uses_the_single_theme_with_the_spec_fonts() -> void:
	assert_str(str(ProjectSettings.get_setting("gui/theme/custom"))).is_equal("res://ui/theme/society_theme.tres")
	var saved: Theme = load("res://ui/theme/society_theme.tres")
	assert_str(saved.default_font.resource_path).is_equal(ThemeBuilder.FONT_REGULAR)
	var title: FontVariation = saved.get_font(&"font", &"TitleLabel")
	assert_str(title.base_font.resource_path).is_equal(ThemeBuilder.FONT_TITLE)


## O .tres gravado tem que ser o que o ThemeBuilder monta: mudou o código, rode tools/build_theme.gd.
func test_the_saved_theme_matches_the_builder() -> void:
	var saved: Theme = load("res://ui/theme/society_theme.tres")
	var built := ThemeBuilder.build()
	var saved_types := Array(saved.get_type_list())
	saved_types.sort()
	var built_types := Array(built.get_type_list())
	built_types.sort()
	assert_array(saved_types).is_equal(built_types)
	for type: StringName in built.get_type_list():
		for name: StringName in built.get_color_list(type):
			assert_object(saved.get_color(name, type)).override_failure_message("%s/%s" % [type, name]).is_equal(built.get_color(name, type))
		for name: StringName in built.get_constant_list(type):
			assert_int(saved.get_constant(name, type)).override_failure_message("%s/%s" % [type, name]).is_equal(built.get_constant(name, type))


func test_colorblind_mode_changes_the_status_colors() -> void:
	var before := UiPalette.colorblind
	UiPalette.colorblind = false
	var normal := UiPalette.status(UiPalette.Status.GOOD)
	UiPalette.colorblind = true
	var colorblind := UiPalette.status(UiPalette.Status.GOOD)
	UiPalette.colorblind = before
	assert_bool(normal == colorblind).is_false()
	assert_int(UiPalette.status_of(0.95, 0.9, 0.5)).is_equal(UiPalette.Status.GOOD)
	assert_int(UiPalette.status_of(0.6, 0.9, 0.5)).is_equal(UiPalette.Status.PARTIAL)
	assert_int(UiPalette.status_of(0.1, 0.9, 0.5)).is_equal(UiPalette.Status.BAD)
