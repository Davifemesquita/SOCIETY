extends GdUnitTestSuite
## Fase 368: com o MegaKit, as janelas e as portas dos prédios de madeira saem das peças do pacote (como as de reboco), não
## das tábuas do Kenney.


func after_test() -> void:
	BuildingKit.reset_megakit()


func _source(piece: String) -> String:
	var parts: Array = BuildingKit._parts_of(piece)
	if parts.is_empty():
		return ""
	var part: Array = parts[0]
	var mesh: Mesh = part[0]
	return mesh.resource_path


func test_every_wood_piece_comes_from_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	var wood: Dictionary = BuildingKit.PIECES[BuildingKit.Walls.WOOD]
	var pieces: Array[String] = [wood[&"plain"], wood[&"door"], wood[&"arch"]]
	for window: String in wood[&"windows"]:
		pieces.append(window)
	for piece: String in pieces:
		assert_str(_source(piece)).override_failure_message(piece).contains("/megakit/")


func test_the_wood_window_is_the_plaster_window_of_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	assert_str(_source("wall-wood-window-glass")).ends_with("megakit/wall-window-glass.res")
	assert_str(_source("wall-wood-door")).ends_with("megakit/wall-door.res")


func test_the_kenney_keeps_its_wood_pieces() -> void:
	BuildingKit.use_megakit(false)
	assert_str(_source("wall-wood-window-glass")).not_contains("/megakit/")
