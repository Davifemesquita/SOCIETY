extends GdUnitTestSuite
## Barco na areia (Fase 183): junto da cabana de pesca, na praia (terra livre, baixa e quase plana, encostada no mar pelo lado),
## com as vizinhas ao longo da costa livres; o barco virado de borco ao longo da costa, com a borda na areia; os remos do lado de
## terra; o recheio deixa as células limpas; nada na ilha plana.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


## Cabanas de pesca na ilha principal, achadas pelo SiteFinder em volta de alguns pontos; devolve os ids.
func _fisheries(count: int) -> Array[int]:
	var grid := _sim.world.island(0)
	var ids: Array[int] = []
	var near := grid.size / 2
	for k: int in count * 4:
		var found := SiteFinder.find(_sim, &"fishery", 0, near)
		if found.is_empty():
			break
		var origin: Vector2i = found[0]
		var rotation: int = found[1]
		var result := _sim.execute(PlaceBuildingCommand.new(0, &"fishery", origin, rotation))
		if result.ok():
			ids.append(result.placed[0])
		near = Vector2i(posmod(near.x + 37, grid.size.x), posmod(near.y + 53, grid.size.y))
		if ids.size() >= count:
			break
	return ids


func test_the_boat_lies_on_the_beach_by_the_hut() -> void:
	var huts := _fisheries(3)
	assert_int(huts.size()).is_greater(0)
	var grid := _sim.world.island(0)
	var found := BeachBoatView.sites(_sim.world, _sim.data, 0)
	assert_int(found.size()).is_greater(0)
	for cell: Vector2i in found:
		var sea := found[cell]
		assert_int(grid.ground_at(cell + sea)).is_equal(IslandGrid.Ground.SEA)
		var along := Vector2i(-sea.y, sea.x)
		for step: Vector2i in [Vector2i.ZERO, along, -along]:
			var index := grid.index(cell + step)
			assert_int(grid.ground[index]).is_equal(IslandGrid.Ground.LAND)
			assert_int(grid.occupancy[index]).is_equal(0)
			assert_int(grid.roads[index]).is_equal(IslandGrid.Road.NONE)
			assert_int(grid.trees[index]).is_equal(0)
		var corners := BuildingKit.corner_range(grid, Rect2i(cell, Vector2i.ONE))
		assert_float(corners.y).is_less_equal(BeachBoatView.MAX_HEIGHT_M)
		# perto de uma cabana
		var near_hut := false
		for id: int in huts:
			var record := _sim.world.building(id)
			var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation).grow(BeachBoatView.REACH)
			if area.has_point(cell):
				near_hut = true
		assert_bool(near_hut).is_true()


func test_the_boat_is_upside_down_along_the_coast_with_the_oars_inland() -> void:
	_fisheries(3)
	var grid := _sim.world.island(0)
	var found := BeachBoatView.sites(_sim.world, _sim.data, 0)
	for cell: Vector2i in found:
		var sea := found[cell]
		var place := BeachBoatView.boat_place(grid, cell, sea)
		# a quilha para cima e o comprimento ao longo da costa
		assert_float(place.basis.y.normalized().dot(Vector3.DOWN)).is_greater(0.99)
		var along := Vector3(-sea.y, 0.0, sea.x)
		assert_float(absf(place.basis.z.normalized().dot(along))).is_greater(0.99)
		# a borda do casco perto da areia
		var ground := grid.height_at(place.origin.x, place.origin.z)
		var top := HarborView.boat_mesh().get_aabb().end.y
		assert_float(place.origin.y - top - ground).is_between(-0.2, 0.2)
		var middle := grid.cell_world(cell)
		for oar: Transform3D in BeachBoatView.oar_places_of(grid, cell, sea):
			var offset := oar.origin - middle
			assert_float(Vector2(offset.x, offset.z).dot(Vector2(sea))).is_less(0.0)


func test_the_scatter_keeps_the_boat_cells_clear() -> void:
	_fisheries(3)
	var doors: Dictionary = ScatterView.island_context(_sim.world, _sim.data, 0)[0]
	for cell: Vector2i in BeachBoatView.cells(_sim.world, _sim.data, 0):
		assert_bool(doors.has(cell)).is_true()


func test_none_on_the_flat_island() -> void:
	var sim := SimFixture.simulation(Vector2i(60, 60))
	sim.free_build = true
	sim.ignore_terrain = true
	SimFixture.place(sim, &"fishery", Vector2i(10, 0), 0)
	assert_int(BeachBoatView.sites(sim.world, sim.data, SimFixture.ISLAND).size()).is_equal(0)
