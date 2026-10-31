extends GdUnitTestSuite
## Poças de luz (Fase 119): uma poça por poste e por fogueira e uma na porta de cada casa com morador, deitada no chão
## logo acima dele; casa vazia fica escura; a vista desenha as portas acesas.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _house() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"house", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"house", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_one_pool_per_lamp_and_fire() -> void:
	var lamps: Array[Vector3] = []
	var fires: Array[Vector3] = []
	var grid := _sim.world.island(0)
	var center := grid.cell_world(grid.size / 2)
	lamps.append(center + Vector3(0.0, 2.9, 0.0))
	fires.append(center + Vector3(4.0, 0.5, 0.0))
	var list := LightPoolView.pools(_sim.world, _sim.data, lamps, fires)
	assert_int(list.size()).is_equal(2)
	for pool: Array in list:
		var place: Transform3D = pool[0]
		var ground := _sim.world.surface_height(place.origin.x, place.origin.z)
		# logo acima do chão, deitado (o eixo de cima quase vertical)
		assert_float(place.origin.y - ground).is_between(0.0, 0.3)
		assert_float(place.basis.y.normalized().y).is_greater(0.7)


func test_the_door_of_an_occupied_house_glows() -> void:
	var record := _house()
	var empty: Array[Vector3] = []
	assert_int(LightPoolView.pools(_sim.world, _sim.data, empty, empty).size()).is_equal(0)
	record.residents = 3.0
	var list := LightPoolView.pools(_sim.world, _sim.data, empty, empty)
	assert_int(list.size()).is_equal(1)
	# a poça fica diante da porta, fora da casa
	var place: Transform3D = list[0][0]
	var grid := _sim.world.island(0)
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	assert_bool(area.has_point(grid.world_to_cell(place.origin))).is_false()


func test_the_view_draws_the_lit_doors() -> void:
	var record := _house()
	record.residents = 3.0
	var view: LightPoolView = auto_free(LightPoolView.new())
	add_child(view)
	view.setup(_sim, null)
	assert_int(view.pool_count()).is_equal(1)
	assert_int(LightPoolView.lit_houses(_sim.world)).is_equal(1)
