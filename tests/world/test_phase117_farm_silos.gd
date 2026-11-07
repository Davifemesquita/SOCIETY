extends GdUnitTestSuite
## Silos das fazendas (Fase 117): cada fazenda ganha um silo ou uma caixa d'água numa célula livre encostada nela, do lado
## de trás; o recheio deixa a célula limpa; casa e estrada tomam o lugar; as faces das peças viram para fora.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _farm(def_id: StringName = &"wheat_farm") -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_one_silo_beside_each_farm() -> void:
	var record := _farm()
	var grid := _sim.world.island(0)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var cells := FarmSiloView.cells(_sim.world, _sim.data, 0)
	assert_int(cells.size()).is_equal(1)
	var cell: Vector2i = cells.keys()[0]
	assert_int(cells[cell]).is_equal(record.id)
	assert_bool(area.grow(1).has_point(cell) and not area.has_point(cell)).is_true()
	assert_int(grid.building_at(cell)).is_equal(0)
	# do lado de trás: não fica na frente da entrada
	var front := Vector2(Footprint.front_direction(record.rotation))
	var offset := Vector2(cell) + Vector2(0.5, 0.5) - (Vector2(area.position) + Vector2(area.size) * 0.5)
	assert_float(offset.dot(front)).is_less_equal(0.5)


func test_the_scatter_leaves_the_silo_alone_and_a_road_moves_it() -> void:
	_farm()
	var cells := FarmSiloView.cells(_sim.world, _sim.data, 0)
	var cell: Vector2i = cells.keys()[0]
	var clear: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	assert_bool(clear.has(cell)).is_true()
	_sim.world.island(0).set_road(cell, IslandGrid.Road.DIRT)
	assert_bool(FarmSiloView.cells(_sim.world, _sim.data, 0).has(cell)).is_false()


func test_the_view_draws_silos_and_tanks() -> void:
	_farm()
	_farm(&"potato_farm")
	var view: FarmSiloView = auto_free(FarmSiloView.new())
	add_child(view)
	view.setup(_sim)
	var total := view.count(FarmSiloView.Kind.SILO) + view.count(FarmSiloView.Kind.TANK)
	assert_int(total).is_equal(FarmSiloView.cells(_sim.world, _sim.data, 0).size())
	assert_int(total).is_greater(0)


func test_the_faces_point_outward() -> void:
	# cada vértice das aduelas do silo (no raio do corpo) tem a normal (pela ordem dos vértices) para fora
	var mesh := FarmSiloView.silo_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var checked := 0
	for i: int in vertices.size():
		var at := vertices[i]
		var radial := Vector3(at.x, 0.0, at.z)
		if absf(radial.length() - FarmSiloView.SILO_RADIUS_M) > 0.005:
			continue
		assert_float(normals[i].dot(radial.normalized())).is_greater(0.0)
		checked += 1
	assert_int(checked).is_greater(0)
