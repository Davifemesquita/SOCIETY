extends GdUnitTestSuite
## Gaivotas no cais (Fase 168): parte dos cabeços que a HarborView desenhou ganha uma gaivota de pé no alto dele; o desenho do
## cais refeito refaz as gaivotas; cada uma vira de tempos em tempos, e o relógio parado (pausa) não as mexe; a gaivota é do
## tamanho de uma gaivota e fica de pé.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _views() -> Array:
	var harbor: HarborView = auto_free(HarborView.new())
	add_child(harbor)
	harbor.setup(_sim)
	var gulls: PerchedGullView = auto_free(PerchedGullView.new())
	add_child(gulls)
	gulls.setup(harbor, _config)
	return [harbor, gulls]


func _trading_post() -> void:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	assert_bool(_sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation)).ok()).is_true()


func test_some_bollards_get_a_gull_on_top() -> void:
	var views := _views()
	var harbor: HarborView = views[0]
	var gulls: PerchedGullView = views[1]
	gulls.rebuild()
	assert_int(gulls.gull_count()).is_equal(0)
	_trading_post()
	harbor.rebuild()
	gulls.rebuild()
	var bollards := harbor.bollard_places
	assert_int(bollards.size()).is_greater(PerchedGullView.PERCH_EVERY)
	assert_int(gulls.gull_count()).is_greater(0)
	assert_int(gulls.gull_count()).is_less(bollards.size())
	for spot: Vector3 in gulls.spots:
		var on_top := false
		for bollard: Transform3D in bollards:
			var top := bollard.origin + Vector3(0.0, PerchedGullView.BOLLARD_TOP_M, 0.0)
			if top.is_equal_approx(spot):
				on_top = true
		assert_bool(on_top).is_true()


func test_the_harbor_rebuild_marks_the_gulls() -> void:
	var views := _views()
	var harbor: HarborView = views[0]
	var gulls: PerchedGullView = views[1]
	gulls._dirty = false
	_trading_post()
	harbor.rebuild()
	assert_bool(gulls._dirty).is_true()


func test_the_gulls_turn_now_and_then_and_not_in_the_pause() -> void:
	var seen: Dictionary[int, bool] = {}
	for second: int in 60:
		seen[roundi(PerchedGullView.heading_at(12345, float(second)) * 100.0)] = true
	# em um minuto ela virou algumas vezes, mas não a cada segundo
	assert_int(seen.size()).is_between(3, 20)
	var views := _views()
	var harbor: HarborView = views[0]
	var gulls: PerchedGullView = views[1]
	_trading_post()
	harbor.rebuild()
	gulls.rebuild()
	var before := gulls.headings.duplicate()
	gulls.advance(0.0)
	assert_bool(gulls.headings == before).is_true()


func test_the_gull_is_gull_sized_and_stands() -> void:
	var box := PerchedGullView.gull_mesh().get_aabb()
	assert_float(box.position.y).is_greater_equal(-0.01)
	assert_float(box.size.z).is_between(0.3, 0.55)
	assert_float(box.size.y).is_between(0.2, 0.4)
