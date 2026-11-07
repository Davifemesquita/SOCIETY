extends GdUnitTestSuite
## Relógio de sol no largo (Fase 224): cada serviço com largo ganha um relógio numa célula de canto do anel em volta dele, que
## é do largo; um relógio por serviço; a ilha plana (sem largo) não tem; a coluna fica de pé, com o mostrador em cima.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _place(def_id: StringName) -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found := SiteFinder.find(_sim, def_id, 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_each_plaza_service_gets_a_dial_on_a_corner_of_its_forecourt() -> void:
	var records: Array[BuildingRecord] = [_place(&"church"), _place(&"school")]
	var found := SundialView.cells(_sim.world, _sim.data, 0)
	var forecourt := ForecourtView.cells(_sim.world, _sim.data, 0)
	var owners: Dictionary[int, bool] = {}
	for cell: Vector2i in found:
		var id: int = found[cell]
		assert_bool(owners.has(id)).override_failure_message("dois relógios no mesmo serviço").is_false()
		owners[id] = true
		assert_bool(forecourt.has(cell)).is_true()
		var record := _sim.world.building(id)
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		# num canto do anel: fora da área, encostado nela só pela diagonal
		assert_bool(area.has_point(cell)).is_false()
		assert_bool(area.grow(1).has_point(cell)).is_true()
		var corner := (cell.x == area.position.x - 1 or cell.x == area.end.x) and (cell.y == area.position.y - 1
				or cell.y == area.end.y)
		assert_bool(corner).is_true()
	# todo serviço que tem algum canto no largo ganhou o seu
	for record: BuildingRecord in records:
		var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
		var has_corner := false
		for corner: Vector2i in [area.position - Vector2i.ONE, Vector2i(area.end.x, area.position.y - 1),
				Vector2i(area.position.x - 1, area.end.y), area.end]:
			if forecourt.has(corner):
				has_corner = true
		assert_bool(owners.has(record.id)).is_equal(has_corner)


func test_the_flat_island_has_none() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 30))
	sim.free_build = true
	SimFixture.place(sim, &"church", Vector2i(20, 10), 0)
	assert_int(SundialView.cells(sim.world, sim.data, 0).size()).is_equal(0)


func test_the_column_stands_with_the_dial_on_top() -> void:
	var box := SundialView.dial_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.end.y).is_between(SundialView.DIAL_Y + 0.1, SundialView.DIAL_Y + 0.25)
	# cabe numa célula
	assert_float(box.size.x).is_less(1.0)
	assert_float(box.size.z).is_less(1.0)
