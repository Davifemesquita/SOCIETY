extends GdUnitTestSuite
## Girassóis (Fase 274): a peça nova vem no fim da lista junto das casas (o sorteio das peças de antes não muda) e depois das outras
## no enum; aparece encostada nas casas das ilhas temperadas, de pé, nunca nas tropicais; a malha é a touceira alta com as flores
## amarelas no alto.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func test_the_sunflower_is_the_last_rule_by_the_houses() -> void:
	assert_bool(_appended(ScatterView.NEAR_HOUSE, ScatterView.Kind.SUNFLOWER)).is_true()
	assert_int(ScatterView.Kind.SUNFLOWER).is_greater(ScatterView.Kind.FAIRY_RING)
	assert_bool(ScatterView.Kind.SUNFLOWER in ScatterView.PLANTS).is_true()
	assert_bool(ScatterView.Kind.SUNFLOWER in ScatterView.SHADOWED).is_false()


## Se a peça está na lista com só peças mais velhas antes dela e só mais novas depois (o sorteio de antes não mudou).
func _appended(rules: Array[Array], kind: int) -> bool:
	var seen := false
	for rule: Array in rules:
		var other: int = rule[0]
		if other == kind:
			seen = true
		elif (other > kind) != seen:
			return false
	return seen


func _sunflowers(island_id: int) -> Array:
	var grid := _sim.world.island(island_id)
	var found: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_sim.world, _sim.data, _config, island_id, Vector2i(cx, cy))
			var flowers: Array = items[ScatterView.Kind.SUNFLOWER]
			found.append_array(flowers)
	return found


## Uma fileira de casas com uma célula livre entre elas, no lugar livre perto do meio da ilha.
func _houses(island_id: int) -> int:
	var grid := _sim.world.island(island_id)
	var found: Array = SiteFinder.find(_sim, &"house", island_id, grid.size / 2)
	var origin: Vector2i = found[0]
	var placed := 0
	_sim.ignore_terrain = true
	for i: int in 8:
		if _sim.execute(PlaceBuildingCommand.new(island_id, &"house", origin + Vector2i(i * 4, 0), 0)).ok():
			placed += 1
	_sim.ignore_terrain = false
	return placed


func test_sunflowers_grow_by_temperate_houses_only() -> void:
	assert_int(_houses(0)).is_greater(4)
	var grid := _sim.world.island(0)
	var flowers := _sunflowers(0)
	print("girassóis: ", flowers.size())
	assert_int(flowers.size()).is_greater(0)
	for item: Array in flowers:
		var place: Transform3D = item[0]
		# de pé, numa célula livre encostada numa casa
		assert_float(place.basis.y.normalized().y).is_greater(0.99)
		var cell := grid.world_to_cell(place.origin)
		assert_int(grid.occupancy[grid.index(cell)]).is_equal(0)
		var beside_house := false
		for side: Vector2i in ScatterView.SIDES:
			var other := cell + side
			if grid.in_bounds(other):
				var building := grid.occupancy[grid.index(other)]
				if building != 0 and _sim.world.building(building).is_house():
					beside_house = true
		assert_bool(beside_house).is_true()
	# a ilha tropical não tem girassol, nem com casas
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			_houses(island_id)
			assert_int(_sunflowers(island_id).size()).is_equal(0)


func test_the_sunflower_is_tall_with_yellow_flowers() -> void:
	var mesh := ScatterView.sunflower_mesh()
	var box := mesh.get_aabb()
	assert_float(box.end.y).is_between(1.8, 2.4)
	assert_float(box.size.x).is_less(1.4)
	# as pétalas amarelas (o vermelho e o verde bem acima do azul) só no alto das hastes
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var yellow_high := 0
	var yellow_low := 0
	for i: int in vertices.size():
		if colors[i].r > 0.8 and colors[i].g > 0.6 and colors[i].b < 0.3:
			if vertices[i].y > 1.0:
				yellow_high += 1
			else:
				yellow_low += 1
	assert_int(yellow_high).is_greater(0)
	assert_int(yellow_low).is_equal(0)
