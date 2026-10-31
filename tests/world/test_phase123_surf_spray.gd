extends GdUnitTestSuite
## Borrifo nas falésias (Fase 123): os pontos vêm das rochas da RockView que encostam no mar; a escolha fica entre os mais
## perto de onde a câmera olha e dentro do alcance; o jato sobe na beira da rocha, na água; o intervalo fica na faixa; os
## jatos se revezam.


func test_the_sites_come_from_the_sea_rocks() -> void:
	var config := GameConfig.new()
	var world := ArchipelagoGenerator.new_world(1840, config, GameData.get_default())
	var terrain: TerrainView = auto_free(TerrainView.new())
	add_child(terrain)
	terrain.setup(world, config, GameData.get_default())
	var rocks: RockView = auto_free(RockView.new())
	add_child(rocks)
	rocks.setup(terrain, world, config)
	var sites := rocks.spray_sites()
	assert_int(sites.size()).is_equal(rocks.rock_count())
	assert_int(sites.size()).is_greater(0)
	for site: Vector3 in sites:
		assert_float(site.z).is_greater(0.0)


func test_pick_stays_near_the_focus() -> void:
	var sites := PackedVector3Array([Vector3(0.0, 0.0, 1.0), Vector3(50.0, 0.0, 1.0), Vector3(500.0, 0.0, 1.0)])
	for index: int in 50:
		var site := SurfSprayView.pick(sites, Vector2(10.0, 0.0), index)
		assert_float(site.z).is_greater(0.0)
		assert_float(Vector2(site.x, site.y).distance_to(Vector2(10.0, 0.0))).is_less_equal(SurfSprayView.RANGE_M)
	assert_float(SurfSprayView.pick(sites, Vector2(2000.0, 0.0), 0).z).is_less(0.0)


func test_the_jet_rises_at_the_rock_edge_on_the_water() -> void:
	var site := Vector3(20.0, -5.0, 2.0)
	for index: int in 20:
		var at := SurfSprayView.spot(site, index)
		assert_float(at.y).is_equal_approx(SurfSprayView.WATER_Y, 0.001)
		assert_float(Vector2(at.x - site.x, at.z - site.y).length()).is_equal_approx(site.z * 0.9, 0.01)


func test_the_delay_stays_in_range() -> void:
	for index: int in 200:
		assert_float(SurfSprayView.delay(index)).is_between(SurfSprayView.INTERVAL_S.x, SurfSprayView.INTERVAL_S.y)


func test_the_jets_take_turns() -> void:
	var view: SurfSprayView = auto_free(SurfSprayView.new())
	add_child(view)
	view.setup(func() -> PackedVector3Array: return PackedVector3Array())
	for k: int in SurfSprayView.POOL + 2:
		view.launch(Vector3(k, 0.0, 0.0))
	assert_int(view.spray_count()).is_equal(SurfSprayView.POOL + 2)
	assert_int(view.get_child_count()).is_equal(SurfSprayView.POOL)


func test_the_jet_rises_on_the_sea_side() -> void:
	# o chão sobe para +x (terra) e desce para −x (mar): o jato fica do lado de −x
	var height := func(x: float, _z: float) -> float: return x - 20.0
	var site := Vector3(20.0, 5.0, 3.0)
	for index: int in 20:
		var at := SurfSprayView.spot(site, index, height)
		assert_float(at.x).is_less(site.x - site.z * 0.4)
