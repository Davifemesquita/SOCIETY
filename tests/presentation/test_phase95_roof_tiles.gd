extends GdUnitTestSuite
## Telhado de telhas (Fase 95): a capa redonda na cumeeira e nos espigões, o beiral redondo, na célula de acabamento da
## paleta (as telhas do shader ficam só nas águas); o telhado plano não ganha nada disso.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _spec(def_id: StringName, roof: BuildingKit.Roof) -> BuildingKit.Spec:
	var spec := BuildingKit.spec_for(_sim, BuildingRecord.new(5, def_id, 0, Vector2i(10, 10), 0), 2.0)
	spec.roof = roof
	spec.lucarnes = 0
	return spec


## Os vértices do modelo com a UV da célula (1, 3) da paleta (o acabamento do telhado).
func _trim_points(mesh: Mesh) -> PackedVector3Array:
	var found := PackedVector3Array()
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i: int in uvs.size():
			var cell := Vector2i(floori(uvs[i].x * 8.0), floori(uvs[i].y * 4.0))
			if cell == Vector2i(1, 3):
				found.append(vertices[i])
	return found


func test_the_rod_is_round() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	BuildingKit._rod(tool, Vector3(-1.0, 2.0, 0.0), Vector3(1.0, 2.0, 0.0), 0.2, 6, BuildingKit.UV_ROOF_TRIM)
	var arrays := tool.commit_to_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	# seis faces, dois triângulos cada
	assert_int(vertices.size()).is_equal(6 * 6)
	for i: int in vertices.size():
		# na superfície (a 0,2 m do eixo) e com a normal para fora do eixo
		var radial := vertices[i] - Vector3(vertices[i].x, 2.0, 0.0)
		assert_float(radial.length()).is_equal_approx(0.2, 0.001)
		assert_float(normals[i].dot(radial.normalized())).is_greater(0.99)
	# a meia volta só tem a metade de cima
	tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	BuildingKit._rod(tool, Vector3(-1.0, 2.0, 0.0), Vector3(1.0, 2.0, 0.0), 0.2, 6, BuildingKit.UV_ROOF_TRIM, true)
	var half: PackedVector3Array = tool.commit_to_arrays()[Mesh.ARRAY_VERTEX]
	for point: Vector3 in half:
		assert_float(point.y).is_greater_equal(2.0 - 0.001)


func test_the_gable_gets_a_round_ridge_and_eaves() -> void:
	var spec := _spec(&"bakery", BuildingKit.Roof.GABLE_X)
	var trim := _trim_points(BuildingKit.mesh(spec))
	assert_int(trim.size()).is_greater(0)
	var ridge := spec.height_m + spec.roof_m
	var highest := -INF
	var lowest := INF
	for point: Vector3 in trim:
		highest = maxf(highest, point.y)
		lowest = minf(lowest, point.y)
	# a capa passa da cumeeira; o beiral fica embaixo, na altura da borda das águas
	assert_float(highest).is_greater(ridge + BuildingKit.RIDGE_CAP_M)
	assert_float(lowest).is_less(spec.height_m)


func test_the_hip_gets_round_hips_and_the_flat_roof_nothing() -> void:
	assert_int(_trim_points(BuildingKit.mesh(_spec(&"bakery", BuildingKit.Roof.HIP))).size()).is_greater(0)
	assert_int(_trim_points(BuildingKit.mesh(_spec(&"bakery", BuildingKit.Roof.FLAT))).size()).is_equal(0)
