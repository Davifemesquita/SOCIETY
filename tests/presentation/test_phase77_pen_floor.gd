extends GdUnitTestSuite
## Chão e bebedouro no cercado (Fase 77): cada cercado ocupado do zoológico ganha o chão do bicho (areia, capim seco ou
## capim verde) e um bebedouro encostado na cerca de trás, e o bicho passeia sem pisar no bebedouro; o museu não ganha
## nada disso. Só apresentação.

const STREET := 20

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _half() -> Vector2:
	return BuildingKit.pen_half(BuildingKit.spec_for(_sim, BuildingRecord.new(5, &"zoo", 0, Vector2i(10, 10), 0), 2.0))


func test_the_pen_floor_and_trough_fit_inside_the_fence() -> void:
	var half := _half()
	var trough := ExhibitModels.trough_rect(half)
	# encostado na cerca de trás, inteiro dentro do cercado
	assert_float(trough.end.y).is_less_equal(half.y)
	assert_float(trough.end.y).is_greater(half.y - 0.3)
	assert_float(trough.position.x).is_greater(-half.x)
	assert_float(trough.end.x).is_less_equal(half.x)
	for exhibit_id: StringName in [&"elephant", &"giraffe", &"lion", &"parrots"]:
		var made := ExhibitModels.pen_dressing(exhibit_id, half) as ArrayMesh
		var box := made.get_aabb()
		assert_float(box.position.x).is_greater_equal(-half.x)
		assert_float(box.end.x).is_less_equal(half.x)
		assert_float(box.position.z).is_greater_equal(-half.y)
		assert_float(box.end.z).is_less_equal(half.y)
		# o bebedouro no chão, com a água rente à borda; o chão um pouco acima do pátio, virado para cima
		assert_float(box.position.y).is_equal_approx(0.0, 0.001)
		assert_float(box.end.y).is_equal_approx(ExhibitModels.TROUGH_M.y, 0.001)
		var vertices: PackedVector3Array = made.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		assert_float(vertices[0].y).is_equal_approx(ExhibitModels.PEN_FLOOR_Y, 0.001)
		var normals: PackedVector3Array = made.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
		assert_float(normals[0].y).override_failure_message("o chão virado para baixo").is_greater(0.9)
		assert_object(ExhibitModels.pen_dressing(exhibit_id, half)).is_same(made)
	# cada bicho no chão dele: a areia dos grandes felinos não é o capim da girafa
	var sand: PackedColorArray = (ExhibitModels.pen_dressing(&"lion", half) as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var grass: PackedColorArray = (ExhibitModels.pen_dressing(&"giraffe", half) as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert_float(sand[0].r).is_greater(grass[0].r)


func test_animals_never_step_into_the_trough() -> void:
	var half := _half()
	var trough := ExhibitModels.trough_rect(half)
	for exhibit_id: StringName in ExhibitModels.FACING:
		var full := ExhibitModels.footprint(exhibit_id)
		var fit := PenWalk.fit_scale(half, full)
		var walk := PenWalk.new(half, Rect2(full.position * fit, full.size * fit), 11, ExhibitModels.FACING[exhibit_id],
				trough)
		assert_bool(walk.still).override_failure_message(String(exhibit_id)).is_false()
		var start := walk.position
		var farthest := 0.0
		for frame: int in 3000:
			walk.advance(0.1)
			assert_bool(walk.fits(walk.position, walk.heading)).override_failure_message(String(exhibit_id)).is_true()
			farthest = maxf(farthest, walk.position.distance_to(start))
		assert_float(farthest).override_failure_message(String(exhibit_id)).is_greater(0.25)
	# o teste dos eixos: um corpo em cima do bebedouro bate, um longe dele não, e o caminho que cruza o bebedouro bate
	var walk := PenWalk.new(half, Rect2(-0.2, -0.4, 0.4, 0.8), 1, 0.0, trough)
	assert_bool(walk.fits(trough.get_center(), 0.0)).is_false()
	assert_bool(walk.fits(Vector2(-half.x * 0.5, 0.0), 0.0)).is_true()
	var left := Vector2(trough.position.x - 0.6, trough.get_center().y - 0.1)
	var right := Vector2(trough.end.x + 0.3, trough.get_center().y - 0.1)
	assert_bool(walk.path_clear(left, right, -PI * 0.5)).is_false()
	assert_bool(walk.path_clear(Vector2(-1.0, -1.0), Vector2(0.5, -1.0), -PI * 0.5)).is_true()


func test_occupied_pens_get_their_floor_and_the_museum_does_not() -> void:
	SimFixture.road(_sim, Vector2i(0, STREET), Vector2i(119, STREET))
	var zoo_id := SimFixture.place(_sim, &"zoo", Vector2i(10, STREET + 1), 0)
	var museum_id := SimFixture.place(_sim, &"museum", Vector2i(20, STREET + 1), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	for exhibit_id: StringName in [&"lion", &"parrots"]:
		assert_bool(_sim.execute(PlaceExhibitCommand.new(exhibit_id, zoo_id)).ok()).is_true()
	assert_bool(_sim.execute(PlaceExhibitCommand.new(&"amphora", museum_id)).ok()).is_true()
	for item: Node3D in view.exhibit_nodes(zoo_id):
		var pen := item.get_node_or_null(^"Pen") as MeshInstance3D
		assert_object(pen).override_failure_message(String(item.name)).is_not_null()
		assert_object(pen.mesh).is_same(ExhibitModels.pen_dressing(StringName(item.name), _half()))
	assert_object(view.exhibit_walk(zoo_id, &"lion").blocked).is_equal(ExhibitModels.trough_rect(_half()))
	for item: Node3D in view.exhibit_nodes(museum_id):
		assert_object(item.get_node_or_null(^"Pen")).is_null()
