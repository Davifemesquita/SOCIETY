extends GdUnitTestSuite
## Beleza (Fase 16): a decoração embeleza as casas em volta (cai com a distância, soma até 1), não pede
## estrada e a beleza entra na felicidade da casa.

const STREET := 10

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 30))
	SimFixture.road(_sim, Vector2i(2, STREET), Vector2i(70, STREET))


func test_a_decoration_beautifies_the_houses_around_it() -> void:
	var near := SimFixture.house(_sim, 10, STREET, &"peasants", 10.0)
	var far := SimFixture.house(_sim, 40, STREET, &"peasants", 10.0)
	# canteiro logo atrás da primeira casa (as casas ficam de y = 7 a 9)
	var bed := SimFixture.place(_sim, &"flower_bed", Vector2i(11, 5), 0)
	var derived := _sim.derived_state()
	var def := _sim.data.building(&"flower_bed")
	var beauty: float = derived.beauty[near]
	# um espaço de uma célula entre o canteiro e a casa: cai uma fração do raio
	assert_float(beauty).is_equal_approx(def.beauty * (1.0 - 1.0 / float(def.beauty_radius_cells + 1)), 0.001)
	var far_beauty: float = derived.beauty[far]
	assert_float(far_beauty).is_equal(0.0)
	# não pede estrada
	assert_bool(_sim.has_road_access(bed)).is_true()


func test_beauty_adds_up_to_one() -> void:
	var house := SimFixture.house(_sim, 10, STREET, &"peasants", 10.0)
	for x: int in range(2, 30):
		for y: int in range(0, 6):
			_sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND, &"planted_tree", Vector2i(x, y), 0))
	var beauty: float = _sim.derived_state().beauty[house]
	assert_float(beauty).is_equal(1.0)


func test_beauty_raises_happiness() -> void:
	var plain := SimFixture.house(_sim, 10, STREET, &"peasants", 10.0)
	var pretty := SimFixture.house(_sim, 40, STREET, &"peasants", 10.0)
	for x: int in range(38, 46):
		_sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND, &"planted_tree", Vector2i(x, 6), 0))
	_sim.run_ticks(roundi(180.0 / _sim.config.tick_interval()))
	var gap := _sim.world.building(pretty).happiness - _sim.world.building(plain).happiness
	var beauty: float = _sim.derived_state().beauty[pretty]
	assert_float(beauty).is_greater(0.5)
	assert_float(gap).is_equal_approx(_sim.config.happiness_per_beauty * beauty, 0.5)


func test_every_decoration_is_cheap_harmless_and_in_its_own_menu_tab() -> void:
	var decorations := _sim.data.buildings.filter(func(def: BuildingDef) -> bool: return def.is_decoration())
	assert_int(decorations.size()).is_greater_equal(3)
	for def: BuildingDef in decorations:
		assert_float(def.beauty).override_failure_message(String(def.id)).is_greater(0.0)
		assert_int(def.beauty_radius_cells).override_failure_message(String(def.id)).is_greater(0)
		assert_float(def.fire_risk).override_failure_message(String(def.id)).is_equal(0.0)
		assert_int(def.workers).is_equal(0)


func test_the_beauty_layer_paints_around_decorations() -> void:
	SimFixture.place(_sim, &"statue", Vector2i(30, 20), 0)
	var image := MapOverlays.image(MapOverlays.Layer.BEAUTY, _sim, SimFixture.ISLAND)
	var def := _sim.data.building(&"statue")
	# a estátua, a borda do raio e fora dele
	assert_float(image.get_pixel(30, 20).a).is_greater(0.2)
	assert_float(image.get_pixel(30 - def.beauty_radius_cells, 20).a).is_greater(0.0)
	assert_float(image.get_pixel(30 - def.beauty_radius_cells - 1, 20).a).is_equal(0.0)
