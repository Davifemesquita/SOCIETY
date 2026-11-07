extends GdUnitTestSuite
## Fase 360 (ensaio): as paredes do MegaKit no lugar das do Kenney, desligadas por padrão.


func after_test() -> void:
	BuildingKit.use_megakit(false)


func test_it_is_off_by_default() -> void:
	if OS.get_environment("SOCIETY_MEGAKIT") == "1":
		return
	BuildingKit._megakit = -1
	assert_bool(BuildingKit.megakit_walls()).is_false()


func test_every_wall_piece_has_a_converted_mesh_inside_the_kenney_box() -> void:
	for piece: String in ["wall", "wall-window-shutters", "wall-window-glass", "wall-window-small", "wall-door",
			"wall-doorway-round", "wall-wood"]:
		var path := BuildingKit.MEGAKIT_DIR + piece + ".res"
		assert_bool(ResourceLoader.exists(path)).override_failure_message(piece).is_true()
		var mesh := load(path) as Mesh
		var box := mesh.get_aabb()
		# a face de fora em x = 0,5, nada passa dela; a largura e o andar na caixa unitária
		assert_float(box.end.x).override_failure_message(piece).is_less_equal(0.501)
		# (o batente da porta passa ~3,6 cm da largura, como o do Kenney passa da dele)
		assert_float(box.position.z).override_failure_message(piece).is_greater_equal(-0.54)
		assert_float(box.end.z).override_failure_message(piece).is_less_equal(0.54)
		assert_float(box.end.y).override_failure_message(piece).is_less_equal(1.01)


func test_the_vertices_carry_the_layer_in_uv2() -> void:
	var arrays := (load(BuildingKit.MEGAKIT_DIR + "wall-window-shutters.res") as Mesh).surface_get_arrays(0)
	var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var layers := {}
	for uv: Vector2 in uv2:
		layers[roundi(uv.x)] = true
	# reboco, madeira e vidro, pelo menos; nenhum vértice sem camada
	assert_bool(layers.has(1) and layers.has(2) and layers.has(6)).is_true()
	assert_bool(layers.has(0)).is_false()


func test_switching_it_on_swaps_the_parts_and_drops_the_generated_glass() -> void:
	BuildingKit.use_megakit(true)
	var parts := BuildingKit._parts_of("wall")
	assert_int(parts.size()).is_equal(1)
	var mesh: Mesh = parts[0][0]
	assert_str(mesh.resource_path).ends_with("megakit/wall.res")
	BuildingKit.use_megakit(false)
	var kenney: Array = BuildingKit._parts_of("wall")[0]
	var kenney_mesh: Mesh = kenney[0]
	assert_bool(kenney_mesh.resource_path.contains("megakit")).is_false()
