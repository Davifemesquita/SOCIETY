extends GdUnitTestSuite
## Patos na água (Fase 196): os bandos nadam em roda sobre a água de fundo raso junto da costa baixa, de frente para onde
## vão; os patinhos seguem a pata pela mesma roda; nenhum bando perto do porto; a ilha plana não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true


func _all_flocks() -> Array[DuckView.Flock]:
	var result: Array[DuckView.Flock] = []
	for island_id: int in _sim.world.islands.size():
		result.append_array(DuckView.flocks(_sim.world, _sim.data, island_id))
	return result


func test_the_flocks_swim_over_shallow_water() -> void:
	var found := _all_flocks()
	assert_int(found.size()).is_greater(0)
	for island_id: int in _sim.world.islands.size():
		var grid := _sim.world.island(island_id)
		for flock: DuckView.Flock in DuckView.flocks(_sim.world, _sim.data, island_id):
			assert_bool(DuckView.ring_in_water(grid, flock.center, flock.radius)).is_true()
			assert_bool(grid.ground_at(grid.world_to_cell(flock.center)) != IslandGrid.Ground.LAND).is_true()
			assert_float(flock.radius).is_between(DuckView.RADIUS_M.x - 0.001, DuckView.RADIUS_M.y)
			assert_int(flock.kinds.size()).is_equal(flock.seeds.size())
			if flock.kinds.has(DuckView.Duck.DUCKLING):
				# a família: a pata na frente e só patinhos atrás
				assert_int(flock.kinds[0]).is_equal(DuckView.Duck.HEN)
				for k: int in range(1, flock.kinds.size()):
					assert_int(flock.kinds[k]).is_equal(DuckView.Duck.DUCKLING)


func test_the_ducks_go_round_facing_the_way() -> void:
	for flock: DuckView.Flock in _all_flocks():
		for k: int in flock.kinds.size():
			# um instante em que ele nada de cabeça para fora (mergulhando, o giro no peito mexe a origem)
			var time := 0.0
			while DuckView.dabble(flock.seeds[k], time) > 0.0 or DuckView.dabble(flock.seeds[k], time + 0.2) > 0.0:
				time += 0.5
			var now := DuckView.pose(flock, k, time)
			var later := DuckView.pose(flock, k, time + 0.2)
			var moved := later.origin - now.origin
			moved.y = 0.0
			assert_float(moved.length()).is_greater(0.0)
			var front := -now.basis.z
			front.y = 0.0
			assert_float(front.normalized().dot(moved.normalized())).is_greater(0.95)
			var flat := now.origin - flock.center
			flat.y = 0.0
			assert_float(flat.length()).is_equal_approx(flock.radius, 0.001)
			assert_float(absf(now.origin.y - DuckView.WATER_Y)).is_less_equal(DuckView.BOB_M + 0.0001)


func test_the_ducklings_follow_the_hen() -> void:
	var flock := DuckView.Flock.new()
	flock.center = Vector3(10.0, 0.0, 20.0)
	flock.radius = 2.5
	flock.turn = -1.0
	flock.start = 0.7
	flock.kinds.assign([DuckView.Duck.HEN, DuckView.Duck.DUCKLING, DuckView.Duck.DUCKLING, DuckView.Duck.DUCKLING])
	flock.seeds = PackedInt32Array([11, 22, 33, 44])
	for k: int in range(1, flock.kinds.size()):
		# o patinho está onde a pata estava DuckView.gap_of / velocidade segundos antes, mais junto dos outros patinhos
		var behind := DuckView.gap_of(flock, k) / DuckView.SWIM_M_S
		var when := 20.0
		while DuckView.dabble(flock.seeds[0], when - behind) > 0.0:
			when += 0.5
		var duckling := DuckView.pose(flock, k, when).origin
		var hen := DuckView.pose(flock, 0, when - behind).origin
		assert_float(Vector2(duckling.x, duckling.z).distance_to(Vector2(hen.x, hen.z))).is_less(0.001)
		assert_float(DuckView.pose(flock, k, 20.0).basis.get_scale().x).is_equal_approx(DuckView.DUCKLING_SCALE * DuckView.SIZE, 0.001)
	assert_float(DuckView.gap_of(flock, 2) - DuckView.gap_of(flock, 1)).is_equal_approx(DuckView.DUCKLING_GAP_M, 0.0001)


func test_no_flock_by_a_harbor() -> void:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"trading_post", 0, grid.size / 2)
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"trading_post", origin, rotation))
	assert_bool(result.ok()).is_true()
	var record := _sim.world.building(result.placed[0])
	var area := Footprint.rect(record.origin, _sim.def_of(record).size, record.rotation)
	var post := Vector2(area.position) + Vector2(area.size) * 0.5
	# os bandos perto do porto saem; os outros ficam como o terreno deu
	assert_int(DuckView.flocks(_sim.world, _sim.data, 0).size()).is_less_equal(DuckView.candidates(grid, 0).size())
	for flock: DuckView.Flock in DuckView.flocks(_sim.world, _sim.data, 0):
		assert_float(post.distance_to(flock.cell)).is_greater_equal(DuckView.HARBOR_CELLS)


func test_the_dabble_comes_and_goes() -> void:
	var down := 0
	for step: int in 400:
		var angle := DuckView.dabble(12345, step * 0.1)
		assert_float(angle).is_between(0.0, DuckView.DABBLE_RAD)
		if angle > DuckView.DABBLE_RAD * 0.5:
			down += 1
	assert_int(down).is_greater(0)
	assert_int(down).is_less(200)


func test_the_flat_island_has_none() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 30))
	assert_int(DuckView.flocks(sim.world, sim.data, 0).size()).is_equal(0)
