extends GdUnitTestSuite
## Boca do forno (Fase 137): as fábricas de forno ganham a boca numa fachada do lado, no térreo, sem bater em janela; as
## outras não; o fogo acende só com a fábrica produzindo.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func test_the_mouth_sits_on_a_side_wall_on_the_ground_floor() -> void:
	for def_id: StringName in FurnaceGlowView.FURNACES:
		for rotation: int in 4:
			var sim := SimFixture.simulation()
			sim.free_build = true
			var id := SimFixture.place(sim, def_id, Vector2i(20, 10), rotation)
			var record := sim.world.building(id)
			var place: Variant = FurnaceGlowView.mouth(sim, record)
			assert_bool(place is Transform3D).is_true()
			var mouth: Transform3D = place
			var out := mouth.basis.z.normalized()
			var front := Footprint.front_direction(rotation)
			# de lado: para fora, perpendicular à frente
			assert_float(absf(out.dot(Vector3(front.x, 0.0, front.y)))).is_less(0.01)
			assert_float(absf(out.y)).is_less(0.01)
			var grid := sim.world.island(0)
			var area := Footprint.rect(record.origin, sim.def_of(record).size, rotation)
			var lot := Rect2(grid.origin_m + Vector2(area.position) * grid.cell_size, Vector2(area.size) * grid.cell_size)
			assert_bool(lot.grow(0.01).has_point(Vector2(mouth.origin.x, mouth.origin.z))).is_true()
			# no chão do prédio
			assert_float(mouth.origin.y).is_equal_approx(BuildingKit.seat(grid, area).y, 0.01)


func test_the_mouth_never_hits_a_window() -> void:
	for def_id: StringName in FurnaceGlowView.FURNACES:
		var id := SimFixture.place(_sim, def_id, Vector2i(20 + FurnaceGlowView.FURNACES.find(def_id) * 8, 10))
		var record := _sim.world.building(id)
		var mouth: Transform3D = FurnaceGlowView.mouth(_sim, record)
		var top := mouth.origin.y + FurnaceGlowView.HEARTH_M + FurnaceGlowView.SPRING_M + FurnaceGlowView.HALF_W \
				+ FurnaceGlowView.SURROUND_M
		for window: Transform3D in WindowLightsView.building_windows(_sim, record):
			var apart := Vector2(window.origin.x - mouth.origin.x, window.origin.z - mouth.origin.z).length()
			if apart < 0.6:
				var bottom := window.origin.y - window.basis.y.length() * 0.5
				assert_float(bottom).is_greater(top)


func test_other_buildings_have_no_furnace_mouth() -> void:
	SimFixture.place(_sim, &"lumberjack", Vector2i(20, 10))
	SimFixture.place(_sim, &"house", Vector2i(30, 10))
	var view: FurnaceGlowView = auto_free(FurnaceGlowView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.mouth_count()).is_equal(0)


func test_the_fire_burns_only_while_producing() -> void:
	var id := SimFixture.place(_sim, &"furnace", Vector2i(20, 10))
	SimFixture.place(_sim, &"bakery", Vector2i(40, 10))
	var record := _sim.world.building(id)
	var view: FurnaceGlowView = auto_free(FurnaceGlowView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.mouth_count()).is_equal(2)
	record.state = BuildingRecord.State.PRODUCING
	view.refresh_state()
	assert_int(view.lit_count()).is_equal(1)
	record.paused = true
	view.refresh_state()
	assert_int(view.lit_count()).is_equal(0)
	record.paused = false
	record.state = BuildingRecord.State.NO_INPUT
	assert_bool(FurnaceGlowView.burning(record)).is_false()
