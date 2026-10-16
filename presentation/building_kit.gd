class_name BuildingKit
extends RefCounted
## Prédios de modelo (depois da Fase 12): as fachadas saem das peças modulares do Kenney Fantasy Town
## Kit (CC0, assets/models/buildings/), uma peça por célula da borda e por andar — parede com janela,
## porta na célula da entrada —, e o telhado é gerado aqui (duas águas, quatro águas ou plano), porque
## as peças de telhado do kit só fecham larguras de uma ou duas células. Tudo vira uma malha só por
## forma (Spec), guardada em cache: as casas iguais dividem a mesma malha.
##
## A malha fica no referencial "canônico" do prédio: rotação 0 (frente em −Z), largura def.size.x em
## x, fundo def.size.y em z, centro da área na origem e o chão em y = 0. A BuildingView gira o nó.
## O material (BuildingMaterials.kit) reconhece pela UV o que é parede e o que é telhado e põe nelas a
## textura PBR e o tom do prédio; o resto (madeiramento, janelas, porta) fica com as cores do kit.

const DIR := "res://assets/models/buildings/"
## Folga entre a parede e a borda da área, a mesma das caixas de antes.
const INSET_M := 0.3
## Altura de andar procurada: o número de andares é a altura do prédio dividida por ela.
const FLOOR_TARGET_M := 2.6
## Alicerce: desce abaixo do chão (a área pode ter desnível) e aparece um pouco acima dele.
const FOUNDATION_DOWN_M := 0.6
const FOUNDATION_UP_M := 0.15
## Beiral do telhado e espessura das águas.
const ROOF_OVERHANG_M := 0.35
const ROOF_THICKNESS_M := 0.18
## Telhado da casa em fração da altura (como a caixa de antes: fica acima das paredes).
const HOUSE_ROOF_FRACTION := 0.35
## Telhado dos outros em fração do lado curto.
const ROOF_SLOPE := 0.28
const SPIRE_SLOPE := 0.75
const FLAT_ROOF_M := 0.3
## Vidro aceso (WindowLightsView): onde fica a abertura da janela na peça, em fração da célula
## (largura) e do andar (centro e altura).
const WINDOW_WIDTH := 0.36
const WINDOW_CENTER := 0.52
const WINDOW_HEIGHT := 0.4
const WINDOW_GAP_M := 0.06

## UV de cada tipo de superfície na paleta do kit (colormap.png, 8 colunas × 4 linhas de cor). O
## shader usa a mesma divisão: parede = (1, 2) e (5, 3); telhado = (0, 3) e (1, 3).
const UV_WALL := Vector2(1.25 / 8.0, 2.5 / 4.0)
const UV_ROOF := Vector2(0.25 / 8.0, 3.5 / 4.0)
const UV_STONE := Vector2(7.5 / 8.0, 3.5 / 4.0)

enum Walls { PLASTER, WOOD }
enum Roof { GABLE_X, GABLE_Z, HIP, FLAT }
enum Door { NONE, DOOR, ARCH }

## Peças: parede lisa, janelas e portas de cada estilo.
const PIECES := {
	Walls.PLASTER: {
		&"plain": "wall", &"windows": ["wall-window-shutters", "wall-window-glass", "wall-window-small"],
		&"door": "wall-door", &"arch": "wall-doorway-round",
	},
	Walls.WOOD: {
		&"plain": "wall-wood", &"windows": ["wall-wood-window-shutters", "wall-wood-window-glass", "wall-wood-window-small"],
		&"door": "wall-wood-door", &"arch": "wall-wood-doorway-round",
	},
}
const CHIMNEY := "chimney"


## A forma de um prédio: tudo que muda a malha (e nada que só muda a cor).
class Spec:
	var cells := Vector2i(3, 3)
	var cell_m: float = 2.0
	var height_m: float = 4.0
	var walls: int = Walls.PLASTER
	var roof: int = Roof.GABLE_X
	var roof_m: float = 1.0
	var door: int = Door.DOOR
	var door_index: int = 1
	## Qual das três janelas do estilo, e se as fachadas alternam janela e parede lisa.
	var window_style: int = 0
	var sparse_windows: bool = false
	var chimney: bool = false

	func key() -> String:
		return "%d,%d|%.2f|%.2f|%d|%d|%.2f|%d|%d|%d|%d|%d" % [cells.x, cells.y, cell_m, height_m, walls, roof,
				roof_m, door, door_index, window_style, int(sparse_windows), int(chimney)]

	func size_m() -> Vector2:
		return Vector2(cells.x * cell_m - INSET_M, cells.y * cell_m - INSET_M)

	func floors() -> int:
		return maxi(1, roundi(height_m / FLOOR_TARGET_M))

	func floor_m() -> float:
		return height_m / floors()


static var _parts: Dictionary[String, Array] = {}
static var _meshes: Dictionary[String, ArrayMesh] = {}
static var _available: int = -1


static func available() -> bool:
	if _available < 0:
		_available = 1 if ResourceLoader.exists(DIR + "wall.glb") else 0
	return _available == 1


## A forma do prédio do registro (null: fica a caixa — campo, pasto, píer ou kit ausente).
static func spec_for(simulation: Simulation, record: BuildingRecord, cell_size: float) -> Spec:
	var def := simulation.def_of(record)
	if not available() or def.kind in [BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER]:
		return null
	var spec := Spec.new()
	spec.cells = def.size
	spec.cell_m = cell_size
	spec.door_index = def.size.x / 2 if posmod(record.rotation, 4) < 2 else def.size.x - 1 - def.size.x / 2
	if record.is_house():
		var tier := simulation.data.tier(record.tier)
		var variant := BuildingView.house_variant(record.id)
		spec.height_m = tier.house_height_m
		spec.walls = Walls.WOOD if tier.wall_material == BuildingMaterials.Wall.WOOD else Walls.PLASTER
		spec.roof = [Roof.GABLE_X, Roof.GABLE_Z, Roof.FLAT][variant]
		spec.roof_m = tier.house_height_m * HOUSE_ROOF_FRACTION
		spec.chimney = variant == 2
		spec.window_style = BuildingView.house_hash(record.id) / 3 % 2
		return spec
	spec.height_m = def.height_m
	spec.walls = Walls.WOOD if def.wall_material == BuildingMaterials.Wall.WOOD else Walls.PLASTER
	var short := minf(def.size.x, def.size.y) * cell_size
	spec.roof_m = short * ROOF_SLOPE
	spec.roof = Roof.GABLE_X if def.size.x >= def.size.y else Roof.GABLE_Z
	spec.window_style = 1
	if def.kind in [BuildingDef.Kind.WAREHOUSE] or def.is_shipyard():
		spec.door = Door.ARCH
		spec.sparse_windows = true
	elif def.kind == BuildingDef.Kind.SERVICE and def.wall_material == BuildingMaterials.Wall.STONE:
		# igreja, teatro, universidade: quatro águas, a igreja bem alta
		spec.roof = Roof.HIP
		spec.roof_m = short * (SPIRE_SLOPE if def.id == &"church" else ROOF_SLOPE * 1.4)
		spec.door = Door.ARCH
		spec.window_style = 2
	elif def.kind == BuildingDef.Kind.PRODUCTION and def.smoke != BuildingDef.Smoke.NONE:
		spec.sparse_windows = true
	if def.height_m < 3.0 or def.deposit != &"" or def.id in [&"clay_pit", &"sand_pit"]:
		spec.roof = Roof.FLAT
		spec.roof_m = FLAT_ROOF_M
	if def.wall_material == BuildingMaterials.Wall.WOOD:
		spec.window_style = 0
	return spec


## A malha da forma, feita uma vez por chave.
static func mesh(spec: Spec) -> ArrayMesh:
	var key := spec.key()
	if not _meshes.has(key):
		_meshes[key] = _build(spec)
	return _meshes[key]


static func cached_meshes() -> int:
	return _meshes.size()


## O que vai em cada célula da borda de cada andar: &"door", &"arch", &"plain" ou &"window".
## faces: 0 = frente (−Z), 1 = +X, 2 = fundo (+Z), 3 = −X; índice crescendo em x ou z.
static func slot(spec: Spec, face: int, index: int, level: int) -> StringName:
	if face == 0 and level == 0 and index == spec.door_index and spec.door != Door.NONE:
		return &"arch" if spec.door == Door.ARCH else &"door"
	if spec.sparse_windows and (index + level + face) % 2 == 1:
		return &"plain"
	return &"window"


## Vidros acesos à noite no referencial canônico: um por janela do modelo, logo à frente dela, com
## o +Z do vidro para fora.
static func windows(spec: Spec) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var size := spec.size_m()
	var floor_m := spec.floor_m()
	for face: int in 4:
		var count := spec.cells.x if face % 2 == 0 else spec.cells.y
		var step := (size.x if face % 2 == 0 else size.y) / count
		for level: int in spec.floors():
			for index: int in count:
				if slot(spec, face, index, level) != &"window":
					continue
				var place := _cell_transform(spec, face, index, level)
				var normal := _face_normal(face)
				# o meio da peça fica meia célula para dentro (o x da base é a profundidade): o vidro vai à parede
				var origin := place.origin + normal * (place.basis.x.length() * 0.5 + WINDOW_GAP_M) \
						+ Vector3(0.0, floor_m * WINDOW_CENTER, 0.0)
				var basis := Basis.looking_at(-normal, Vector3.UP).scaled_local(Vector3(step * WINDOW_WIDTH, floor_m * WINDOW_HEIGHT, 1.0))
				result.append(Transform3D(basis, origin))
	return result


const FACE_NORMALS: Array[Vector3] = [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
## Giro que leva o +X da peça à normal de cada fachada.
const FACE_YAWS: Array[float] = [PI * 0.5, 0.0, -PI * 0.5, PI]


## Meio da porta no chão, na fachada da frente (referencial canônico).
static func door_position(spec: Spec) -> Vector3:
	var place := _cell_transform(spec, 0, spec.door_index, 0)
	return place.origin + FACE_NORMALS[0] * (spec.size_m().y / spec.cells.y * 0.5)


## Triângulos da malha da forma (orçamento de polígonos).
static func triangles(spec: Spec) -> int:
	var arrays := mesh(spec).surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	return indices.size() / 3


static func _face_normal(face: int) -> Vector3:
	return FACE_NORMALS[face]


## Onde fica a peça: a origem é o ponto da fachada no meio da célula, no chão do andar; a base gira o
## +X da peça (a face de fora) para a normal da fachada e estica a célula até o tamanho dela.
static func _cell_transform(spec: Spec, face: int, index: int, level: int) -> Transform3D:
	var size := spec.size_m()
	var along := face % 2 == 0
	var count := spec.cells.x if along else spec.cells.y
	var step := (size.x if along else size.y) / count
	var depth := size.y / spec.cells.y if along else size.x / spec.cells.x
	var t := -(size.x if along else size.y) * 0.5 + step * (index + 0.5)
	var normal := _face_normal(face)
	var center := Vector3(t, level * spec.floor_m(), 0.0) if along else Vector3(0.0, level * spec.floor_m(), t)
	center += normal * ((size.y if along else size.x) * 0.5)
	# a peça ocupa x de -0,5 a 0,5 com a parede em 0,4..0,5: o meio da célula fica meia célula para dentro
	center -= normal * depth * 0.5
	var yaw := FACE_YAWS[face]
	var basis := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(depth, spec.floor_m(), step))
	return Transform3D(basis, center)


static func _parts_of(piece: String) -> Array:
	if _parts.has(piece):
		return _parts[piece]
	var parts: Array = []
	var path := DIR + piece + ".glb"
	if ResourceLoader.exists(path):
		var root := (load(path) as PackedScene).instantiate() as Node3D
		for node: Node in root.find_children("*", "MeshInstance3D", true, false):
			var part := node as MeshInstance3D
			parts.append([part.mesh, ShipView._transform_to(root, part)])
		root.free()
	_parts[piece] = parts
	return parts


static func _append_piece(tool: SurfaceTool, piece: String, transform: Transform3D) -> void:
	for part: Array in _parts_of(piece):
		var mesh: Mesh = part[0]
		var local: Transform3D = part[1]
		for surface: int in mesh.get_surface_count():
			tool.append_from(mesh, surface, transform * local)


static func _build(spec: Spec) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pieces: Dictionary = PIECES[spec.walls]
	var choices: Array = pieces[&"windows"]
	for face: int in 4:
		var count := spec.cells.x if face % 2 == 0 else spec.cells.y
		for level: int in spec.floors():
			for index: int in count:
				var kind := slot(spec, face, index, level)
				var piece: String = pieces[&"plain"]
				if kind == &"window":
					piece = choices[spec.window_style % choices.size()]
				elif kind != &"plain":
					piece = pieces[kind]
				_append_piece(tool, piece, _cell_transform(spec, face, index, level))
	var size := spec.size_m()
	# alicerce e telhado à parte: as peças do kit chegam indexadas, e vértice solto depois delas
	# ficaria fora do índice
	var extra := SurfaceTool.new()
	extra.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(extra, Vector3(0.0, (FOUNDATION_UP_M - FOUNDATION_DOWN_M) * 0.5, 0.0),
			Vector3(size.x + 0.1, FOUNDATION_UP_M + FOUNDATION_DOWN_M, size.y + 0.1), UV_STONE)
	_roof(extra, spec)
	extra.index()
	extra.generate_tangents()
	tool.append_from(extra.commit(), 0, Transform3D.IDENTITY)
	if spec.chimney:
		var stack := spec.roof_m + 0.6
		_append_piece(tool, CHIMNEY, Transform3D(Basis.from_scale(Vector3(3.0, stack, 3.0)),
				Vector3(size.x * 0.25 - 0.6, spec.height_m, -size.y * 0.2 + 0.5)))
	var arrays := tool.commit_to_arrays()
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	importer.generate_lods(25.0, 60.0, [])
	return importer.get_mesh()


## Telhado: as águas com a UV do telhado; as empenas (triângulos das pontas) com a UV da parede.
static func _roof(tool: SurfaceTool, spec: Spec) -> void:
	var size := spec.size_m()
	var top := spec.height_m
	var o := ROOF_OVERHANG_M
	match spec.roof:
		Roof.FLAT:
			_box(tool, Vector3(0.0, top + spec.roof_m * 0.5, 0.0), Vector3(size.x + 0.2, spec.roof_m, size.y + 0.2), UV_ROOF)
		Roof.HIP:
			var hx := size.x * 0.5 + o
			var hz := size.y * 0.5 + o
			var rx := maxf(hx - hz, 0.0)
			var rz := maxf(hz - hx, 0.0)
			var peak := top + spec.roof_m
			var c00 := Vector3(-hx, top, -hz)
			var c10 := Vector3(hx, top, -hz)
			var c11 := Vector3(hx, top, hz)
			var c01 := Vector3(-hx, top, hz)
			var r00 := Vector3(-rx, peak, -rz)
			var r10 := Vector3(rx, peak, -rz)
			var r11 := Vector3(rx, peak, rz)
			var r01 := Vector3(-rx, peak, rz)
			_quad(tool, c00, c10, r10, r00, Vector3(0, 1, -1), UV_ROOF)
			_quad(tool, c10, c11, r11, r10, Vector3(1, 1, 0), UV_ROOF)
			_quad(tool, c11, c01, r01, r11, Vector3(0, 1, 1), UV_ROOF)
			_quad(tool, c01, c00, r00, r01, Vector3(-1, 1, 0), UV_ROOF)
			_quad(tool, c00, c10, c11, c01, Vector3.DOWN, UV_ROOF)
		_:
			var along_x := spec.roof == Roof.GABLE_X
			# a cumeeira corre em u (x ou z) e as águas descem em v
			var hu := (size.x if along_x else size.y) * 0.5
			var hv := (size.y if along_x else size.x) * 0.5
			var eave := top - o * spec.roof_m / hv
			var ridge := top + spec.roof_m
			var down := Vector3(0.0, -ROOF_THICKNESS_M, 0.0)
			for side: float in [-1.0, 1.0]:
				var low_a := _uv_point(along_x, -hu - o, eave, side * (hv + o))
				var low_b := _uv_point(along_x, hu + o, eave, side * (hv + o))
				var high_b := _uv_point(along_x, hu + o, ridge, 0.0)
				var high_a := _uv_point(along_x, -hu - o, ridge, 0.0)
				var away := _uv_point(along_x, 0.0, 0.0, side)
				_quad(tool, low_a, low_b, high_b, high_a, away + Vector3.UP, UV_ROOF)
				_quad(tool, low_a + down, low_b + down, high_b + down, high_a + down, -away - Vector3.UP, UV_ROOF)
				_quad(tool, low_a + down, low_b + down, low_b, low_a, away, UV_ROOF)
			for end: float in [-1.0, 1.0]:
				var left := _uv_point(along_x, end * hu, top, -hv)
				var right := _uv_point(along_x, end * hu, top, hv)
				var apex := _uv_point(along_x, end * hu, ridge, 0.0)
				_triangle(tool, left, right, apex, _uv_point(along_x, end, 0.0, 0.0), UV_WALL)
				# a ponta da água por fora da empena
				var side_a := _uv_point(along_x, end * (hu + o), eave, -(hv + o))
				var side_b := _uv_point(along_x, end * (hu + o), eave, hv + o)
				var tip := _uv_point(along_x, end * (hu + o), ridge, 0.0)
				_quad(tool, side_a, side_a + down, tip + down, tip, _uv_point(along_x, end, 0.0, 0.0), UV_ROOF)
				_quad(tool, side_b, side_b + down, tip + down, tip, _uv_point(along_x, end, 0.0, 0.0), UV_ROOF)


static func _uv_point(along_x: bool, u: float, y: float, v: float) -> Vector3:
	return Vector3(u, y, v) if along_x else Vector3(v, y, u)


## Quadrilátero plano a, b, c, d (em volta), virado para "outward".
static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3, uv: Vector2) -> void:
	_triangle(tool, a, b, c, outward, uv)
	_triangle(tool, a, c, d, outward, uv)


## Triângulo virado para "outward" (o sentido dos vértices é acertado aqui). Triângulo sem área
## (a ponta do telhado de quatro águas quadrado) é pulado.
static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3, uv: Vector2) -> void:
	var cross := (b - a).cross(c - a)
	if cross.length_squared() < 1e-8:
		return
	var normal := cross.normalized()
	var points: Array[Vector3] = [a, b, c]
	# o Godot desenha como frente o sentido horário visto de fora
	if normal.dot(outward) > 0.0:
		points = [a, c, b]
	else:
		normal = -normal
	for point: Vector3 in points:
		tool.set_normal(normal)
		tool.set_uv(uv)
		tool.add_vertex(point)


static func _box(tool: SurfaceTool, center: Vector3, size: Vector3, uv: Vector2) -> void:
	var h := size * 0.5
	for axis: int in 3:
		for sign_value: float in [-1.0, 1.0]:
			var normal := Vector3.ZERO
			normal[axis] = sign_value
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = 1.0
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = 1.0
			var face := center + normal * h[axis]
			var du := u * h[(axis + 1) % 3]
			var dv := v * h[(axis + 2) % 3]
			_quad(tool, face - du - dv, face + du - dv, face + du + dv, face - du + dv, normal, uv)
