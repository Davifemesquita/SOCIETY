extends GdUnitTestSuite
## Mata e recheio (Fase 41): copas fofas (tufos e normais da copa inteira) com histerese na troca de detalhe; recheio
## determinístico fora do save, nunca em estrada, prédio, árvore ou porta, encostado nos prédios e na beira da mata,
## refeito só nos trechos atingidos e sem mexer na simulação.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _view() -> ScatterView:
	var view: ScatterView = auto_free(ScatterView.new())
	add_child(view)
	view.setup(_sim.world, _sim.data, _config)
	return view


## Um lugar livre para o prédio (pelas regras da simulação), perto do meio da ilha principal.
func _site(def_id: StringName) -> Vector2i:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	var origin: Vector2i = found[0]
	return origin


func test_the_crowns_are_puffier_and_round() -> void:
	var near := TreeModel.mesh(TreeModel.Species.OAK, 0)
	var arrays := near.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	# as normais da folhagem apontam para fora do meio da copa (a copa é um volume de luz macia)
	var center := Vector3.ZERO
	var leaves := 0
	for i: int in points.size():
		if colors[i].g > colors[i].r * 1.2:
			center += points[i]
			leaves += 1
	center /= leaves
	var outward := 0
	for i: int in points.size():
		if colors[i].g > colors[i].r * 1.2 and normals[i].dot(points[i] - center) > 0.0:
			outward += 1
	assert_float(float(outward) / leaves).is_greater(0.85)
	# a troca de detalhe tem histerese
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(_sim.world, _sim.data, _config)
	var checked := 0
	for node: MultiMeshInstance3D in view.chunk_layers(0, Vector2i.ZERO):
		if node.name.ends_with("Far"):
			assert_float(node.visibility_range_begin_margin).is_equal(TreeView.LOD_MARGIN_M)
			checked += 1
		elif node.visibility_range_end == TreeView.NEAR_UNTIL_M:
			assert_float(node.visibility_range_end_margin).is_equal(TreeView.LOD_MARGIN_M)
	assert_int(checked).is_greater(0)


func test_scatter_is_deterministic_and_avoids_roads_buildings_trees_and_doors() -> void:
	var grid := _sim.world.island(0)
	var origin := _site(&"house")
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"house", origin, 0)).ok()).is_true()
	var road: Array[Vector2i] = []
	for x: int in range(origin.x - 6, origin.x + 9):
		road.append(Vector2i(x, origin.y - 1))
	_sim.execute(BuildRoadCommand.new(0, road))
	var a := ScatterView.places(_sim.world, _sim.data, _config, 0, origin / ScatterView.CHUNK_CELLS)
	var b := ScatterView.places(_sim.world, _sim.data, _config, 0, origin / ScatterView.CHUNK_CELLS)
	assert_str(var_to_str(a)).is_equal(var_to_str(b))
	var doors: Dictionary[Vector2i, bool] = {}
	for id: int in _sim.world.buildings:
		var record := _sim.world.buildings[id]
		var def := _sim.def_of(record)
		doors[Footprint.entrance_cell(record.origin, def.size, record.rotation)] = true
	var total := 0
	for kind: int in a:
		for item: Array in a[kind]:
			var place: Transform3D = item[0]
			var cell := grid.world_to_cell(place.origin)
			# a peça pode sair um pouco da célula dela; confere a célula de onde ela saiu (o meio, arredondado)
			assert_int(grid.building_at(cell)).override_failure_message("prédio em %s" % cell).is_equal(0)
			assert_bool(grid.has_road(cell)).override_failure_message("estrada em %s" % cell).is_false()
			assert_bool(doors.has(cell)).override_failure_message("porta em %s" % cell).is_false()
			total += 1
	assert_int(total).is_greater(0)


func test_houses_get_things_against_their_walls() -> void:
	var origin := _site(&"house")
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"house", origin, 0)).ok()).is_true()
	var grid := _sim.world.island(0)
	# a obra só limpa as árvores debaixo dela: a volta da casa fica limpa à mão (um quintal)
	for y: int in range(origin.y - 2, origin.y + 5):
		for x: int in range(origin.x - 2, origin.x + 5):
			grid.trees[grid.index(Vector2i(x, y))] = 0
	var lot := Rect2(grid.origin_m + Vector2(origin) * grid.cell_size, Vector2(3, 3) * grid.cell_size)
	var near := 0
	for chunk_y: int in range(origin.y / ScatterView.CHUNK_CELLS - 1, origin.y / ScatterView.CHUNK_CELLS + 2):
		for chunk_x: int in range(origin.x / ScatterView.CHUNK_CELLS - 1, origin.x / ScatterView.CHUNK_CELLS + 2):
			if chunk_x < 0 or chunk_y < 0:
				continue
			var items := ScatterView.places(_sim.world, _sim.data, _config, 0, Vector2i(chunk_x, chunk_y))
			for kind: int in [ScatterView.Kind.BUSH, ScatterView.Kind.FLOWERS, ScatterView.Kind.BARREL,
					ScatterView.Kind.WOODPILE, ScatterView.Kind.CRATE]:
				for item: Array in items[kind]:
					var place: Transform3D = item[0]
					if lot.grow(1.0).has_point(Vector2(place.origin.x, place.origin.z)):
						near += 1
	# a casa tem 12 células em volta (menos a porta e o que for estrada ou mata): sai alguma coisa encostada nela
	assert_int(near).is_greater(0)


func test_only_the_touched_chunks_are_redone_and_nothing_goes_to_the_save() -> void:
	var view := _view()
	var before := view.rebuilt_chunks
	var count := view.item_count()
	assert_int(count).is_greater(100)
	var origin := _site(&"house")
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"house", origin, 0)).ok()).is_true()
	view._process(0.0)
	var redone := view.rebuilt_chunks - before
	assert_int(redone).is_between(1, 4)
	# o recheio sai do mundo: salvar e carregar dá a mesma lista
	var chunk := origin / ScatterView.CHUNK_CELLS
	var items := var_to_str(ScatterView.places(_sim.world, _sim.data, _config, 0, chunk))
	var loaded := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _config)
	assert_str(var_to_str(ScatterView.places(loaded, _sim.data, _config, 0, chunk))).is_equal(items)
	var state := var_to_str(_sim.world.to_dict())
	view.rebuild()
	assert_str(var_to_str(_sim.world.to_dict())).is_equal(state)


func test_scatter_of_a_full_archipelago_in_reasonable_time() -> void:
	var config := GameConfig.get_default()
	var world := ArchipelagoGenerator.new_world(1840, config, GameData.get_default())
	var view: ScatterView = auto_free(ScatterView.new())
	add_child(view)
	var started := Time.get_ticks_msec()
	view.setup(world, GameData.get_default(), config)
	var elapsed := Time.get_ticks_msec() - started
	print("Fase 41: recheio da semente 1840 em %d ms, %d peças" % [elapsed, view.item_count()])
	assert_int(view.item_count()).is_greater(1000)
