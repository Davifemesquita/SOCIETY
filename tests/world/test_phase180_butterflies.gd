extends GdUnitTestSuite
## Borboletas (Fase 180): os grupos ficam em terra livre, acima do chão; nas temperadas só nos canteiros de papoulas, nas
## tropicais no capim aberto; o mesmo mundo dá os mesmos grupos; nada na ilha plana; a borboleta tem as asas abertas com o UV
## do corpo até a ponta.

var _config: GameConfig
var _world: WorldState
var _data: GameData


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_data = GameData.get_default()
	_world = ArchipelagoGenerator.new_world(1840, _config, _data)


func test_groups_hover_over_free_land() -> void:
	var temperate := 0
	var tropical := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var hot := _world.is_tropical(island_id, _data)
		for center: Vector3 in ButterflyView.groups(_world, _data, island_id):
			var cell := grid.world_to_cell(center)
			var index := grid.index(cell)
			assert_int(grid.ground[index]).is_equal(IslandGrid.Ground.LAND)
			assert_int(grid.trees[index]).is_equal(0)
			assert_int(grid.occupancy[index]).is_equal(0)
			assert_int(grid.roads[index]).is_equal(IslandGrid.Road.NONE)
			assert_float(center.y - grid.height_at(center.x, center.z)).is_equal_approx(ButterflyView.GROUP_HEIGHT_M, 0.001)
			if hot:
				tropical += 1
			else:
				# nas temperadas, só sobre as papoulas
				assert_bool(ScatterView.poppy_patch(island_id, cell)).is_true()
				temperate += 1
	assert_int(temperate).is_greater(0)
	assert_int(tropical).is_greater(0)


func test_the_same_world_gives_the_same_groups() -> void:
	for island_id: int in _world.islands.size():
		assert_array(ButterflyView.groups(_world, _data, island_id)).is_equal(ButterflyView.groups(_world, _data, island_id))


func test_none_on_the_flat_island() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 60))
	assert_array(ButterflyView.groups(sim.world, sim.data, SimFixture.ISLAND)).is_empty()


func test_the_butterfly_has_open_wings_from_body_to_tip() -> void:
	var mesh := ButterflyView.butterfly_mesh()
	var box := mesh.get_aabb()
	assert_float(box.size.x).is_equal_approx(ButterflyView.SPAN_M * 2.0, 0.001)
	assert_float(box.size.y).is_less(0.01)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i: int in vertices.size():
		# o corpo e a raiz da asa no zero, a ponta no um
		if absf(vertices[i].x) <= 0.016:
			assert_float(uvs[i].x).is_equal(0.0)
		else:
			assert_float(uvs[i].x).is_equal(1.0)


func test_a_change_on_one_island_redoes_only_that_island() -> void:
	var changes := IslandDirty.new()
	# o começo: todas
	assert_int(changes.take(_world).size()).is_equal(_world.islands.size())
	assert_bool(changes.pending()).is_false()
	changes.mark_island(1)
	assert_array(changes.take(_world)).is_equal([1])
	# o prédio demolido sai do mundo: a ilha dele vem da conta guardada
	var some_id := -1
	for id: int in _world.buildings:
		some_id = id
		break
	if some_id >= 0:
		var island := _world.building(some_id).island_id
		changes.mark_building(_world, some_id)
		assert_array(changes.take(_world)).is_equal([island])
	# um prédio que ela nunca viu e que já saiu: todas
	changes.mark_building(_world, 999999)
	assert_int(changes.take(_world).size()).is_equal(_world.islands.size())
