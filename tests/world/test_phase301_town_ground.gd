extends GdUnitTestSuite
## Chão de vila (Fase 301): nas ilhas temperadas o lote de cada casa, crescido de TOWN_YARD_REACH_M, vira chão batido no canal b da
## máscara das estradas, com a borda recortada e mais fraco que o terreiro tropical; longe da casa, nada.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _house(island_id: int) -> BuildingRecord:
	var grid := _sim.world.island(island_id)
	_sim.ignore_terrain = false
	var found: Array = SiteFinder.find(_sim, &"house", island_id, grid.size / 2)
	_sim.ignore_terrain = true
	var origin: Vector2i = found[0]
	var result := _sim.execute(PlaceBuildingCommand.new(island_id, &"house", origin, 0))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func _wear_at(mask: RoadMask, point: Vector2) -> int:
	var pixel := Vector2i((point / mask._grid.cell_size * mask.pixels_per_cell()).floor())
	return mask._bytes[(pixel.y * mask._width + pixel.x) * 4 + 2]


func test_temperate_houses_get_a_ragged_town_ground() -> void:
	assert_bool(_sim.world.is_tropical(0, _sim.data)).is_false()
	var record := _house(0)
	var mask := RoadMask.new(_sim.world, _sim.data, 0, _config.road_mask_px_per_cell, _config.road_mask_max_m)
	assert_bool(mask._town).is_true()
	var cell_size := _sim.world.island(0).cell_size
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var lot := Rect2(Vector2(area.position) * cell_size, Vector2(area.size) * cell_size)
	# no meio do lote o chão é batido, mas mais fraco que o terreiro tropical (0,9 × 255)
	var middle := _wear_at(mask, lot.get_center())
	assert_int(middle).is_greater(120)
	assert_int(middle).is_less(int(0.9 * 255.0) - 20)
	# a borda recortada: ao longo do lado de fora do lote, a uma mesma distância, a força varia
	var values := {}
	for k: int in 12:
		var point := Vector2(lot.position.x + lot.size.x * (k + 0.5) / 12.0, lot.end.y + RoadMask.TOWN_YARD_REACH_M * 0.3)
		values[_wear_at(mask, point)] = true
	assert_int(values.size()).is_greater(2)
	# bem longe da casa, nada
	var far := lot.end + Vector2.ONE * 4.0
	if far.x < mask._grid.size.x * cell_size and far.y < mask._grid.size.y * cell_size:
		assert_int(_wear_at(mask, far)).is_equal(0)
