extends GdUnitTestSuite
## Muro dos quintais (Fase 304): atrás das casas de camponeses, operários e artesãos das ilhas temperadas, com a fileira de trás
## livre, o quintal fecha em três divisas (o fundo no fim da fileira e os dois lados); a divisa entre duas casas vizinhas sai uma
## vez só; nada com a fileira de trás ocupada, nas outras classes nem nas tropicais.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70])
	_config.tropical_island_sizes_cells = PackedInt32Array([50])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _clear(island_id: int, area: Rect2i) -> void:
	var grid := _sim.world.island(island_id)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var index := grid.index(Vector2i(x, y))
			grid.ground[index] = IslandGrid.Ground.LAND
			grid.trees[index] = 0


func _house(island_id: int, origin: Vector2i, tier: StringName = &"workers") -> BuildingRecord:
	var result := _sim.execute(PlaceBuildingCommand.new(island_id, &"house", origin, 0))
	assert_bool(result.ok()).is_true()
	var record := _sim.world.building(result.placed[0])
	record.tier = tier
	return record


func _base() -> Vector2i:
	var grid := _sim.world.island(0)
	var base := grid.size / 2 - Vector2i(6, 6)
	_clear(0, Rect2i(base, Vector2i(14, 14)))
	return base


func test_a_free_back_row_closes_the_yard() -> void:
	var base := _base()
	var record := _house(0, base)
	var grid := _sim.world.island(0)
	var lines := YardWallView.yard_lines(grid, _sim.data, record)
	assert_int(lines.size()).is_equal(3)
	# o fundo fica a uma célula atrás da parede (menos a folga), do lado de trás da casa
	var def := _sim.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var back := Vector2(-Footprint.front_direction(record.rotation))
	var far: Array = lines[0]
	var far_from: Vector2 = far[0]
	var far_to: Vector2 = far[1]
	var middle := (far_from + far_to) * 0.5
	var lot_middle := Vector2(grid.cell_world(area.position).x, grid.cell_world(area.position).z) \
			+ (Vector2(area.size) - Vector2.ONE) * grid.cell_size * 0.5
	var behind := (middle - lot_middle).dot(back)
	var depth := float(area.size.y if posmod(record.rotation, 2) == 0 else area.size.x) * grid.cell_size
	assert_float(behind).is_equal_approx(depth * 0.5 + grid.cell_size - YardWallView.INSET_M, 0.05)
	assert_float(far_from.distance_to(far_to)).is_equal_approx(
			float(area.size.x if posmod(record.rotation, 2) == 0 else area.size.y) * grid.cell_size, 0.05)


func test_a_busy_back_row_leaves_the_yard_open() -> void:
	var base := _base()
	var record := _house(0, base)
	var back := -Footprint.front_direction(record.rotation)
	var def := _sim.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	# uma estrada numa célula da fileira de trás
	var cell := Vector2i(-1, -1)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if not area.has_point(Vector2i(x, y) + back):
				cell = Vector2i(x, y) + back
	assert_bool(_sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(cell, cell), false)).ok()).is_true()
	assert_int(YardWallView.yard_lines(_sim.world.island(0), _sim.data, record).size()).is_equal(0)


func test_neighbours_share_the_side_and_other_tiers_have_none() -> void:
	var base := _base()
	var left := _house(0, base)
	var width := Footprint.rect(left.origin, _sim.def_of(left).size, left.rotation).size.x
	_house(0, base + Vector2i(width, 0))
	var segments := YardWallView.segments(_sim.world, _sim.data, 0)
	# duas casas lado a lado: dois fundos e três lados (o do meio uma vez só)
	assert_int(segments.size()).is_equal(5)
	left.tier = &"engineers"
	assert_int(YardWallView.segments(_sim.world, _sim.data, 0).size()).is_equal(3)


func test_tropical_islands_have_no_yard_walls() -> void:
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			var grid := _sim.world.island(island_id)
			var base := grid.size / 2 - Vector2i(3, 3)
			_clear(island_id, Rect2i(base, Vector2i(8, 8)))
			_house(island_id, base)
			assert_int(YardWallView.segments(_sim.world, _sim.data, island_id).size()).is_equal(0)
