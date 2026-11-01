extends GdUnitTestSuite
## Andorinhas no campanário (Fase 218): só a igreja (o campanário) tem o bando; elas voam em volta da sineira, dentro da faixa
## de raio e altura, rápidas mas sem saltos, acima do beiral da igreja; batem as asas em rajadas e planam no resto.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_only_the_church_tower_has_swallows() -> void:
	SimFixture.place(_sim, &"school", Vector2i(10, 10), 0)
	assert_int(SwallowView.towers(_sim).size()).is_equal(0)
	var id := SimFixture.place(_sim, &"church", Vector2i(30, 10), 0)
	var towers := SwallowView.towers(_sim)
	assert_int(towers.size()).is_equal(1)
	# a sineira fica acima do beiral, dentro da área da igreja
	var record := _sim.world.building(id)
	var grid := _sim.world.island(0)
	var def := _sim.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	assert_float(towers[0].y).is_greater(def.height_m)
	assert_bool(area.grow(1).has_point(grid.world_to_cell(towers[0]))).is_true()


func test_the_flight_circles_the_tower_smoothly() -> void:
	var tower := Vector3(50.0, 14.0, 30.0)
	for k: int in SwallowView.FLOCK:
		var seed_value := k * 1.618 + 0.37
		var last := SwallowView.pose(tower, seed_value, 0.0).origin
		for step: int in range(1, 300):
			var at := SwallowView.pose(tower, seed_value, step * 0.05).origin
			var flat := Vector2(at.x - tower.x, at.z - tower.z).length()
			assert_float(flat).is_less_equal(SwallowView.RADIUS_M.y + 0.01)
			assert_float(flat).is_greater(SwallowView.RADIUS_M.x * 0.6)
			var reach := SwallowView.WAVE_M + SwallowView.RADIUS_M.y * SwallowView.TILT * 0.5 + 0.01
			assert_float(at.y - tower.y).is_between(SwallowView.HEIGHT_M.x - reach, SwallowView.HEIGHT_M.y + reach)
			# 0,05 s a até 12 m/s, mais a onda: menos de 1 m por passo
			assert_float(at.distance_to(last)).is_less(1.0)
			last = at


func test_they_flap_in_bursts() -> void:
	var gliding := 0
	for step: int in 1000:
		if is_equal_approx(SwallowView.beat(0.7, step * 0.05), SwallowView.GLIDE):
			gliding += 1
	assert_int(gliding).is_between(300, 800)


func test_the_view_draws_a_flock_per_tower() -> void:
	SimFixture.place(_sim, &"church", Vector2i(30, 10), 0)
	var view: SwallowView = auto_free(SwallowView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.tower_count()).is_equal(1)
	assert_int(view.swallow_count()).is_equal(SwallowView.FLOCK)
	var box := SwallowView.swallow_mesh().get_aabb()
	assert_float(box.size.x).is_between(0.3, 0.4)
