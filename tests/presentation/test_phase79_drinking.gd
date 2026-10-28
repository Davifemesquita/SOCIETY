extends GdUnitTestSuite
## O bicho vai beber (Fase 79): às vezes o bicho vai até o bebedouro do cercado, vira de frente para ele e fica bebendo
## um tempo, com o focinho perto da borda e sem tocar nele; no BuildingView, inclina para a frente enquanto bebe. Só
## apresentação.

const STREET := 20

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _half() -> Vector2:
	return BuildingKit.pen_half(BuildingKit.spec_for(_sim, BuildingRecord.new(5, &"zoo", 0, Vector2i(10, 10), 0), 2.0))


func _walk(exhibit_id: StringName, seed_value: int) -> PenWalk:
	var half := _half()
	var full := ExhibitModels.footprint(exhibit_id)
	var fit := PenWalk.fit_scale(half, full)
	return PenWalk.new(half, Rect2(full.position * fit, full.size * fit), seed_value, ExhibitModels.FACING[exhibit_id],
			ExhibitModels.trough_rect(half))


func test_animals_go_to_the_trough_and_drink_facing_it() -> void:
	var trough := ExhibitModels.trough_rect(_half())
	var drank: Array[StringName] = []
	for exhibit_id: StringName in ExhibitModels.FACING:
		var walk := _walk(exhibit_id, 5)
		var drinking_s := 0.0
		for frame: int in 6000:
			walk.advance(0.1)
			assert_bool(walk.fits(walk.position, walk.heading)).override_failure_message(String(exhibit_id)).is_true()
			if walk.drinking:
				drinking_s += 0.1
				# de frente para o bebedouro (olhando para +Z), com o focinho a DRINK_GAP_M da borda da frente dele
				assert_float(absf(angle_difference(walk.heading, PI))).is_less(0.01)
				var muzzle := walk.position.y - walk.footprint.position.y
				assert_float(muzzle).is_equal_approx(trough.position.y - PenWalk.DRINK_GAP_M, 0.01)
				assert_float(walk.position.x).is_equal_approx(trough.get_center().x, 0.01)
		if drinking_s > 0.0:
			drank.append(exhibit_id)
			# bebe um bom tempo, mas não fica só bebendo em dez minutos
			assert_float(drinking_s).override_failure_message(String(exhibit_id)).is_greater(PenWalk.DRINK_MIN_S)
			assert_float(drinking_s).override_failure_message(String(exhibit_id)).is_less(400.0)
	print("foram beber: ", drank)
	# os que cabem de frente para o bebedouro vão beber (o leão e o tigre, pelo menos)
	for exhibit_id: StringName in [&"lion", &"tiger"]:
		assert_bool(drank.has(exhibit_id)).override_failure_message("%s não foi beber" % exhibit_id).is_true()


func test_no_trough_no_drinking() -> void:
	var half := _half()
	var full := ExhibitModels.footprint(&"lion")
	var walk := PenWalk.new(half, full, 5, ExhibitModels.FACING[&"lion"])
	assert_vector(walk.drink_spot()).is_equal(Vector2.INF)
	for frame: int in 3000:
		walk.advance(0.1)
		assert_bool(walk.drinking).is_false()


func test_the_drinking_animal_leans_forward_in_the_zoo() -> void:
	SimFixture.road(_sim, Vector2i(0, STREET), Vector2i(119, STREET))
	var zoo_id := SimFixture.place(_sim, &"zoo", Vector2i(10, STREET + 1), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	assert_bool(_sim.execute(PlaceExhibitCommand.new(&"lion", zoo_id)).ok()).is_true()
	var walk := view.exhibit_walk(zoo_id, &"lion")
	var body: Node3D = null
	for item: Node3D in view.exhibit_nodes(zoo_id):
		if item.name == &"lion":
			body = item.get_node(^"Body") as Node3D
	var leaned := false
	var upright := false
	for step: int in 3000:
		view.walk_animals(0.2)
		# a frente do bicho (a cabeça) desce bebendo e fica no nível andando
		var facing: float = ExhibitModels.FACING[&"lion"]
		var forward := body.basis * (Basis(Vector3.UP, facing) * Vector3.FORWARD)
		if walk.drinking:
			assert_float(forward.normalized().y).is_less(-0.05)
			leaned = true
		else:
			assert_float(absf(forward.normalized().y)).is_less(0.001)
			upright = true
		# a escala do cercado continua
		assert_float(body.basis.get_scale().x).is_equal_approx(PenWalk.fit_scale(_half(), ExhibitModels.footprint(&"lion")), 0.001)
	assert_bool(leaned).override_failure_message("o leão não foi beber").is_true()
	assert_bool(upright).is_true()
