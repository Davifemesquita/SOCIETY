extends GdUnitTestSuite
## Morcegos ao anoitecer (Fase 229): só a igreja tem o bando; eles voam em volta da sineira, dentro da faixa de raio e altura,
## sem saltos; batem as asas sem parar; aparecem só com a noite.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func test_the_flight_circles_the_tower_smoothly() -> void:
	var tower := Vector3(50.0, 14.0, 30.0)
	for k: int in BatView.FLOCK:
		var seed_value := k * 1.37 + 0.11
		var last := BatView.pose(tower, seed_value, 0.0).origin
		for step: int in range(1, 300):
			var at := BatView.pose(tower, seed_value, step * 0.05).origin
			var flat := Vector2(at.x - tower.x, at.z - tower.z).length()
			assert_float(flat).is_less_equal(BatView.RADIUS_M.y + BatView.ZIG_M + 0.01)
			assert_float(flat).is_greater_equal(BatView.RADIUS_M.x - BatView.ZIG_M - 0.01)
			assert_float(at.y - tower.y).is_between(BatView.HEIGHT_M.x - BatView.ZIG_M, BatView.HEIGHT_M.y + BatView.ZIG_M)
			# 0,05 s a até 8 m/s, mais o zigue-zague: menos de 1,2 m por passo
			assert_float(at.distance_to(last)).is_less(1.2)
			last = at


func test_they_never_glide() -> void:
	var still := 0
	for step: int in 400:
		if absf(BatView.beat(0.3, step * 0.031)) < 0.05:
			still += 1
	assert_int(still).is_less(60)


func test_only_the_church_has_bats_and_only_at_night() -> void:
	SimFixture.place(_sim, &"church", Vector2i(30, 10), 0)
	var view: BatView = auto_free(BatView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.bat_count()).is_equal(BatView.FLOCK)
	view.show_for_night(0.0)
	assert_bool(view.is_showing()).is_false()
	view.show_for_night(1.0)
	assert_bool(view.is_showing()).is_true()
	var box := BatView.bat_mesh().get_aabb()
	assert_float(box.size.x).is_between(0.3, 0.5)
