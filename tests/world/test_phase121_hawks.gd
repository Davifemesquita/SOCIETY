extends GdUnitTestSuite
## Gavião sobre a cidade (Fase 121): só na ilha com MIN_HOUSES casas, mais um a cada HOUSES_PER_HAWK; ele circula alto,
## dentro da faixa de raio e altura, sem saltos, e plana quase o tempo todo.

var _sim: Simulation
var _placed := 0


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true
	_placed = 0


func _houses(count: int) -> void:
	for k: int in count:
		var i := _placed
		_placed += 1
		SimFixture.place(_sim, &"house", Vector2i(4 + (i % 25) * 4, 4 + (i / 25) * 6))


func test_a_hawk_only_over_a_town() -> void:
	_houses(HawkView.MIN_HOUSES - 1)
	assert_int(HawkView.centers(_sim.world).size()).is_equal(0)
	_houses(1)
	assert_int(HawkView.centers(_sim.world).size()).is_equal(1)


func test_more_hawks_over_a_big_town() -> void:
	_houses(HawkView.HOUSES_PER_HAWK + 2)
	assert_int(HawkView.centers(_sim.world).size()).is_equal(2)


func test_the_flight_stays_high_and_smooth() -> void:
	var center := Vector3(50.0, 2.0, 30.0)
	var seed_value := 1.23
	var last := HawkView.pose(center, seed_value, 0.0).origin
	for step: int in range(1, 600):
		var at := HawkView.pose(center, seed_value, step * 0.1).origin
		var flat := Vector2(at.x - center.x, at.z - center.z).length()
		assert_float(flat).is_less_equal(HawkView.RADIUS_M.y + HawkView.DRIFT_M * 1.5)
		assert_float(at.y - center.y).is_between(HawkView.HEIGHT_M.x - HawkView.BOB_M - 0.01,
				HawkView.HEIGHT_M.y + HawkView.BOB_M + 0.01)
		# 0,1 s a ~7 m/s, mais a deriva: menos de 1,5 m por passo
		assert_float(at.distance_to(last)).is_less(1.5)
		last = at


func test_it_glides_most_of_the_time() -> void:
	var gliding := 0
	for step: int in 1000:
		if is_equal_approx(HawkView.beat(0.7, step * 0.1), HawkView.GLIDE):
			gliding += 1
	assert_int(gliding).is_greater(700)


func test_the_view_draws_one_per_center() -> void:
	_houses(HawkView.MIN_HOUSES)
	var view: HawkView = auto_free(HawkView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.hawk_count()).is_equal(1)
