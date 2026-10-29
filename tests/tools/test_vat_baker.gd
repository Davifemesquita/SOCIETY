extends GdUnitTestSuite
## Gerador de VAT próprio (seção 14): skinning igual ao da placa, textura com um quadro por
## linha, redução de polígonos e os dois pedestres gerados dentro do orçamento.

const MODELS := ["res://assets/vat/pedestrian_male.res", "res://assets/vat/pedestrian_female.res"]


## Dois ossos (raiz e braço a 1 m de altura) e um quadrado: a metade de baixo segue a raiz e a
## de cima, o braço.
func _source() -> VatBaker.Source:
	var source := VatBaker.Source.new()
	source.bone_names = PackedStringArray(["root", "arm"])
	source.bone_parents = PackedInt32Array([-1, 0])
	source.bone_rest = [Transform3D.IDENTITY, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0))]
	source.bind_bones = PackedInt32Array([0, 1])
	source.bind_poses = [Transform3D.IDENTITY, Transform3D(Basis.IDENTITY, Vector3(0.0, -1.0, 0.0))]
	source.vertices = PackedVector3Array([Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0), Vector3(-0.5, 2, 0), Vector3(0.5, 2, 0)])
	source.normals = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	source.bones = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0])
	source.weights = PackedFloat32Array([1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0])
	source.indices = PackedInt32Array([0, 2, 1, 1, 2, 3])
	return source


## O braço gira 90° em z ao longo de 1 s.
func _bend() -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	var track := animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.track_set_path(track, NodePath("Armature/Skeleton3D:arm"))
	animation.rotation_track_insert_key(track, 0.0, Quaternion.IDENTITY)
	animation.rotation_track_insert_key(track, 1.0, Quaternion(Vector3.BACK, PI / 2.0))
	return animation


func test_rest_pose_reproduces_the_mesh() -> void:
	var source := _source()
	var skinned := VatBaker.skin(source, VatBaker.pose(source, null, 0.0))
	for i: int in source.vertices.size():
		assert_vector(skinned[0][i]).is_equal_approx(source.vertices[i], Vector3.ONE * 0.0001)


func test_animated_bone_moves_only_its_vertices() -> void:
	var source := _source()
	var skinned := VatBaker.skin(source, VatBaker.pose(source, _bend(), 1.0))
	assert_vector(skinned[0][1]).is_equal_approx(Vector3(0.5, 0, 0), Vector3.ONE * 0.0001)
	# (0,5; 2) fica a (0,5; 1) do braço; girado 90° em z vira (−1; 0,5), mais o ombro em y = 1
	assert_vector(skinned[0][3]).is_equal_approx(Vector3(-1.0, 1.5, 0), Vector3.ONE * 0.0001)
	assert_vector(skinned[1][3]).is_equal_approx(Vector3.BACK, Vector3.ONE * 0.0001)


func test_bake_writes_one_row_per_frame_and_one_column_per_vertex() -> void:
	var source := _source()
	var clips: Array[VatBaker.ClipSource] = [VatBaker.ClipSource.new("bend", _bend(), false)]
	var model := VatBaker.bake(source, clips, 4.0)
	var positions := model.positions.get_image()
	assert_int(positions.get_width()).is_equal(4)
	assert_int(positions.get_height()).is_equal(4)
	assert_int(positions.get_format()).is_equal(Image.FORMAT_RGBAH)
	assert_bool(model.positions.get_image().has_mipmaps()).is_false()
	var top := positions.get_pixel(3, 2)
	# quadro 2 de 4 = meio segundo, 45°
	var expected := Vector3(0.0, 1.0, 0.0) + Vector3(0.5, 1.0, 0.0).rotated(Vector3.BACK, PI / 4.0)
	assert_vector(Vector3(top.r, top.g, top.b)).is_equal_approx(expected, Vector3.ONE * 0.002)
	var arrays := model.mesh.surface_get_arrays(0)
	var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	assert_array(Array(uv2).map(func(uv: Vector2) -> int: return int(uv.x))).is_equal([0, 1, 2, 3])
	assert_array(Array(model.clip_names)).is_equal(["bend"])
	assert_float(model.clip_strides_m[0]).is_equal(0.0)


func test_reduce_cuts_triangles_and_keeps_only_used_vertices() -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 64
	sphere.rings = 32
	var arrays := sphere.get_mesh_arrays()
	var source := VatBaker.Source.new()
	source.vertices = arrays[Mesh.ARRAY_VERTEX]
	source.normals = arrays[Mesh.ARRAY_NORMAL]
	source.indices = arrays[Mesh.ARRAY_INDEX]
	for i: int in source.vertices.size():
		source.bones.append_array(PackedInt32Array([0, 0, 0, 0]))
		source.weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
	var reduced := VatBaker.reduce(source, 1000)
	assert_int(reduced.triangle_count()).is_less_equal(1000)
	assert_int(reduced.triangle_count()).is_greater(100)
	var used := PackedByteArray()
	used.resize(reduced.vertices.size())
	for index: int in reduced.indices:
		used[index] = 1
	assert_int(used.count(0)).is_equal(0)
	assert_int(reduced.bones.size()).is_equal(reduced.vertices.size() * 4)


func test_baked_pedestrians_fit_the_polygon_budget_and_walk_forward() -> void:
	for path: String in MODELS:
		var model := load(path) as VatModel
		assert_object(model).is_not_null()
		# seção 14: pedestre de 1.000 a 3.000 triângulos
		assert_int(model.triangle_count).is_between(1000, 3000)
		assert_array(Array(model.clip_names)).is_equal(["walk", "walk_carry", "idle", "talk", "cheer"])
		assert_float(model.clip_strides_m[0]).is_between(0.8, 2.0)
		assert_float(model.clip_strides_m[2]).is_equal(0.0)
		var frames := 0
		for count: int in model.clip_frame_counts:
			frames += count
		assert_int(model.positions.get_height()).is_equal(frames)
		assert_int(model.positions.get_width()).is_equal(model.vertex_count)
		assert_int(model.positions.get_image().get_format()).is_equal(Image.FORMAT_RGBAH)
		# virado para −Z: o rosto (pele da cabeça) fica à frente do cabelo
		var arrays := model.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var face := Vector2.ZERO
		var hair := Vector2.ZERO
		for i: int in vertices.size():
			# só a cabeça: as mãos da pose de repouso também ficam no alto, mas longe do meio
			if vertices[i].y < 1.4 or absf(vertices[i].x) > 0.15:
				continue
			if int(uv[i].x) == VatModel.Region.SKIN:
				face += Vector2(vertices[i].z, 1.0)
			elif int(uv[i].x) == VatModel.Region.HAIR:
				hair += Vector2(vertices[i].z, 1.0)
		assert_float(face.y).is_greater(0.0)
		assert_float(hair.y).is_greater(0.0)
		assert_float(face.x / face.y).is_less(hair.x / hair.y)
