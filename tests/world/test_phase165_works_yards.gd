extends GdUnitTestSuite
## Chão batido das fábricas (Fase 165): em volta de cada prédio de produção (fora campo, pasto e as fazendas de campo) o chão
## vira terra batida no canal b da máscara das estradas, em qualquer ilha, cheio no lote e somindo além dele, com a borda
## recortada (não um retângulo); construir redesenha o pátio.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


## Um prédio num lugar de terra da ilha principal (o SiteFinder confere o terreno; a construção ignora o resto das regras).
func _place(def_id: StringName) -> BuildingRecord:
	var grid := _sim.world.island(0)
	_sim.ignore_terrain = false
	var found: Array = SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	_sim.ignore_terrain = true
	var origin: Vector2i = found[0]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, 0))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func _wear_at(mask: RoadMask, point: Vector2) -> int:
	var pixel := Vector2i((point / mask._grid.cell_size * mask.pixels_per_cell()).floor())
	return mask._bytes[(pixel.y * mask._width + pixel.x) * 4 + 2]


func test_production_buildings_get_a_beaten_earth_yard() -> void:
	var record := _place(&"lumberjack")
	var lots := RoadMask.works(_sim.world, _sim.data, 0)
	assert_bool(lots.has(record.id)).is_true()
	var mask := RoadMask.new(_sim.world, _sim.data, 0, _config.road_mask_px_per_cell, _config.road_mask_max_m)
	var cell_size := _sim.world.island(0).cell_size
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	# no canto do lote o chão é batido; bem longe do pátio, não
	assert_int(_wear_at(mask, Vector2(area.position) * cell_size + Vector2.ONE * 0.2)).is_greater(150)
	var far := lots[record.id].end + Vector2.ONE * 3.0
	if far.x < mask._grid.size.x * cell_size and far.y < mask._grid.size.y * cell_size:
		assert_int(_wear_at(mask, far)).is_equal(0)


func test_houses_fields_and_field_farms_get_none() -> void:
	var house := _place(&"house")
	var lots := RoadMask.works(_sim.world, _sim.data, 0)
	assert_bool(lots.has(house.id)).is_false()
	for def: BuildingDef in _sim.data.buildings:
		if def.module_id != &"":
			assert_bool(def.is_production()).override_failure_message(String(def.id)).is_true()
	for id: int in lots:
		var def := _sim.def_of(_sim.world.building(id))
		assert_bool(def.is_production()).is_true()
		assert_str(String(def.module_id)).is_empty()


func test_the_edge_is_ragged() -> void:
	var record := _place(&"lumberjack")
	var mask := RoadMask.new(_sim.world, _sim.data, 0, _config.road_mask_px_per_cell, _config.road_mask_max_m)
	var lot: Rect2 = RoadMask.works(_sim.world, _sim.data, 0)[record.id]
	# ao longo da borda de cima, um pouco para dentro, o chão batido varia (o ruído recorta a borda)
	var values: Dictionary[int, bool] = {}
	for k: int in 20:
		var point := Vector2(lot.position.x + lot.size.x * (k + 0.5) / 20.0, lot.position.y + 0.7)
		values[_wear_at(mask, point) / 20] = true
	assert_int(values.size()).is_greater(2)


func test_a_new_workshop_redraws_the_yard() -> void:
	var mask := RoadMask.new(_sim.world, _sim.data, 0, _config.road_mask_px_per_cell, _config.road_mask_max_m)
	var record := _place(&"lumberjack")
	var area := mask.refresh()
	var lot := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	assert_bool(area.encloses(lot)).is_true()
