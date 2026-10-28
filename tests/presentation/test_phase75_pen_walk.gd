extends GdUnitTestSuite
## Bichos no cercado (Fase 75): no zoológico, os bichos andam dentro do cercado (descansam, viram no lugar e andam até
## um ponto), sem a pegada do corpo passar da cerca em nenhum momento; as araras ficam no poleiro e as peças do museu
## paradas; o bicho segue o passeio quando outra peça entra. Só apresentação.

const STREET := 20

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _zoo_spec() -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, BuildingRecord.new(5, &"zoo", 0, Vector2i(10, 10), 0), 2.0)


func test_every_walking_animal_stays_inside_its_pen() -> void:
	var half := BuildingKit.pen_half(_zoo_spec())
	for exhibit_id: StringName in ExhibitModels.FACING:
		var full := ExhibitModels.footprint(exhibit_id)
		assert_float(full.size.y).override_failure_message(String(exhibit_id)).is_greater(0.5)
		var fit := PenWalk.fit_scale(half, full)
		assert_float(fit).override_failure_message(String(exhibit_id)).is_between(0.5, 1.0)
		var body := Rect2(full.position * fit, full.size * fit)
		var walk := PenWalk.new(half, body, 7, ExhibitModels.FACING[exhibit_id])
		assert_bool(walk.still).override_failure_message(String(exhibit_id) + " não cabe").is_false()
		var start := walk.position
		var farthest := 0.0
		var turned := 0.0
		var last_heading := walk.heading
		for frame: int in 3000:
			walk.advance(0.1)
			assert_bool(walk.fits(walk.position, walk.heading)).override_failure_message(String(exhibit_id)).is_true()
			farthest = maxf(farthest, walk.position.distance_to(start))
			turned += absf(angle_difference(last_heading, walk.heading))
			last_heading = walk.heading
		# em cinco minutos de jogo, todos viram e andam de verdade
		assert_float(turned).override_failure_message(String(exhibit_id)).is_greater(2.0)
		assert_float(farthest).override_failure_message(String(exhibit_id)).is_greater(0.25)
	# só o elefante precisa ficar menor; o leão cabe do tamanho dele
	assert_float(PenWalk.fit_scale(half, ExhibitModels.footprint(&"elephant"))).is_less(0.8)
	assert_float(PenWalk.fit_scale(half, ExhibitModels.footprint(&"lion"))).is_equal(1.0)
	assert_bool(ExhibitModels.roams(&"parrots")).is_false()
	assert_bool(ExhibitModels.roams(&"amphora")).is_false()


func test_the_footprint_faces_forward() -> void:
	# desfeito o giro da malha, o bicho fica comprido em z (de frente para -Z), e a cabeça vai mais longe que o rabo
	for exhibit_id: StringName in [&"giraffe", &"lion", &"tiger"]:
		var body := ExhibitModels.footprint(exhibit_id)
		assert_float(body.size.y).override_failure_message(String(exhibit_id)).is_greater(body.size.x)
		assert_float(-body.position.y).override_failure_message(String(exhibit_id)).is_greater(body.end.y)


func test_a_pen_that_is_too_small_keeps_the_animal_still() -> void:
	var walk := PenWalk.new(Vector2(0.5, 0.5), ExhibitModels.footprint(&"elephant"), 3, 0.0)
	assert_bool(walk.still).is_true()
	walk.advance(60.0)
	assert_vector(walk.position).is_equal(Vector2.ZERO)


func test_animals_walk_in_the_zoo_and_keep_walking_when_another_comes() -> void:
	SimFixture.road(_sim, Vector2i(0, STREET), Vector2i(119, STREET))
	var zoo_id := SimFixture.place(_sim, &"zoo", Vector2i(10, STREET + 1), 0)
	var museum_id := SimFixture.place(_sim, &"museum", Vector2i(20, STREET + 1), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	for exhibit_id: StringName in [&"lion", &"parrots"]:
		assert_bool(_sim.execute(PlaceExhibitCommand.new(exhibit_id, zoo_id)).ok()).is_true()
	assert_bool(_sim.execute(PlaceExhibitCommand.new(&"amphora", museum_id)).ok()).is_true()
	assert_object(view.exhibit_walk(zoo_id, &"parrots")).is_null()
	assert_object(view.exhibit_walk(museum_id, &"amphora")).is_null()
	var walk := view.exhibit_walk(zoo_id, &"lion")
	assert_object(walk).is_not_null()
	var lion_body: Node3D = null
	for item: Node3D in view.exhibit_nodes(zoo_id):
		if item.name == &"lion":
			lion_body = item.get_node(^"Body") as Node3D
	assert_object(lion_body).is_not_null()
	var start := lion_body.transform
	view.walk_animals(120.0)
	assert_bool(lion_body.transform.is_equal_approx(start)).is_false()
	assert_vector(Vector2(lion_body.position.x, lion_body.position.z)).is_equal_approx(walk.position, Vector2(0.001, 0.001))
	# o jogo pausado não mexe ninguém
	var paused := lion_body.transform
	view.walk_animals(0.0)
	assert_bool(lion_body.transform.is_equal_approx(paused)).is_true()
	# outra peça entra (as vagas são refeitas, o leão pode mudar de cercado): o passeio dele segue o mesmo
	assert_bool(_sim.execute(PlaceExhibitCommand.new(&"giraffe", zoo_id)).ok()).is_true()
	assert_object(view.exhibit_walk(zoo_id, &"lion")).is_same(walk)
	assert_object(view.exhibit_walk(zoo_id, &"giraffe")).is_not_null()
	_sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(10, STREET + 1), Vector2i(6, 6))))
	assert_object(view.exhibit_walk(zoo_id, &"lion")).is_null()
