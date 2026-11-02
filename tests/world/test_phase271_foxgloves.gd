extends GdUnitTestSuite
## Dedaleiras (Fase 271): a peça nova vem no fim da lista da beira da mata (o sorteio das peças de antes não muda) e
## depois das outras no enum; aparece nas ilhas temperadas, de pé, nunca nas tropicais; a malha é a touceira com as hastes
## de sinos roxos.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_foxglove_is_the_last_rule_of_the_forest_edge() -> void:
	assert_bool(_appended(ScatterView.NEAR_FOREST, ScatterView.Kind.FOXGLOVE)).is_true()
	assert_int(ScatterView.Kind.FOXGLOVE).is_greater(ScatterView.Kind.HAWTHORN)
	assert_bool(ScatterView.Kind.FOXGLOVE in ScatterView.SHADOWED).is_false()
	assert_bool(ScatterView.Kind.FOXGLOVE in ScatterView.PLANTS).is_true()


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


func test_foxgloves_grow_on_temperate_islands_only() -> void:
	var data := GameData.get_default()
	var count := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var tropical := _world.is_tropical(island_id, data)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var bushes: Array = items[ScatterView.Kind.FOXGLOVE]
				if tropical:
					assert_int(bushes.size()).is_equal(0)
				for item: Array in bushes:
					var place: Transform3D = item[0]
					# de pé: o arbusto cresce para cima
					assert_float(place.basis.y.normalized().y).is_greater(0.99)
				count += bushes.size()
	print("dedaleiras: ", count)
	assert_int(count).is_greater(0)


func test_the_foxglove_is_tall_with_purple_bells() -> void:
	var mesh := ScatterView.foxglove_mesh()
	var box := mesh.get_aabb()
	assert_float(box.end.y).is_between(1.4, 1.9)
	assert_float(box.size.x).is_less(1.0)
	# os sinos roxos (o vermelho e o azul acima do verde) do meio para cima das hastes
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var purple_high := 0
	var purple_low := 0
	for i: int in vertices.size():
		if colors[i].r > colors[i].g and colors[i].b > colors[i].g:
			if vertices[i].y > 0.5:
				purple_high += 1
			elif vertices[i].y < 0.3:
				purple_low += 1
	assert_int(purple_high).is_greater(0)
	assert_int(purple_low).is_equal(0)
