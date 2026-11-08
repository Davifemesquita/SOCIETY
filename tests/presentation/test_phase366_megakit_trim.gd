extends GdUnitTestSuite
## Fase 366: com o MegaKit, a empena no reboco do pacote, os cunhais na cantaria dele e os postigos cabendo na célula.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()


func after_test() -> void:
	BuildingKit.reset_megakit()


func _spec(tier: StringName, id: int = 7) -> BuildingKit.Spec:
	var record := BuildingRecord.new(id, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


## Uma casa da classe com telhado de duas águas (sem mansarda nem abóbada nem ala), procurando pelo id.
func _gabled(tier: StringName) -> BuildingKit.Spec:
	for id: int in range(1, 200):
		var spec := _spec(tier, id)
		var gable := spec.roof == BuildingKit.Roof.GABLE_X or spec.roof == BuildingKit.Roof.GABLE_Z
		if gable and not spec.mansard and not spec.vault and spec.wing == 0 and spec.court_rows == 0:
			return spec
	return null


## Vértices na camada "layer" do MegaKit (UV2.x = camada + 1) acima de "above" metros.
func _layer_vertices(mesh: Mesh, layer: int, above: float = -100.0) -> int:
	var count := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		if not arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			continue
		var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i: int in vertices.size():
			if absf(uv2[i].x - (layer + 1.0)) < 0.25 and vertices[i].y > above:
				count += 1
	return count


func test_the_gable_takes_the_plaster_of_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	var spec := _gabled(&"workers")
	assert_object(spec).is_not_null()
	var mesh := BuildingKit.mesh(spec)
	# acima do alto das paredes só fica a ponta de cada empena (as peças de parede acabam nele)
	assert_int(_layer_vertices(mesh, 0, spec.height_m + 0.2)).is_greater_equal(2)


func test_the_kenney_gable_has_no_megakit_layer() -> void:
	BuildingKit.use_megakit(false)
	var spec := _gabled(&"workers")
	assert_int(_layer_vertices(BuildingKit.mesh(spec), 0, spec.height_m + 0.2)).is_equal(0)


func test_the_quoins_take_the_stone_of_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	var spec := _spec(&"artisans")
	assert_bool(spec.hall().quoins).is_true()
	# cada bloco: seis faces de dois triângulos
	assert_int(_layer_vertices(BuildingKit.mesh(spec), 4)).is_greater_equal(36 * 4)


func test_the_shutters_fit_in_the_cell() -> void:
	BuildingKit.use_megakit(true)
	for tier: StringName in [&"peasants", &"workers", &"artisans"]:
		var hall := _spec(tier).hall()
		var size := hall.size_m()
		for face: int in 4:
			var along_x := face % 2 == 0
			var count := hall.cells.x if along_x else hall.cells.y
			var step := (size.x if along_x else size.y) / count
			var span := step * BuildingKit.opening(hall, face).x
			for index: int in count:
				for side: float in [-1.0, 1.0]:
					var width := BuildingKit.shutter_leaf(hall, face, index, side)
					if width <= 0.0:
						continue
					assert_float(width).is_greater_equal(BuildingKit.SHUTTER_MIN_M)
					var outer := span * 0.5 + BuildingKit.SHUTTER_GAP_M + BuildingKit.MEGAKIT_FRAME_M + width
					assert_float(outer).override_failure_message("%s %d %d" % [tier, face, index]) \
							.is_less_equal(step * 0.5 + 0.001)


func test_no_shutter_over_a_quoin() -> void:
	BuildingKit.use_megakit(true)
	var hall := _spec(&"artisans").hall()
	assert_bool(hall.quoins).is_true()
	var size := hall.size_m()
	var count := hall.cells.x
	var step := size.x / count
	var span := step * BuildingKit.opening(hall, 0).x
	var width := BuildingKit.shutter_leaf(hall, 0, 0, -1.0)
	if width > 0.0:
		var outer := span * 0.5 + BuildingKit.SHUTTER_GAP_M + BuildingKit.MEGAKIT_FRAME_M + width
		assert_float(outer).is_less_equal(step * 0.5 - BuildingKit.QUOIN_LONG_M + 0.001)
