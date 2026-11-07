extends GdUnitTestSuite
## Juncos na margem (Fase 179): a peça nova vem no fim do enum e balança como as plantas; as touceiras ficam só na terra
## encostada no rio, na margem baixa, na beira da água; o sorteio é o mesmo a cada vez; a touceira é alta e estreita.

var _config: GameConfig
var _world: WorldState
var _data: GameData


func before_test() -> void:
	_config = GameConfig.new()
	_data = GameData.get_default()
	_world = ArchipelagoGenerator.new_world(1840, _config, _data)


func _reeds(island_id: int) -> Array:
	var grid := _world.island(island_id)
	var context := ScatterView.island_context(_world, _data, island_id)
	var found: Array = []
	for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
		for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
			var items := ScatterView.places(_world, _data, _config, island_id, Vector2i(cx, cy), context)
			var reeds: Array = items[ScatterView.Kind.REEDS]
			found.append_array(reeds)
	return found


func test_the_reeds_come_after_the_older_pieces_and_sway() -> void:
	# peça nova vai no fim do enum: as de antes não mudam de número (a Fase 207 pôs o pinheiro-anão depois)
	assert_int(ScatterView.Kind.REEDS).is_greater(ScatterView.Kind.TALL_GRASS)
	assert_bool(ScatterView.Kind.REEDS in ScatterView.PLANTS).is_true()


func test_reeds_grow_on_the_low_river_bank_by_the_water() -> void:
	var grid := _world.island(0)
	var reeds := _reeds(0)
	assert_int(reeds.size()).is_greater(5)
	for item: Array in reeds:
		var place: Transform3D = item[0]
		var cell := grid.world_to_cell(place.origin)
		assert_int(grid.ground_at(cell)).is_equal(IslandGrid.Ground.LAND)
		var by_river := false
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if grid.in_bounds(cell + step) and grid.ground_at(cell + step) == IslandGrid.Ground.RIVER:
				by_river = true
		assert_bool(by_river).is_true()
		var middle := grid.cell_world(cell)
		assert_float(grid.height_at(middle.x, middle.z)).is_less_equal(ScatterView.REEDS_MAX_HEIGHT_M)
		# de pé, no chão
		assert_float(place.basis.y.normalized().dot(Vector3.UP)).is_greater(0.99)


func test_the_same_world_gives_the_same_reeds() -> void:
	var first := _reeds(0)
	var second := _reeds(0)
	assert_int(second.size()).is_equal(first.size())
	for i: int in first.size():
		var a: Transform3D = first[i][0]
		var b: Transform3D = second[i][0]
		assert_bool(a.is_equal_approx(b)).is_true()


func test_the_clump_is_tall_and_narrow() -> void:
	var box := ScatterView.reeds_mesh().get_aabb()
	assert_float(box.end.y).is_between(ScatterView.REEDS_HEIGHT_M.y * 0.9, ScatterView.REEDS_HEIGHT_M.y + 0.3)
	assert_float(maxf(box.size.x, box.size.z)).is_less(ScatterView.REEDS_RADIUS_M * 2.0 + 0.5)
