extends GdUnitTestSuite
## Fase 375: com o MegaKit, a cerca do quintal dos camponeses é a cerca de tábuas do pacote, empacotada no referencial da peça
## "fence" do Kenney (que ela substitui pelo nome).


func after_test() -> void:
	BuildingKit.reset_megakit()


func test_the_fence_is_packed_in_the_kenney_frame() -> void:
	var path := BuildingKit.MEGAKIT_DIR + BuildingKit.FENCE + ".res"
	assert_bool(ResourceLoader.exists(path)).is_true()
	var box := (load(path) as Mesh).get_aabb()
	# como a do Kenney: a face em x = 0,5, de z −0,5 a 0,5, 0,38 de altura
	assert_float(box.position.x).is_greater(0.35)
	assert_float(box.end.x).is_less(0.56)
	assert_float(box.position.z).is_equal_approx(-0.5, 0.02)
	assert_float(box.end.z).is_equal_approx(0.5, 0.02)
	assert_float(box.position.y).is_equal_approx(0.0, 0.02)
	assert_float(box.end.y).is_equal_approx(0.38, 0.02)


func test_the_piece_follows_the_kit() -> void:
	BuildingKit.use_megakit(true)
	var parts: Array = BuildingKit._parts_of(BuildingKit.FENCE)
	assert_int(parts.size()).is_equal(1)
	var mesh: Mesh = parts[0][0]
	assert_str(mesh.resource_path).is_equal(BuildingKit.MEGAKIT_DIR + BuildingKit.FENCE + ".res")
	BuildingKit.use_megakit(false)
	for part: Array in BuildingKit._parts_of(BuildingKit.FENCE):
		var kenney: Mesh = part[0]
		assert_bool(kenney.resource_path.begins_with(BuildingKit.MEGAKIT_DIR)).is_false()
