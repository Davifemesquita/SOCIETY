extends GdUnitTestSuite
## Fotos e retratos nos menus (Fase 51): uma foto para cada prédio (a casa, uma por classe; o píer fica com o ícone), o
## acabamento de pintura (PhotoGrade), os cartões do menu de construção e o painel do selecionado com a foto, e os
## retratos de pinturas em domínio público com o crédito de cada obra.

const GAME := "res://ui/screens/game_screen.tscn"
const PORTRAITS: Array[String] = ["tier_peasants", "tier_workers", "tier_artisans", "tier_engineers", "tier_investors",
		"advisor", "trader"]


func after_test() -> void:
	GameScreen.use_sky3d = true


func test_every_building_has_a_photo_and_the_pier_keeps_its_icon() -> void:
	var data := GameData.get_default()
	for def: BuildingDef in data.buildings:
		if def.kind == BuildingDef.Kind.MODULE or def.is_pier():
			continue
		if def.kind == BuildingDef.Kind.RESIDENCE:
			for tier: TierDef in data.tiers:
				assert_object(Icons.photo(def.id, tier.id)).override_failure_message("casa %s" % tier.id).is_not_null()
		else:
			var photo := Icons.photo(def.id)
			assert_object(photo).override_failure_message(str(def.id)).is_not_null()
			assert_vector(photo.get_size()).is_equal(Vector2(320, 240))
	for def: BuildingDef in data.buildings:
		if def.is_pier():
			assert_object(Icons.photo(def.id)).is_null()


func test_the_grade_warms_and_darkens_the_corners() -> void:
	var white := Color(1.0, 1.0, 1.0, 0.5)
	var middle := PhotoGrade.graded(white, 0.0)
	var corner := PhotoGrade.graded(white, 1.0)
	assert_float(corner.r).is_less(middle.r)
	assert_float(middle.r).is_greater(middle.b)
	assert_float(middle.a).is_equal(0.5)
	var frame := Image.create_empty(1920, 1080, false, Image.FORMAT_RGBA8)
	var crop := PhotoGrade.crop_4_3(frame, 0.86)
	assert_float(float(crop.get_width()) / crop.get_height()).is_equal_approx(4.0 / 3.0, 0.01)
	assert_int(crop.get_height()).is_equal(929)


func test_the_paintings_are_credited_and_the_portraits_are_their_size() -> void:
	var credits := FileAccess.get_file_as_string("res://CREDITS.md")
	for name: String in PORTRAITS:
		var portrait := Icons.portrait(name)
		assert_object(portrait).override_failure_message(name).is_not_null()
		assert_vector(portrait.get_size()).is_equal(Vector2(256, 320))
		assert_str(credits).contains("portrait_%s.png" % name)
	for file_name: String in DirAccess.get_files_at("res://assets/source/portraits"):
		if file_name.ends_with(".jpg"):
			assert_str(credits).override_failure_message(file_name).contains(file_name.get_basename().trim_prefix("aic_"))


func test_the_build_cards_and_the_panel_show_the_photo() -> void:
	GameScreen.use_sky3d = false
	GameScreen.flat_world = true
	GameScreen.load_slot_on_start = ""
	var runner := scene_runner(GAME)
	var game: GameScreen = runner.scene()
	GameClock.set_speed(TickClock.PAUSED)
	await runner.simulate_frames(4)
	var sim := game.simulation
	sim.free_build = true
	game.hud.search("bakery" if TranslationServer.get_locale().begins_with("en") else "padaria")
	var card := game.hud.find_child("Item_bakery", true, false) as Button
	assert_object(card).is_not_null()
	assert_object(card.icon).is_equal(Icons.photo(&"bakery"))
	assert_float(card.custom_minimum_size.y).is_equal(float(Hud.PHOTO_CARD_HEIGHT))
	game.hud.search("")
	var bakery := sim.execute(PlaceBuildingCommand.new(0, &"bakery", Vector2i(30, 30), 0)).placed[0]
	game.tool.select(bakery)
	var photo := game.hud.selection_panel.find_child("Photo", true, false) as TextureRect
	assert_bool(photo.visible).is_true()
	assert_object(photo.texture).is_equal(Icons.photo(&"bakery"))
	var house := sim.execute(PlaceBuildingCommand.new(0, &"house", Vector2i(40, 30), 0)).placed[0]
	sim.world.building(house).tier = &"workers"
	game.tool.select(house)
	assert_object(photo.texture).is_equal(Icons.photo(&"house", &"workers"))
