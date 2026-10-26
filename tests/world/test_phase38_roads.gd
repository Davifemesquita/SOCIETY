extends GdUnitTestSuite
## Estradas no chão (Fase 38): a máscara das estradas mede a distância até a linha do meio da terra — reta, diagonal a
## 45° sem escada, cruzamento contínuo e o L de canto arredondado —, marca o calçamento, o chão batido das portas e as
## poças, é determinística, refaz só o retângulo do que mudou e não mexe na simulação; a RoadView deixa de pôr ladrilho
## na terra da ilha com relevo.

const PER_CELL := 4
const MAX_M := 1.6
const PIXEL_M := 0.5

var _world: WorldState


func before_test() -> void:
	_world = _flat_terrain_world(Vector2i(40, 40))


## Ilha de relevo plano a 1,2 m (não é a ilha plana antiga: tem terreno), toda de terra firme.
func _flat_terrain_world(size: Vector2i) -> WorldState:
	var grid := IslandGrid.new(size)
	grid.init_terrain()
	for i: int in grid.corner_heights.size():
		grid.corner_heights[i] = 1.2
	grid.invalidate_heights()
	grid.origin_m = Vector2(100.0, 50.0)
	var world := WorldState.new()
	world.islands.append(grid)
	var economy := IslandEconomy.new()
	economy.profile_id = &"main_island"
	world.economies.append(economy)
	return world


func _mask() -> RoadMask:
	return RoadMask.new(_world, GameData.get_default(), 0, PER_CELL, MAX_M)


func _road(cells: Array[Vector2i], road: IslandGrid.Road = IslandGrid.Road.DIRT) -> void:
	for cell: Vector2i in cells:
		_world.island(0).set_road(cell, road)


func _row(y: int, from_x: int, to_x: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x: int in range(from_x, to_x + 1):
		cells.append(Vector2i(x, y))
	return cells


## Centro do pixel que contém o ponto (m da grade).
func _pixel(point: Vector2) -> Vector2:
	return ((point / PIXEL_M).floor() + Vector2(0.5, 0.5)) * PIXEL_M


func test_a_straight_road_measures_the_distance_to_its_middle_line() -> void:
	_road(_row(10, 2, 9))
	var mask := _mask()
	# a linha do meio passa em z = 21 m (centro da linha 10)
	for x: float in [7.0, 10.0, 13.0, 16.0]:
		for z: float in [18.6, 19.6, 20.1, 20.6, 21.1, 21.6, 22.6, 23.4]:
			var p := _pixel(Vector2(x, z))
			var expected := minf(absf(p.y - 21.0), MAX_M)
			assert_float(mask.distance_at(p)).override_failure_message("em %s" % p).is_equal_approx(expected, 0.015)
	# longe da estrada, a distância satura
	assert_float(mask.distance_at(_pixel(Vector2(40.0, 40.0)))).is_equal_approx(MAX_M, 0.001)


func test_a_diagonal_is_one_segment_at_45_degrees_without_steps() -> void:
	_road(RoadPath.diagonal_path(Vector2i(10, 10), Vector2i(14, 14)))
	var mask := _mask()
	# do centro de (10, 10) ao de (14, 14): a reta x = z de 21 a 29 m; a distância é a da reta, a mesma ao longo dela
	var checked := 0
	for py: int in range(44, 58):
		for px: int in range(44, 58):
			var p := (Vector2(px, py) + Vector2(0.5, 0.5)) * PIXEL_M
			var expected := absf(p.x - p.y) / sqrt(2.0)
			if expected > 1.4:
				continue
			assert_float(mask.distance_at(p)).override_failure_message("em %s" % p).is_equal_approx(expected, 0.015)
			checked += 1
	assert_int(checked).is_greater(50)


func test_a_crossing_is_one_continuous_patch() -> void:
	_road(_row(5, 2, 12))
	var column: Array[Vector2i] = []
	for y: int in range(0, 11):
		column.append(Vector2i(7, y))
	_road(column)
	var mask := _mask()
	# toda a célula do cruzamento fica dentro da meia largura (0,8 m): os quatro cantos de dentro arredondados
	for py: int in range(20, 24):
		for px: int in range(28, 32):
			var p := (Vector2(px, py) + Vector2(0.5, 0.5)) * PIXEL_M
			assert_float(mask.distance_at(p)).override_failure_message("em %s" % p).is_less(0.8)


func test_an_l_corner_is_rounded_inside_and_out() -> void:
	_road(_row(30, 20, 25))
	_road([Vector2i(25, 31), Vector2i(25, 32), Vector2i(25, 33)])
	var mask := _mask()
	# a célula do canto (25, 30), centro em (51, 61) m, liga para −x e +z
	var inner := Vector2(51.0 - 0.75, 61.0 + 0.75)
	# sem o arredondamento seria 0,75 (até cada um dos dois segmentos); com ele, até a corda entre os meios dos lados
	assert_float(mask.distance_at(inner)).is_equal_approx(0.5 / sqrt(2.0), 0.015)
	# o canto de fora é um arco em volta do centro
	var outer := Vector2(51.0 + 0.75, 61.0 - 0.75)
	assert_float(mask.distance_at(outer)).is_equal_approx(0.75 * sqrt(2.0), 0.015)


func test_paving_goes_to_its_own_channel_and_doors_wear_the_ground() -> void:
	_road(_row(36, 2, 10), IslandGrid.Road.PAVED)
	var data := GameData.get_default()
	var def: BuildingDef = null
	for candidate: BuildingDef in data.buildings:
		if candidate.kind != BuildingDef.Kind.DECORATION:
			def = candidate
			break
	_world.buildings[1] = BuildingRecord.new(1, def.id, 0, Vector2i(28, 10), 0)
	var mask := _mask()
	var paved := _pixel(Vector2(11.2, 73.2))
	assert_float(mask.channel_at(paved, 1)).is_equal(1.0)
	# a rua só de paralelepípedo não entra na distância da terra (o ladrilho fica)
	assert_float(mask.distance_at(paved)).is_equal_approx(MAX_M, 0.001)
	# a porta fica na divisa da frente (rotação 0: −z) e o chão batido em volta dela
	var door: Vector2 = RoadMask.doors(_world, data, 0)[1]
	assert_float(door.y).is_equal_approx(20.0, 0.001)
	assert_float(mask.channel_at(_pixel(door), 2)).is_greater(0.8)
	assert_float(mask.channel_at(_pixel(door + Vector2(0.0, -4.0)), 2)).is_equal(0.0)


func test_some_dirt_cells_get_a_puddle_on_the_middle_line() -> void:
	_road(_row(20, 0, 39))
	var mask := _mask()
	var puddles := 0
	for x: int in 40:
		var strongest := 0.0
		for px: int in range(x * PER_CELL, x * PER_CELL + PER_CELL):
			strongest = maxf(strongest, mask.channel_at(Vector2(px + 0.5, 81.5) * PIXEL_M, 3))
		if strongest > 0.0:
			puddles += 1
	# a chance é de 12%: em 40 células, entre 1 e 15
	assert_int(puddles).is_between(1, 15)


func test_the_mask_is_deterministic() -> void:
	_road(_row(10, 2, 30))
	_road(RoadPath.diagonal_path(Vector2i(5, 20), Vector2i(15, 30)))
	assert_bool(_mask().image.get_data() == _mask().image.get_data()).is_true()


func test_a_new_road_redraws_only_around_itself() -> void:
	_road(_row(10, 2, 30))
	var mask := _mask()
	assert_int(mask.refresh().size.x).override_failure_message("nada mudou e algo foi redesenhado").is_equal(0)
	var before := mask.image.get_data()
	_road([Vector2i(35, 35)])
	var area := mask.refresh()
	assert_that(area).is_equal(Rect2i(32, 32, 7, 7))
	var after := mask.image.get_data()
	var width := 40 * PER_CELL
	var pixels := Rect2i(area.position * PER_CELL, area.size * PER_CELL)
	for i: int in before.size() / 4:
		if not pixels.has_point(Vector2i(i % width, i / width)):
			if before[i * 4] != after[i * 4]:
				assert_bool(false).override_failure_message("pixel %d mudou fora do retângulo" % i).is_true()
				return
	# a célula solta é um ponto: o pixel do lado do centro dela fica a ~0,35 m
	assert_float(mask.distance_at(Vector2(71.25, 71.25))).is_equal_approx(0.25 * sqrt(2.0), 0.015)


func test_the_road_view_drops_dirt_tiles_where_the_terrain_paints_them() -> void:
	var sim := Simulation.new(GameConfig.new(), GameData.get_default(), _world)
	_road(_row(10, 2, 9))
	_road(_row(20, 2, 9), IslandGrid.Road.PAVED)
	var view: RoadView = auto_free(RoadView.new())
	add_child(view)
	view.setup(sim, sim.config.cell_size_m)
	# a terra não tem ladrilho; o paralelepípedo, desde a Fase 46, é da grade dual; as pedras soltas descem para o chão
	assert_int(view.tile_count()).is_equal(0)
	assert_int(view.dual_corner_count(0)).is_equal(9 * 2)
	assert_int(view.painted_count()).is_equal(8)
	var grid := _world.island(0)
	for spot: Vector3 in RoadView.stone_spots(grid, Vector2i(4, 10), RoadView.Ruts.ALONG_X, false):
		assert_float(spot.y).is_equal_approx(1.2, 0.001)
	# desligada a pintura, a terra volta ao ladrilho
	sim.config.road_paint = false
	view.rebuild()
	assert_int(view.tile_count()).is_equal(8)
	assert_int(view.painted_count()).is_equal(0)
	remove_child(view)


func test_the_terrain_paints_new_roads_without_touching_the_simulation() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var sim := Simulation.new(config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, config, GameData.get_default()))
	sim.free_build = true
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(sim.world, config, sim.data)
	var grid := sim.world.island(0)
	var mask := view.road_mask(0)
	assert_object(mask).is_not_null()
	assert_bool(view.materials()[0].get_shader_parameter(&"has_roads")).is_true()
	# uma estrada onde a simulação aceita
	var target := Vector2i(-1, -1)
	for i: int in grid.ground.size():
		var cell := grid.cell_at(i)
		if PlacementRules.check_road_cell(grid, cell, config) == PlacementRules.OK:
			target = cell
			break
	assert_int(target.x).is_greater_equal(0)
	var one: Array[Vector2i] = [target]
	assert_bool(sim.execute(BuildRoadCommand.new(0, one)).ok()).is_true()
	var state := var_to_str(sim.world.to_dict())
	view.flush_road_masks()
	assert_str(var_to_str(sim.world.to_dict())).is_equal(state)
	var center := (Vector2(target) + Vector2(0.5, 0.5)) * grid.cell_size
	assert_float(mask.distance_at(center)).is_less(0.5)
	remove_child(view)


func test_a_big_road_network_masks_in_reasonable_time() -> void:
	_world = _flat_terrain_world(Vector2i(160, 160))
	var cells := 0
	for y: int in 160:
		for x: int in 160:
			if x % 8 == 0 or y % 8 == 0:
				_world.island(0).set_road(Vector2i(x, y), IslandGrid.Road.DIRT)
				cells += 1
	var started := Time.get_ticks_msec()
	var mask := _mask()
	var full := Time.get_ticks_msec() - started
	started = Time.get_ticks_msec()
	_world.island(0).set_road(Vector2i(84, 84), IslandGrid.Road.DIRT)
	mask.refresh()
	var one := Time.get_ticks_msec() - started
	print("máscara das estradas: %d células de estrada em %d ms; uma estrada nova em %d ms" % [cells, full, one])
	assert_int(one).is_less(50)
