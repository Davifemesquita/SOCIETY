extends GdUnitTestSuite
## Névoa nos vales (Fase 309): a força pela hora (nada de tarde e de noite, cheia de manhã cedo, mais no dia de neblina); os lugares
## só nas temperadas, em terra mais baixa que a volta e com mata perto; duas camadas por lugar acima do chão; o shader compila
## (com tela).

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([120])
	_config.tropical_island_sizes_cells = PackedInt32Array([50])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))


func test_the_mist_belongs_to_the_early_morning() -> void:
	for hour: float in [0.0, 2.0, 13.0, 18.0, 22.0]:
		assert_float(ValleyMistView.amount_at(hour, 1.0)).is_zero()
	assert_float(ValleyMistView.amount_at(6.5, 1.0)).is_equal_approx(1.0, 0.001)
	assert_float(ValleyMistView.amount_at(6.5, 0.0)).is_equal_approx(ValleyMistView.PLAIN_DAY, 0.001)
	assert_float(ValleyMistView.amount_at(9.5, 1.0)).is_between(0.05, 0.95)


func test_sites_sit_in_temperate_valleys_near_the_forest() -> void:
	var grid := _sim.world.island(0)
	var sites := ValleyMistView.sites(_sim.world, _sim.data, 0)
	assert_int(sites.size()).is_greater(0)
	for site: Vector3 in sites:
		var cell := grid.world_to_cell(site)
		assert_int(grid.ground[grid.index(cell)]).is_equal(IslandGrid.Ground.LAND)
		assert_float(site.y).is_equal_approx(grid.cell_height(cell), 0.001)
		var forest := 0
		for dy: int in range(-ValleyMistView.FOREST_REACH, ValleyMistView.FOREST_REACH + 1):
			for dx: int in range(-ValleyMistView.FOREST_REACH, ValleyMistView.FOREST_REACH + 1):
				if grid.trees[grid.index(cell + Vector2i(dx, dy))] > 0:
					forest += 1
		assert_int(forest).is_greater_equal(ValleyMistView.FOREST_MIN)
	for island_id: int in _sim.world.islands.size():
		if _sim.world.is_tropical(island_id, _sim.data):
			assert_int(ValleyMistView.sites(_sim.world, _sim.data, island_id).size()).is_equal(0)


func test_each_site_gets_two_sheets_above_the_ground() -> void:
	var site := Vector3(10.0, 3.0, -4.0)
	var sheets := ValleyMistView.sheets(site)
	assert_int(sheets.size()).is_equal(ValleyMistView.LAYERS.size())
	for k: int in sheets.size():
		assert_float(sheets[k].origin.y - site.y).is_equal_approx(ValleyMistView.LAYERS[k].x, 0.001)
		assert_float(sheets[k].basis.x.length()).is_equal_approx(ValleyMistView.LAYERS[k].y, 0.001)


func test_the_mist_shader_compiles() -> void:
	var names: Array[String] = []
	for entry: Dictionary in (load("res://shaders/valley_mist.gdshader") as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(raw)
	if DisplayServer.get_name() == "headless":
		return
	for wanted: String in ["amount", "mist_color", "opacity", "tear_m", "drift", "softness_m"]:
		assert_bool(names.has(wanted)).override_failure_message(wanted).is_true()
