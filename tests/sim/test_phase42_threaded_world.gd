extends GdUnitTestSuite
## Jogo novo em etapas (Fase 42): o arquipélago gerado com uma ilha por tarefa no WorkerThreadPool é idêntico ao do
## caminho direto (o save e as impressões digitais das ilhas), com o progresso só subindo até 1.

var _config: GameConfig


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([70, 50, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([40, 30])


func _fingerprints(world: WorldState) -> PackedInt64Array:
	var result := PackedInt64Array()
	for grid: IslandGrid in world.islands:
		result.append(grid.fingerprint)
	return result


func test_the_threaded_world_is_the_same_as_the_direct_one() -> void:
	var data := GameData.get_default()
	for seed_value: int in [1840, 5, 777]:
		var direct := ArchipelagoGenerator.new_world(seed_value, _config, data)
		var job := ArchipelagoJob.new(seed_value, _config, data)
		job.start(true)
		job.wait()
		var threaded := job.result()
		assert_that(_fingerprints(threaded)).is_equal(_fingerprints(direct))
		assert_str(var_to_str(threaded.to_dict())).override_failure_message("semente %d" % seed_value) \
				.is_equal(var_to_str(direct.to_dict()))
		# e sem thread (o caminho dos testes e do modo direto da cortina)
		var serial := ArchipelagoJob.new(seed_value, _config, data)
		serial.start(false)
		assert_str(var_to_str(serial.result().to_dict())).is_equal(var_to_str(direct.to_dict()))


func test_progress_only_goes_up_to_one() -> void:
	var job := ArchipelagoJob.new(1840, _config, GameData.get_default())
	assert_float(job.progress()).is_equal(0.0)
	assert_bool(job.poll()).is_false()
	job.start(true)
	var last := 0.0
	var steps := 0
	while not job.poll():
		assert_float(job.progress()).is_greater_equal(last)
		last = job.progress()
		OS.delay_msec(2)
		steps += 1
		assert_int(steps).is_less(20000)
	assert_float(job.progress()).is_equal(1.0)
	assert_int(job.island_count()).is_equal(5)
	# o resultado é o mesmo objeto a cada chamada
	assert_object(job.result()).is_same(job.result())


func test_the_size_and_difficulty_reach_the_world() -> void:
	var data := GameData.get_default()
	var config := GameConfig.get_default()
	var job := ArchipelagoJob.new(42, config, data, 0, 2)
	job.start(true)
	job.wait()
	var world := job.result()
	var direct := ArchipelagoGenerator.new_world(42, config, data, 0, 2)
	assert_int(world.islands.size()).is_equal(direct.islands.size())
	assert_int(world.difficulty).is_equal(2)
	assert_float(world.money).is_equal(direct.money)
