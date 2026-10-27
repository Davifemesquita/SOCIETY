extends GdUnitTestSuite
## Rocha nos rochedos e nas falésias (Fase 56): a malha gerada (RockModel) e onde a RockView põe as rochas — um bloco e
## um pilar em cada rochedo solto no mar, rochas encaixadas na face da falésia com o topo abaixo da borda, nada na
## encosta suave nem onde caberia obra.

const SIDE := 40
const SPACING := 2.0
const SEA := -8.0
const PLATEAU := 4.0
const STACK_AT := Vector2i(20, 31)


## Mar fundo, um planalto de falésia reta (x 5..34, y 5..20) e um rochedo em cone no mar.
func _region() -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			var h := SEA
			if x >= 5 and x <= 34 and y >= 5 and y <= 20:
				h = PLATEAU
			var d := Vector2(x, y).distance_to(Vector2(STACK_AT))
			if d < 3.5:
				h = maxf(h, 5.0 - d * 1.2)
			heights[y * SIDE + x] = h
	return heights


func _of_kind(entries: Array, kind: int) -> Array:
	return entries.filter(func(entry: Array) -> bool: return entry[2] == kind)


func test_the_rock_mesh_is_faceted_outward_and_normalized() -> void:
	var first := RockModel.mesh(0)
	var arrays := first.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_int(vertices.size()).is_greater(300)
	var box := first.get_aabb()
	assert_float(box.position.y).is_equal_approx(RockModel.BOTTOM, 0.001)
	assert_float(box.end.y).is_equal_approx(1.0, 0.001)
	assert_float(maxf(maxf(-box.position.x, box.end.x), maxf(-box.position.z, box.end.z))).is_equal_approx(1.0, 0.001)
	var center := Vector3.ZERO
	for v: Vector3 in vertices:
		center += v
	center /= vertices.size()
	var outward := 0
	for t: int in range(0, vertices.size(), 3):
		var a := vertices[t]
		var b := vertices[t + 1]
		var c := vertices[t + 2]
		# a mesma normal nos três (face chapada) e frente no sentido horário do Godot
		assert_bool(normals[t] == normals[t + 1] and normals[t] == normals[t + 2]).is_true()
		assert_float((b - a).cross(c - a).dot(normals[t])).is_less(0.0)
		if normals[t].dot((a + b + c) / 3.0 - center) > 0.0:
			outward += 1
	assert_int(outward).is_equal(vertices.size() / 3)
	# as variantes são formas diferentes, e a mesma variante sai sempre igual
	assert_bool(RockModel.mesh(1).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != vertices).is_true()
	assert_object(RockModel.mesh(RockModel.VARIANTS)).is_same(first)


func test_a_sea_stack_gets_a_block_and_a_taller_pillar() -> void:
	var entries := RockView.places(_region(), SIDE, Vector2.ZERO, SPACING, null, 2.0, 7)
	var stacks := _of_kind(entries, RockView.Kind.STACK)
	# bloco, pilar e de 2 a 4 pedras em volta; o planalto (bem maior) não é rochedo
	assert_int(stacks.size()).is_between(4, 6)
	var block: Transform3D = stacks[0][1]
	var pillar: Transform3D = stacks[1][1]
	assert_float(Vector2(block.origin.x, block.origin.z).distance_to(Vector2(STACK_AT) * SPACING)).is_less(1.0)
	var block_top := block.origin.y + block.basis.y.length()
	var pillar_top := pillar.origin.y + pillar.basis.y.length()
	assert_float(block_top).is_equal_approx(5.0 + RockView.STACK_TOP_M, 0.01)
	assert_float(pillar_top).is_greater(block_top)
	# o bloco cobre o monte (que vai até 3,5 células do meio): raio de pelo menos 3 células
	assert_float(block.basis.x.length()).is_greater(3.0 * SPACING)


func test_a_hill_on_a_low_plain_is_not_a_stack() -> void:
	# planície baixa (1,2 m, abaixo de STACK_MIN_M) com um morro no meio e mar só na borda
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			var inland := x >= 4 and x <= 35 and y >= 4 and y <= 35
			heights[y * SIDE + x] = maxf(1.2, 6.0 - Vector2(x, y).distance_to(Vector2(20, 20)) * 1.2) if inland else SEA
	assert_array(_of_kind(RockView.places(heights, SIDE, Vector2.ZERO, SPACING, null, 2.0, 7), RockView.Kind.STACK)).is_empty()


func test_cliff_rocks_sit_on_the_face_below_the_edge() -> void:
	var heights := _region()
	var cliffs := _of_kind(RockView.places(heights, SIDE, Vector2.ZERO, SPACING, null, 2.0, 7), RockView.Kind.CLIFF)
	assert_int(cliffs.size()).is_greater(8)
	for entry: Array in cliffs:
		var place: Transform3D = entry[1]
		var cell := Vector2(place.origin.x, place.origin.z) / SPACING
		var near_plateau := cell.x > 3.0 and cell.x < 36.0 and cell.y > 3.0 and cell.y < 22.0
		if not near_plateau:
			continue
		# perto da borda do planalto (não no meio dele) e com o topo abaixo dela (o topo da malha é y = 1, inclinado
		# só desce)
		var inside := cell.x > 6.5 and cell.x < 33.5 and cell.y > 6.5 and cell.y < 19.5
		assert_bool(inside).override_failure_message("rocha no meio do planalto em %s" % cell).is_false()
		var top := place.origin.y + place.basis.y.length()
		assert_float(top).is_less_equal(PLATEAU - RockView.CLIFF_BELOW_TOP_M + 0.001)


func test_a_gentle_beach_gets_no_rocks() -> void:
	var heights := PackedFloat32Array()
	heights.resize(SIDE * SIDE)
	for y: int in SIDE:
		for x: int in SIDE:
			heights[y * SIDE + x] = 20.0 - x * 0.8
	assert_array(RockView.places(heights, SIDE, Vector2.ZERO, SPACING, null, 2.0, 7)).is_empty()


func test_the_archipelago_gets_rocks_only_where_nothing_can_be_built() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([160])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var world := ArchipelagoGenerator.new_world(1840, config, GameData.get_default())
	var terrain: TerrainView = auto_free(TerrainView.new())
	add_child(terrain)
	terrain.setup(world, config, GameData.get_default())
	var rocks: RockView = auto_free(RockView.new())
	add_child(rocks)
	rocks.setup(terrain, world, config)
	assert_int(rocks.rock_count(RockView.Kind.STACK)).is_greater(0)
	assert_int(rocks.rock_count(RockView.Kind.CLIFF)).is_greater(0)
	assert_int(rocks.get_child_count()).is_greater(0)
	var grid := world.island(0)
	var region := terrain.region_heights(0)
	var heights: PackedFloat32Array = region["heights"]
	var side: int = region["side"]
	var origin: Vector2 = region["origin"]
	for entry: Array in _of_kind(RockView.places(heights, side, origin, config.cell_size_m, grid, config.max_road_relief_m, 0),
			RockView.Kind.CLIFF):
		var place: Transform3D = entry[1]
		var cell := grid.world_to_cell(place.origin)
		if not grid.in_bounds(cell):
			continue
		var index := grid.index(cell)
		var buildable := grid.ground[index] == IslandGrid.Ground.LAND \
				and grid.area_relief(Rect2i(cell, Vector2i.ONE)) <= config.max_road_relief_m
		assert_bool(buildable).override_failure_message("rocha em célula de obra %s" % cell).is_false()
	remove_child(rocks)
	remove_child(terrain)
