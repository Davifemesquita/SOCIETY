extends GdUnitTestSuite
## Anel de cogumelos (Fase 272): a peça nova vem no fim da lista do campo aberto (o sorteio das peças de antes não muda) e
## depois das outras no enum; aparece nas ilhas temperadas, no chão de pouco desnível, nunca nas tropicais; a malha é uma roda
## baixa de cogumelos, rente ao chão.

var _config: GameConfig
var _world: WorldState


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


func test_the_ring_is_the_last_rule_of_the_open_field() -> void:
	assert_bool(_appended(ScatterView.OPEN, ScatterView.Kind.FAIRY_RING)).is_true()
	assert_int(ScatterView.Kind.FAIRY_RING).is_greater(ScatterView.Kind.FOXGLOVE)
	assert_bool(ScatterView.Kind.FAIRY_RING in ScatterView.SHADOWED).is_false()
	assert_bool(ScatterView.Kind.FAIRY_RING in ScatterView.PLANTS).is_false()


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


func test_rings_grow_on_temperate_islands_only() -> void:
	var data := GameData.get_default()
	var count := 0
	for island_id: int in _world.islands.size():
		var grid := _world.island(island_id)
		var tropical := _world.is_tropical(island_id, data)
		for cy: int in ceili(grid.size.y / float(ScatterView.CHUNK_CELLS)):
			for cx: int in ceili(grid.size.x / float(ScatterView.CHUNK_CELLS)):
				var items := ScatterView.places(_world, data, _config, island_id, Vector2i(cx, cy))
				var logs: Array = items[ScatterView.Kind.FAIRY_RING]
				if tropical:
					assert_int(logs.size()).is_equal(0)
				for item: Array in logs:
					var place: Transform3D = item[0]
					var cell := grid.world_to_cell(place.origin)
					assert_float(ScatterView.cell_relief(grid, cell)).is_less_equal(ScatterView.SCREE_MIN_RELIEF_M)
					# rente ao chão: o anel deitado no plano da célula
					assert_float(place.basis.y.normalized().y).is_greater(0.8)
				count += logs.size()
	print("anéis: ", count)
	assert_int(count).is_greater(0)


func test_the_ring_is_a_low_circle() -> void:
	var box := ScatterView.fairy_ring_mesh().get_aabb()
	assert_float(box.size.x).is_between(ScatterView.FAIRY_RING_M * 1.9, ScatterView.FAIRY_RING_M * 2.4)
	assert_float(box.size.y).is_less(0.25)
	assert_float(box.position.y).is_greater_equal(-0.05)
