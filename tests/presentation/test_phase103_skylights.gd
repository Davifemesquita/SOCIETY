extends GdUnitTestSuite
## Claraboias (Fase 103): as fábricas grandes sem silhueta têm uma fileira de vidraças em cada água (ou na abóbada),
## assentadas no telhado e viradas para o céu; elas entram na lista das janelas que acendem à noite; os outros prédios
## não têm.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _spec(id: StringName) -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, BuildingRecord.new(5, id, 0, Vector2i(10, 10), 0), 2.0)


func test_who_gets_skylights() -> void:
	for id: StringName in [&"bakery", &"weavery", &"lamp_factory", &"sewing_machine_factory"]:
		assert_bool(_spec(id).skylights).override_failure_message(String(id)).is_true()
	# fazenda pequena, mina (telhado plano), silhueta própria, serviço e casa: sem
	for id: StringName in [&"lumberjack", &"iron_mine", &"brewery", &"furnace", &"church", &"market"]:
		assert_bool(_spec(id).skylights).override_failure_message(String(id)).is_false()


func test_the_panes_sit_on_the_roof_and_face_the_sky() -> void:
	for id: StringName in [&"bakery", &"weavery"]:
		var spec := _spec(id)
		var panes := BuildingKit.skylight_panes(spec)
		assert_int(panes.size()).override_failure_message(String(id)).is_greater_equal(4)
		var size := spec.size_m()
		var sides := {}
		for pane: Transform3D in panes:
			var normal := pane.basis.z.normalized()
			assert_float(normal.y).override_failure_message(String(id)).is_greater(0.3)
			# acima das paredes, abaixo da cumeeira, dentro da planta
			assert_float(pane.origin.y).is_greater(spec.height_m)
			assert_float(pane.origin.y).is_less(spec.height_m + spec.roof_m + 0.2)
			assert_float(absf(pane.origin.x)).is_less(size.x * 0.5)
			assert_float(absf(pane.origin.z)).is_less(size.y * 0.5)
			sides[signf(normal.z if spec.roof == BuildingKit.Roof.GABLE_X else normal.x)] = true
		# uma fileira em cada água
		assert_int(sides.size()).is_equal(2)


func test_the_panes_light_up_with_the_windows() -> void:
	var spec := _spec(&"bakery")
	var panes := BuildingKit.skylight_panes(spec)
	var windows := BuildingKit.windows(spec)
	for pane: Transform3D in panes:
		assert_bool(windows.has(pane)).is_true()
	var plain := spec._copy()
	plain.skylights = false
	assert_int(windows.size() - BuildingKit.windows(plain).size()).is_equal(panes.size())
	assert_int(BuildingKit.skylight_panes(plain).size()).is_equal(0)
