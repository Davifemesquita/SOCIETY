extends GdUnitTestSuite
## Terreiro tropical (Fase 111): nas ilhas tropicais o chão em volta de cada casa vira terra batida (canal b da máscara das
## estradas), cheio no lote e somindo além dele; as ilhas temperadas não têm; construir uma casa redesenha o terreiro.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _tropical() -> int:
	for index: int in _sim.world.islands.size():
		if _sim.world.is_tropical(index, _sim.data) and not _sim.world.island(index).flat:
			return index
	return -1


## Uma casa num lugar de terra da ilha (o SiteFinder confere o terreno; a construção ignora o resto das regras).
func _house(island_id: int) -> BuildingRecord:
	var grid := _sim.world.island(island_id)
	_sim.ignore_terrain = false
	var found: Array = SiteFinder.find(_sim, &"house", island_id, grid.size / 2)
	_sim.ignore_terrain = true
	var origin: Vector2i = found[0]
	var result := _sim.execute(PlaceBuildingCommand.new(island_id, &"house", origin, 0))
	assert_bool(result.ok()).is_true()
	var record := _sim.world.building(result.placed[0])
	record.tier = &"peasants"
	return record


func _wear_at(mask: RoadMask, point: Vector2) -> int:
	var pixel := Vector2i((point / mask._grid.cell_size * mask.pixels_per_cell()).floor())
	return mask._bytes[(pixel.y * mask._width + pixel.x) * 4 + 2]


func test_tropical_houses_get_a_beaten_earth_yard() -> void:
	var island := _tropical()
	assert_int(island).is_greater_equal(0)
	var record := _house(island)
	var lots := RoadMask.yards(_sim.world, _sim.data, island)
	assert_bool(lots.has(record.id)).is_true()
	var mask := RoadMask.new(_sim.world, _sim.data, island, _config.road_mask_px_per_cell, _config.road_mask_max_m)
	var lot := lots[record.id]
	var cell_size := _sim.world.island(island).cell_size
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	# no canto do lote (já dentro do terreiro) o chão é batido; bem longe dele, não
	var corner := Vector2(area.position) * cell_size + Vector2.ONE * 0.2
	assert_int(_wear_at(mask, corner)).is_greater(150)
	var far := lot.end + Vector2.ONE * 3.0
	if far.x < mask._grid.size.x * cell_size and far.y < mask._grid.size.y * cell_size:
		assert_int(_wear_at(mask, far)).is_equal(0)


func test_temperate_islands_have_no_yards() -> void:
	_house(0)
	assert_int(RoadMask.yards(_sim.world, _sim.data, 0).size()).is_equal(0)


func test_a_new_house_redraws_the_yard() -> void:
	var island := _tropical()
	var mask := RoadMask.new(_sim.world, _sim.data, island, _config.road_mask_px_per_cell, _config.road_mask_max_m)
	var record := _house(island)
	var area := mask.refresh()
	var lot := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	assert_bool(area.encloses(lot)).is_true()
