extends GdUnitTestSuite
## Medas de feno (Fase 166): cada fazenda de gado e de trigo ganha as medas numa célula livre encostada nela, do lado e fora do
## silo; casas não; o recheio e as bombas deixam a célula limpa; a meda é redonda, de pé no chão e com a vara em cima.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _place(def_id: StringName) -> BuildingRecord:
	var grid := _sim.world.island(0)
	_sim.ignore_terrain = false
	var found: Array = SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	_sim.ignore_terrain = true
	var origin: Vector2i = found[0]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, 0))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_farms_get_their_haystacks_beside_them_apart_from_the_silo() -> void:
	var farm := _place(&"sheep_farm")
	var found := HaystackView.cells(_sim.world, _sim.data, 0)
	assert_bool(found.values().has(farm.id)).is_true()
	var cell: Vector2i = found.keys()[found.values().find(farm.id)]
	var area := Footprint.rect(farm.origin, _sim.def_of(farm).size, farm.rotation)
	assert_bool(area.has_point(cell)).is_false()
	assert_bool(area.grow(1).has_point(cell)).is_true()
	var grid := _sim.world.island(0)
	assert_int(grid.building_at(cell)).is_equal(0)
	assert_bool(grid.has_road(cell)).is_false()
	assert_bool(FarmSiloView.cells(_sim.world, _sim.data, 0).has(cell)).is_false()


func test_houses_get_none_and_the_scatter_and_pumps_keep_off() -> void:
	var house := _place(&"house")
	_place(&"wheat_farm")
	var found := HaystackView.cells(_sim.world, _sim.data, 0)
	assert_bool(found.values().has(house.id)).is_false()
	var context := ScatterView.island_context(_sim.world, _sim.data, 0)
	var doors: Dictionary[Vector2i, bool] = context[0]
	var pumps := WaterPumpView.cells(_sim.world, _sim.data, 0)
	for cell: Vector2i in found:
		assert_bool(doors.has(cell)).is_true()
		assert_bool(pumps.has(cell)).is_false()


func test_the_stack_stands_round_with_its_pole() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	HaystackView.stack_mesh(tool, Transform3D.IDENTITY, 1.0)
	tool.generate_normals()
	var mesh := tool.commit()
	var box := mesh.get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_greater(HaystackView.STACK_BODY_M + HaystackView.STACK_DOME_M)
	assert_float(box.size.x).is_equal_approx(box.size.z, 0.2)
	# as faces para fora: a normal do meio do corpo aponta para longe do eixo
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var outward := 0
	var total := 0
	for k: int in vertices.size():
		var v := vertices[k]
		if v.y > 0.3 and v.y < 0.9:
			total += 1
			if normals[k].dot(Vector3(v.x, 0.0, v.z)) > 0.0:
				outward += 1
	assert_int(outward).is_greater(total * 9 / 10)
