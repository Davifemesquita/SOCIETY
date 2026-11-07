extends GdUnitTestSuite
## Carroça de feno parada (Fase 193): ao lado das medas das fazendas do resto certo, numa célula livre vizinha da delas, fora
## do lote; tombada para a frente; a carga de feno fica sobre a caçamba; o recheio deixa a célula.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([60])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _farms(def_id: StringName, count: int) -> Array[int]:
	var grid := _sim.world.island(0)
	var ids: Array[int] = []
	var near := grid.size / 2
	for k: int in count * 4:
		var found := SiteFinder.find(_sim, def_id, 0, near)
		if found.is_empty():
			break
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
		if result.ok():
			ids.append(result.placed[0])
		near = Vector2i(posmod(near.x + 17, grid.size.x), posmod(near.y + 11, grid.size.y))
		if ids.size() >= count:
			break
	return ids


func test_wagons_stand_beside_the_haystacks() -> void:
	_farms(&"wheat_farm", 4)
	var stacks := HaystackView.cells(_sim.world, _sim.data, 0)
	var wagons := HayWagonView.cells(_sim.world, _sim.data, 0)
	assert_int(wagons.size()).is_greater(0)
	var grid := _sim.world.island(0)
	for cell: Vector2i in wagons:
		var farm_id: int = wagons[cell]
		assert_int(posmod(farm_id, HayWagonView.WAGON_EVERY)).is_equal(HayWagonView.WAGON_REST)
		# vizinha da célula das medas da mesma fazenda, pelo lado
		var beside := false
		for stack: Vector2i in stacks:
			if stacks[stack] == farm_id and absi(stack.x - cell.x) + absi(stack.y - cell.y) == 1:
				beside = true
		assert_bool(beside).is_true()
		var index := grid.index(cell)
		assert_int(grid.occupancy[index]).is_equal(0)
		assert_int(grid.roads[index]).is_equal(IslandGrid.Road.NONE)
		var place := HayWagonView.wagon_place(grid, cell, farm_id)
		# tombada para a frente: o eixo de cima inclina, mas pouco
		assert_float(place.basis.y.normalized().dot(Vector3.UP)).is_between(0.95, 0.999)


func test_the_scatter_keeps_the_wagon_cell_clear() -> void:
	_farms(&"wheat_farm", 4)
	var doors: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	for cell: Vector2i in HayWagonView.cells(_sim.world, _sim.data, 0):
		assert_bool(doors.has(cell)).is_true()


func test_the_hay_load_sits_on_the_bed() -> void:
	var box := HayWagonView.load_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(HayWagonView.LOAD_FOOT_M - 0.2)
	assert_float(box.end.y).is_between(HayWagonView.LOAD_FOOT_M + 0.6, HayWagonView.LOAD_FOOT_M + 1.1)
	assert_float(box.size.z).is_between(1.6, 2.4)
