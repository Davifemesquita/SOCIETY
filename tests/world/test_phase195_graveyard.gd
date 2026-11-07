extends GdUnitTestSuite
## Cemitério da igreja (Fase 195): as covas ficam atrás da igreja, além do largo, nas células livres e quase planas; as
## lápides olham para a igreja; o muro fecha as bordas e abre o portão do lado dela; o recheio fica fora; outros prédios e a
## ilha plana não têm.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _place(def_id: StringName) -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_graves_lie_behind_the_church_past_the_forecourt() -> void:
	var record := _place(&"church")
	var grid := _sim.world.island(0)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var back := -Footprint.front_direction(record.rotation)
	var yard := GraveyardView.cells(_sim.world, _sim.data, 0)
	var court := ForecourtView.cells(_sim.world, _sim.data, 0)
	assert_int(yard.size()).is_greater(0)
	var center := Vector2(area.position) + Vector2(area.size) * 0.5
	for cell: Vector2i in yard:
		assert_bool(yard[cell] == back).is_true()
		# fora do prédio e do anel do largo, do lado de trás
		assert_bool(area.grow(1).has_point(cell)).is_false()
		assert_bool(court.has(cell)).is_false()
		assert_float((Vector2(cell) + Vector2(0.5, 0.5) - center).dot(Vector2(back))).is_greater(0.0)
		var index := grid.index(cell)
		assert_int(grid.occupancy[index]).is_equal(0)
		assert_int(grid.roads[index]).is_equal(IslandGrid.Road.NONE)
		assert_int(grid.trees[index]).is_equal(0)
		var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
		assert_float(corners.y - corners.x).is_less_equal(GraveyardView.MAX_RELIEF_M)


func test_the_headstones_face_the_church_and_sit_on_the_ground() -> void:
	var record := _place(&"church")
	var grid := _sim.world.island(0)
	var back := -Footprint.front_direction(record.rotation)
	var kinds: Dictionary[int, bool] = {}
	var yard := GraveyardView.cells(_sim.world, _sim.data, 0)
	for cell: Vector2i in yard:
		var graves := GraveyardView.graves_of(grid, 0, cell, yard[cell])
		assert_int(graves.size()).is_equal(GraveyardView.GRAVES_PER_CELL)
		for grave: Array in graves:
			var kind: int = grave[0]
			kinds[kind] = true
			var place: Transform3D = grave[1]
			# a frente da malha (−Z) aponta para a igreja, tombada no máximo MAX_TILT_RAD e o desvio
			var facing := -place.basis.z.normalized()
			assert_float(facing.dot(-Vector3(back.x, 0.0, back.y))).is_greater(cos(GraveyardView.MAX_TILT_RAD + 0.05))
			assert_float(place.origin.y).is_equal_approx(grid.height_at(place.origin.x, place.origin.z), 0.001)
			assert_bool(grid.world_to_cell(place.origin) == cell).is_true()
	# com três fileiras de covas sai mais de um tipo de pedra
	assert_int(kinds.size()).is_greater(1)


func test_the_wall_closes_the_yard_and_opens_the_gate() -> void:
	_place(&"church")
	var grid := _sim.world.island(0)
	var plan := GraveyardView.layout(_sim.world, _sim.data, 0)
	var yard: Dictionary[Vector2i, Vector2i] = plan[0]
	var gates: Dictionary[Vector2i, bool] = plan[1]
	var open_sides := 0
	for cell: Vector2i in yard:
		for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not yard.has(cell + side):
				open_sides += 1
	var walls := GraveyardView.walls(grid, yard, gates)
	# um pedaço por lado de borda, menos o do portão, que vira dois pilares
	assert_int(walls.size()).is_equal(open_sides - gates.size() + gates.size() * 2)
	for gate: Vector2i in gates:
		assert_bool(yard.has(gate)).is_true()
		assert_bool(yard.has(gate - yard[gate])).is_false()
	for wall: Transform3D in walls:
		# cada pedaço fica dentro de uma célula do cemitério
		assert_bool(yard.has(grid.world_to_cell(wall.origin))).is_true()


func test_the_scatter_stays_off_the_graveyard() -> void:
	_place(&"church")
	var yard := GraveyardView.cells(_sim.world, _sim.data, 0)
	var grid := _sim.world.island(0)
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, 0, Vector2i(cx, cy))
			for kind: int in items.keys():
				var list: Array = items[kind]
				for item: Array in list:
					var place: Transform3D = item[0]
					assert_bool(yard.has(grid.world_to_cell(place.origin))).is_false()


func test_other_buildings_and_the_flat_island_have_none() -> void:
	_place(&"theater")
	assert_int(GraveyardView.cells(_sim.world, _sim.data, 0).size()).is_equal(0)
	var sim := SimFixture.simulation(Vector2i(40, 30))
	sim.free_build = true
	SimFixture.place(sim, &"church", Vector2i(10, 10), 0)
	assert_int(GraveyardView.cells(sim.world, sim.data, 0).size()).is_equal(0)
