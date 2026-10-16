class_name VatBaker
extends RefCounted
## Gerador próprio de VAT (animação gravada em textura, seção 14). Substitui o OpenVAT, que pede
## o Blender e é GPL: aqui o personagem com esqueleto vira só arrays e matrizes, a malha é
## reduzida pelo gerador de LOD do próprio Godot, cada quadro das animações é calculado na CPU
## (skinning linear, o mesmo da placa de vídeo) e gravado numa linha da textura.
## Só ferramenta: o jogo carrega o VatModel pronto.

## Altura do quadro de referência usada para separar cabelo de rosto na cabeça (fração da
## altura da cabeça, de baixo para cima) e quanto atrás do centro da cabeça já é nuca.
const HAIR_HEIGHT_FRACTION := 0.68
const HAIR_BACK_HEIGHT_FRACTION := 0.42
const HAIR_BACK_OFFSET_M := 0.035
## Folga da caixa da malha: a animação tira o boneco da pose de repouso.
const AABB_MARGIN_M := 0.6
const SKIN_BONES := ["Head", "neck_01", "hand_l", "hand_r"]
const SKIN_PREFIXES := ["index_", "middle_", "pinky_", "ring_", "thumb_"]
const COAT_PREFIXES := ["spine_", "clavicle_", "upperarm_", "lowerarm_"]
const SHOE_PREFIXES := ["foot_", "ball_"]


## Personagem com esqueleto fora da árvore de cenas.
class Source:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	## Índice de bind (não de osso) e peso de cada influência; `influences` por vértice.
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var influences: int = 4
	var indices := PackedInt32Array()
	## Cor de cada vértice (a do material da superfície; Fase 13, animais). Vazio nos pedestres, que
	## pintam pela região do corpo.
	var colors := PackedColorArray()
	var bone_names := PackedStringArray()
	var bone_parents := PackedInt32Array()
	var bone_rest: Array[Transform3D] = []
	var bind_bones := PackedInt32Array()
	var bind_poses: Array[Transform3D] = []
	## Do espaço do esqueleto para o do personagem (nós acima do Skeleton3D).
	var to_root := Transform3D.IDENTITY

	func triangle_count() -> int:
		return indices.size() / 3

	func bone_index(bone_name: String) -> int:
		return bone_names.find(bone_name)


## Uma animação a gravar: nome no modelo, a Animation e se ela anda (passo medido nos pés).
class ClipSource:
	var name: String
	var animation: Animation
	var walks: bool

	func _init(clip_name: String, clip_animation: Animation, clip_walks: bool) -> void:
		name = clip_name
		animation = clip_animation
		walks = clip_walks


## Lê o esqueleto e as malhas nomeadas de uma cena gerada do glTF ou do FBX (ImporterMeshInstance3D ou
## MeshInstance3D), juntando todas as superfícies numa só. Com keep_colors, cada vértice guarda a cor
## do material da superfície dele.
static func from_scene(root: Node, mesh_names: PackedStringArray, keep_colors: bool = false) -> Source:
	var source := Source.new()
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return null
	var skeleton := skeletons[0] as Skeleton3D
	for bone: int in skeleton.get_bone_count():
		source.bone_names.append(skeleton.get_bone_name(bone))
		source.bone_parents.append(skeleton.get_bone_parent(bone))
		source.bone_rest.append(skeleton.get_bone_rest(bone))
	var node: Node = skeleton
	while node != null and node != root:
		if node is Node3D:
			var spatial: Node3D = node
			source.to_root = spatial.transform * source.to_root
		node = node.get_parent()
	var skin: Skin = null
	for found: Node in root.find_children("*", "", true, false):
		if not mesh_names.has(String(found.name)):
			continue
		if found is ImporterMeshInstance3D:
			var importer_node: ImporterMeshInstance3D = found
			skin = importer_node.skin
			for surface: int in importer_node.mesh.get_surface_count():
				_append_surface(source, importer_node.mesh.get_surface_arrays(surface),
						importer_node.mesh.get_surface_format(surface))
				if keep_colors:
					_append_color(source, importer_node.mesh.get_surface_material(surface))
		elif found is MeshInstance3D:
			var mesh_node: MeshInstance3D = found
			var array_mesh := mesh_node.mesh as ArrayMesh
			if array_mesh == null:
				continue
			skin = mesh_node.skin
			for surface: int in array_mesh.get_surface_count():
				_append_surface(source, array_mesh.surface_get_arrays(surface), array_mesh.surface_get_format(surface))
				if keep_colors:
					var material := mesh_node.get_surface_override_material(surface)
					_append_color(source, material if material != null else array_mesh.surface_get_material(surface))
	if skin == null or source.vertices.is_empty():
		return null
	for bind: int in skin.get_bind_count():
		var bone := skin.get_bind_bone(bind)
		if bone < 0:
			bone = skeleton.find_bone(skin.get_bind_name(bind))
		source.bind_bones.append(bone)
		source.bind_poses.append(skin.get_bind_pose(bind))
	return source


## Completa as cores até o último vértice com a cor do material (cinza sem material).
static func _append_color(source: Source, material: Material) -> void:
	var color := Color(0.6, 0.6, 0.6)
	if material is BaseMaterial3D:
		var base: BaseMaterial3D = material
		color = base.albedo_color
	while source.colors.size() < source.vertices.size():
		source.colors.append(color)


static func _append_surface(source: Source, arrays: Array, format: int) -> void:
	var influences := 8 if format & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS else 4
	if not source.vertices.is_empty() and influences != source.influences:
		push_error("VatBaker: superfícies com número diferente de influências")
		return
	source.influences = influences
	var offset := source.vertices.size()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	source.vertices.append_array(vertices)
	source.normals.append_array(normals)
	source.bones.append_array(bones)
	source.weights.append_array(weights)
	var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
	if raw_indices is PackedInt32Array:
		var indices: PackedInt32Array = raw_indices
		for index: int in indices:
			source.indices.append(index + offset)
	else:
		for index: int in vertices.size():
			source.indices.append(index + offset)


## Reduz a malha até perto de target_triangles com o gerador de LOD do Godot (meshoptimizer) e
## descarta os vértices que sobraram sem triângulo.
static func reduce(source: Source, target_triangles: int) -> Source:
	if source.triangle_count() <= target_triangles:
		return source
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = source.vertices
	arrays[Mesh.ARRAY_NORMAL] = source.normals
	arrays[Mesh.ARRAY_BONES] = source.bones
	arrays[Mesh.ARRAY_WEIGHTS] = source.weights
	arrays[Mesh.ARRAY_INDEX] = source.indices
	if not source.colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = source.colors
	var importer := ImporterMesh.new()
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if source.influences == 8 else 0
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, null, "", flags)
	importer.generate_lods(60.0, 25.0, [])
	var generated := importer.get_surface_arrays(0)
	var best := source.indices
	for lod: int in importer.get_surface_lod_count(0):
		var lod_indices := importer.get_surface_lod_indices(0, lod)
		if lod_indices.size() < best.size():
			best = lod_indices
		if lod_indices.size() / 3 <= target_triangles:
			best = lod_indices
			break
	var reduced := Source.new()
	reduced.influences = source.influences
	reduced.bone_names = source.bone_names
	reduced.bone_parents = source.bone_parents
	reduced.bone_rest = source.bone_rest
	reduced.bind_bones = source.bind_bones
	reduced.bind_poses = source.bind_poses
	reduced.to_root = source.to_root
	var vertices: PackedVector3Array = generated[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = generated[Mesh.ARRAY_NORMAL]
	var bones: PackedInt32Array = generated[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = generated[Mesh.ARRAY_WEIGHTS]
	var colors: PackedColorArray = generated[Mesh.ARRAY_COLOR] if not source.colors.is_empty() else PackedColorArray()
	var remap := PackedInt32Array()
	remap.resize(vertices.size())
	remap.fill(-1)
	for index: int in best:
		if remap[index] < 0:
			remap[index] = reduced.vertices.size()
			reduced.vertices.append(vertices[index])
			reduced.normals.append(normals[index])
			if not colors.is_empty():
				reduced.colors.append(colors[index])
			for k: int in source.influences:
				reduced.bones.append(bones[index * source.influences + k])
				reduced.weights.append(weights[index * source.influences + k])
		reduced.indices.append(remap[index])
	return reduced


## Pose global (espaço do esqueleto) de cada osso no instante time da animação. Osso sem trilha
## fica na pose de repouso.
static func pose(source: Source, animation: Animation, time: float) -> Array[Transform3D]:
	var count := source.bone_names.size()
	var positions: Array[Vector3] = []
	var rotations: Array[Quaternion] = []
	var scales: Array[Vector3] = []
	for bone: int in count:
		var rest := source.bone_rest[bone]
		positions.append(rest.origin)
		rotations.append(rest.basis.get_rotation_quaternion())
		scales.append(rest.basis.get_scale())
	if animation != null:
		for track: int in animation.get_track_count():
			var bone := source.bone_index(animation.track_get_path(track).get_concatenated_subnames())
			if bone < 0:
				continue
			match animation.track_get_type(track):
				Animation.TYPE_POSITION_3D:
					positions[bone] = animation.position_track_interpolate(track, time)
				Animation.TYPE_ROTATION_3D:
					rotations[bone] = animation.rotation_track_interpolate(track, time)
				Animation.TYPE_SCALE_3D:
					scales[bone] = animation.scale_track_interpolate(track, time)
	var globals: Array[Transform3D] = []
	globals.resize(count)
	var done := PackedByteArray()
	done.resize(count)
	for bone: int in count:
		_resolve(source, bone, positions, rotations, scales, globals, done)
	return globals


static func _resolve(source: Source, bone: int, positions: Array[Vector3], rotations: Array[Quaternion],
		scales: Array[Vector3], globals: Array[Transform3D], done: PackedByteArray) -> void:
	if done[bone] == 1:
		return
	var local := Transform3D(Basis(rotations[bone]) * Basis.from_scale(scales[bone]), positions[bone])
	var parent := source.bone_parents[bone]
	if parent >= 0:
		_resolve(source, parent, positions, rotations, scales, globals, done)
		globals[bone] = globals[parent] * local
	else:
		globals[bone] = local
	done[bone] = 1


## Posições e normais dos vértices numa pose (espaço do personagem): [PackedVector3Array, PackedVector3Array].
static func skin(source: Source, globals: Array[Transform3D]) -> Array[PackedVector3Array]:
	var matrices: Array[Transform3D] = []
	for bind: int in source.bind_bones.size():
		var bone := source.bind_bones[bind]
		matrices.append(source.to_root * (globals[bone] if bone >= 0 else Transform3D.IDENTITY) * source.bind_poses[bind])
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	positions.resize(source.vertices.size())
	normals.resize(source.vertices.size())
	var influences := source.influences
	for vertex: int in source.vertices.size():
		var position := Vector3.ZERO
		var normal := Vector3.ZERO
		var total := 0.0
		for k: int in influences:
			var weight := source.weights[vertex * influences + k]
			if weight <= 0.0:
				continue
			var matrix := matrices[source.bones[vertex * influences + k]]
			position += (matrix * source.vertices[vertex]) * weight
			normal += (matrix.basis * source.normals[vertex]) * weight
			total += weight
		if total <= 0.0:
			position = source.to_root * source.vertices[vertex]
			normal = source.to_root.basis * source.normals[vertex]
		elif not is_equal_approx(total, 1.0):
			position /= total
		positions[vertex] = position
		normals[vertex] = normal.normalized()
	return [positions, normals]


## Grava as animações num VatModel: a malha em repouso virada para −Z, as texturas de posição e
## de normal (uma linha por quadro) e o passo das animações que andam. Sem pés para medir (os
## animais), head_bone diz para onde o bicho olha: a cabeça na frente do quadril (Hips).
static func bake(source: Source, clips: Array[ClipSource], fps: float, head_bone: String = "") -> VatModel:
	var rest := skin(source, pose(source, null, 0.0))
	var frames_positions: Array[PackedVector3Array] = []
	var frames_normals: Array[PackedVector3Array] = []
	var model := VatModel.new()
	model.fps = fps
	var foot_tracks: Array[PackedVector3Array] = []
	for clip: ClipSource in clips:
		var frames := maxi(1, roundi(clip.animation.length * fps))
		model.clip_names.append(clip.name)
		model.clip_start_rows.append(frames_positions.size())
		model.clip_frame_counts.append(frames)
		var feet := PackedVector3Array()
		for frame: int in frames:
			var time := clip.animation.length * frame / frames
			var globals := pose(source, clip.animation, time)
			var skinned := skin(source, globals)
			frames_positions.append(skinned[0])
			frames_normals.append(skinned[1])
			if clip.walks:
				for foot: String in ["foot_l", "foot_r"]:
					var bone := source.bone_index(foot)
					if bone >= 0:
						feet.append(source.to_root * globals[bone].origin)
		foot_tracks.append(feet)
	# o pé apoiado anda para trás: se ele vai para +z, o boneco já olha para −z (frente no Godot)
	var forward_sign := 0.0
	var strides := PackedFloat32Array()
	for index: int in clips.size():
		var measured := _stride(foot_tracks[index], model.clip_frame_counts[index], fps)
		strides.append(absf(measured.x))
		forward_sign += measured.y
	model.clip_strides_m = strides
	if head_bone != "":
		var still := pose(source, null, 0.0)
		var head := source.to_root * still[source.bone_index(head_bone)].origin
		var hips := source.to_root * still[source.bone_index("Hips")].origin
		# cabeça em +z: o bicho olha para +z e precisa virar
		forward_sign = -1.0 if head.z > hips.z else 1.0
	var facing := Basis.IDENTITY if forward_sign >= 0.0 else Basis(Vector3.UP, PI)
	var turn := Transform3D(facing, Vector3.ZERO)
	_write_textures(model, frames_positions, frames_normals, turn)
	model.mesh = _rest_mesh(source, rest[0], rest[1], turn)
	model.vertex_count = source.vertices.size()
	model.triangle_count = source.triangle_count()
	return model


## Passo da animação (metros por ciclo) e para onde o pé apoiado anda (sinal em z): mede a
## velocidade do pé enquanto ele está no chão (até 2 cm acima do ponto mais baixo).
static func _stride(feet: PackedVector3Array, frames: int, fps: float) -> Vector2:
	if feet.size() < 4:
		return Vector2.ZERO
	var lowest := INF
	for point: Vector3 in feet:
		lowest = minf(lowest, point.y)
	var speeds := PackedFloat32Array()
	var direction := 0.0
	for foot: int in 2:
		for frame: int in frames:
			var now := feet[frame * 2 + foot]
			var next := feet[((frame + 1) % frames) * 2 + foot]
			if now.y < lowest + 0.02 and next.y < lowest + 0.02:
				var dz := next.z - now.z
				speeds.append(absf(dz) * fps)
				direction += signf(dz)
	if speeds.is_empty():
		return Vector2.ZERO
	speeds.sort()
	var speed := speeds[speeds.size() / 2]
	return Vector2(speed * frames / fps, direction)


static func _write_textures(model: VatModel, frames_positions: Array[PackedVector3Array],
		frames_normals: Array[PackedVector3Array], turn: Transform3D) -> void:
	var width := frames_positions[0].size()
	var height := frames_positions.size()
	var positions := Image.create_empty(width, height, false, Image.FORMAT_RGBAH)
	var normals := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for row: int in height:
		var frame_positions := frames_positions[row]
		var frame_normals := frames_normals[row]
		for vertex: int in width:
			var p := turn * frame_positions[vertex]
			var n := (turn.basis * frame_normals[vertex]) * 0.5 + Vector3(0.5, 0.5, 0.5)
			positions.set_pixel(vertex, row, Color(p.x, p.y, p.z, 1.0))
			normals.set_pixel(vertex, row, Color(n.x, n.y, n.z, 1.0))
	model.positions = ImageTexture.create_from_image(positions)
	model.normals = ImageTexture.create_from_image(normals)


## Malha na pose de repouso, com a região do corpo em UV.x e o índice do vértice em UV2.x.
static func _rest_mesh(source: Source, rest_positions: PackedVector3Array, rest_normals: PackedVector3Array,
		turn: Transform3D) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	for vertex: int in rest_positions.size():
		vertices.append(turn * rest_positions[vertex])
		normals.append((turn.basis * rest_normals[vertex]).normalized())
		uv2.append(Vector2(vertex, 0.0))
	var regions := regions_of(source, vertices)
	for region: int in regions:
		uv.append(Vector2(region, 0.0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_INDEX] = source.indices
	if not source.colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = source.colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = mesh.get_aabb().grow(AABB_MARGIN_M)
	return mesh


## Região de cada vértice pelo osso de maior peso; na cabeça, o alto e a nuca viram cabelo.
static func regions_of(source: Source, vertices: PackedVector3Array) -> PackedInt32Array:
	var regions := PackedInt32Array()
	var head_low := INF
	var head_high := -INF
	var head_center := Vector3.ZERO
	var head_count := 0
	var dominant := PackedStringArray()
	for vertex: int in vertices.size():
		var best_weight := -1.0
		var best_bone := ""
		for k: int in source.influences:
			var weight := source.weights[vertex * source.influences + k]
			if weight > best_weight:
				best_weight = weight
				var bone := source.bind_bones[source.bones[vertex * source.influences + k]]
				best_bone = source.bone_names[bone] if bone >= 0 else ""
		dominant.append(best_bone)
		if best_bone == "Head":
			head_low = minf(head_low, vertices[vertex].y)
			head_high = maxf(head_high, vertices[vertex].y)
			head_center += vertices[vertex]
			head_count += 1
	if head_count > 0:
		head_center /= head_count
	for vertex: int in vertices.size():
		var bone := dominant[vertex]
		var region := VatModel.Region.TROUSERS
		if bone == "Head":
			var height := inverse_lerp(head_low, head_high, vertices[vertex].y)
			var behind := vertices[vertex].z > head_center.z + HAIR_BACK_OFFSET_M
			if height > HAIR_HEIGHT_FRACTION or (behind and height > HAIR_BACK_HEIGHT_FRACTION):
				region = VatModel.Region.HAIR
			else:
				region = VatModel.Region.SKIN
		elif SKIN_BONES.has(bone) or _starts_with_any(bone, SKIN_PREFIXES):
			region = VatModel.Region.SKIN
		elif _starts_with_any(bone, COAT_PREFIXES):
			region = VatModel.Region.COAT
		elif _starts_with_any(bone, SHOE_PREFIXES):
			region = VatModel.Region.SHOES
		regions.append(region)
	return regions


static func _starts_with_any(text: String, prefixes: Array) -> bool:
	for prefix: String in prefixes:
		if text.begins_with(prefix):
			return true
	return false
