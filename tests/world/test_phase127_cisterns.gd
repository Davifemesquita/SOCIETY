extends GdUnitTestSuite
## Cisternas no cais (Fase 127): o entreposto ganha duas cisternas no cais de pedra, uma de cada lado, fora da largura
## dele e no alto da plataforma; a vista as desenha; a cisterna tem as faces para fora.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _post() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_cisterns_stand_on_the_stone_quay_beside_the_post() -> void:
	var record := _post()
	var places := HarborView.cistern_places(_sim, record)
	var segments := HarborView.stone_quay(_sim, record)
	assert_int(places.size()).is_less_equal(2)
	if segments.is_empty():
		assert_int(places.size()).is_equal(0)
		return
	var plan := HarborView.walkway(_sim, record)
	var half: Vector2 = plan["half"]
	var start: Vector3 = plan["start"]
	var direction: Vector3 = plan["direction"]
	var across := Vector3(-direction.z, 0.0, direction.x)
	var width := (half.y if direction.x != 0.0 else half.x) * 2.0
	var sides: Array[float] = []
	for place: Transform3D in places:
		var t := (place.origin - start).dot(across)
		assert_float(absf(t)).is_greater_equal(width * 0.5 + HarborView.CISTERN_CLEAR_M)
		sides.append(signf(t))
		# no alto do cais de pedra
		var top: float = plan["deck"] - HarborView.STONE_QUAY_BELOW_DECK_M
		assert_float(place.origin.y).is_equal_approx(top, 0.01)
	if sides.size() == 2:
		assert_float(sides[0]).is_not_equal(sides[1])


func test_the_view_draws_them() -> void:
	var record := _post()
	var view: HarborView = auto_free(HarborView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.cistern_count()).is_equal(HarborView.cistern_places(_sim, record).size())


func test_the_staves_face_outward() -> void:
	var mesh := FarmSiloView.cistern_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var checked := 0
	for i: int in vertices.size():
		var radial := Vector3(vertices[i].x, 0.0, vertices[i].z)
		if absf(radial.length() - FarmSiloView.CISTERN_RADIUS_M) > 0.005:
			continue
		assert_float(normals[i].dot(radial.normalized())).is_greater(0.0)
		checked += 1
	assert_int(checked).is_greater(0)
