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
## Silhueta por cadeia (Fase 13, BuildingDef.silhouette): as peças do mesmo kit.
const WINDMILL := "windmill"
const WATERWHEEL := "watermill"
const SHEAVE := "wheel"
const BEAM := "pillar-wood"
const STALLS: Array[String] = ["stall-red", "stall-green"]
const BANNER := "banner-red"
## Detalhe das casas (Fase 13, TierDef.house_trim): cerca e portão do quintal, sebe (também a floreira),
## frente de sacada com colunas e parapeito e coluna de pedra do pórtico.
const FENCE := "fence"
const GATE := "fence-gate"
const HEDGE := "hedge"
const BALCONY := "balcony-wall-fence"
const PILLAR := "pillar-stone"
const PLANKS := "planks-half"
## Altura da cerca, quanto a sacada e a floreira saem da parede e a altura da coluna do pórtico em
## fração do andar.
const FENCE_M := 1.0
const BALCONY_OUT_M := 0.8
const FLOWER_BOX_OUT_M := 0.16
const PORTICO_HEIGHT := 0.95
## Medidas das peças do kit (caixa da peça importada): diâmetro das rodas, meio da polia, lado da viga.
const WINDMILL_DIAMETER := 3.113
const WATERWHEEL_DIAMETER := 1.8
const SHEAVE_DIAMETER := 0.483
const SHEAVE_CENTER := Vector3(0.318, 0.2416, 0.0)
const BEAM_SIDE := 0.16
## Torre de mina e guindaste: altura acima do telhado e espessura das vigas.
const HEADFRAME_M := 5.5
const CRANE_M := 3.0
const BEAM_M := 0.35
## Giro das partes que andam (rad/s de jogo a 1x) enquanto o prédio produz.
const WINDMILL_SPEED := 0.7
const WATERWHEEL_SPEED := 0.5
const SHEAVE_SPEED := 1.6


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
	var silhouette: int = BuildingDef.Silhouette.NONE
	## Fileiras da frente sem paredes (o pátio das bancas do mercado, o quintal da casa): o corpo fica
	## nas de trás.
	var court_rows: int = 0
	var trim: int = TierDef.HouseTrim.NONE

	func key() -> String:
		return "%d,%d|%.2f|%.2f|%d|%d|%.2f|%d|%d|%d|%d|%d|%d|%d|%d" % [cells.x, cells.y, cell_m, height_m, walls, roof,
				roof_m, door, door_index, window_style, int(sparse_windows), int(chimney), silhouette, court_rows, trim]

	## O corpo do prédio (sem o pátio), no referencial dele; hall_offset() o leva ao do prédio.
	func hall() -> Spec:
		if court_rows == 0:
			return self
		var copy := Spec.new()
		copy.cells = Vector2i(cells.x, cells.y - court_rows)
		copy.cell_m = cell_m
		copy.height_m = height_m
		copy.walls = walls
		copy.roof = roof
		copy.roof_m = roof_m
		copy.door = door
		copy.door_index = door_index
		copy.window_style = window_style
		copy.sparse_windows = sparse_windows
		copy.chimney = chimney
		copy.silhouette = silhouette
		copy.trim = trim
		return copy

	func hall_offset() -> Vector3:
		return Vector3(0.0, 0.0, court_rows * cell_m * 0.5)

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
		spec.trim = tier.house_trim
		if spec.trim == TierDef.HouseTrim.YARD and spec.cells.y > 2:
			# a fileira da frente vira quintal cercado; a casa fica nas de trás
			spec.court_rows = 1
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
	spec.silhouette = def.silhouette
	if def.silhouette == BuildingDef.Silhouette.STALLS:
		# metade da frente vira pátio; o telhado segue o lado curto do corpo
		spec.court_rows = def.size.y / 2
		var hall := spec.hall()
		spec.roof = Roof.GABLE_X if hall.cells.x >= hall.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(hall.cells.x, hall.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.WINDMILL:
		# a empena fica na frente e as pás giram nela
		spec.roof = Roof.GABLE_Z
	elif def.silhouette == BuildingDef.Silhouette.CLERESTORY and spec.roof == Roof.FLAT:
		spec.roof = Roof.GABLE_X if def.size.x >= def.size.y else Roof.GABLE_Z
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
	if spec.silhouette == BuildingDef.Silhouette.BANNERS and face == 0 and level == 1 and index == spec.door_index:
		return &"plain"
	if spec.sparse_windows and (index + level + face) % 2 == 1:
		return &"plain"
	return &"window"


## Vidros acesos à noite no referencial canônico: um por janela do modelo, logo à frente dela, com
## o +Z do vidro para fora.
static func windows(spec: Spec) -> Array[Transform3D]:
	if spec.court_rows > 0:
		var shifted: Array[Transform3D] = []
		for window: Transform3D in windows(spec.hall()):
			shifted.append(window.translated(spec.hall_offset()))
		return shifted
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
	if spec.court_rows > 0:
		return door_position(spec.hall()) + spec.hall_offset()
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
	var hall := spec.hall()
	var offset := Transform3D(Basis.IDENTITY, spec.hall_offset())
	var pieces: Dictionary = PIECES[spec.walls]
	var choices: Array = pieces[&"windows"]
	for face: int in 4:
		var count := hall.cells.x if face % 2 == 0 else hall.cells.y
		for level: int in hall.floors():
			for index: int in count:
				var kind := slot(hall, face, index, level)
				var piece: String = pieces[&"plain"]
				if kind == &"window":
					piece = choices[spec.window_style % choices.size()]
				elif kind != &"plain":
					piece = pieces[kind]
				_append_piece(tool, piece, offset * _cell_transform(hall, face, index, level))
	var size := spec.size_m()
	# alicerce e telhado à parte: as peças do kit chegam indexadas, e vértice solto depois delas
	# ficaria fora do índice
	var extra := SurfaceTool.new()
	extra.begin(Mesh.PRIMITIVE_TRIANGLES)
	# o quintal fica no chão: o alicerce é só o do corpo
	var base := hall.size_m() if spec.trim == TierDef.HouseTrim.YARD else size
	var base_center := spec.hall_offset() if spec.trim == TierDef.HouseTrim.YARD else Vector3.ZERO
	_box(extra, base_center + Vector3(0.0, (FOUNDATION_UP_M - FOUNDATION_DOWN_M) * 0.5, 0.0),
			Vector3(base.x + 0.1, FOUNDATION_UP_M + FOUNDATION_DOWN_M, base.y + 0.1), UV_STONE)
	if spec.court_rows > 0:
		# o telhado do corpo é feito no referencial dele e trazido para o do prédio
		var roof := SurfaceTool.new()
		roof.begin(Mesh.PRIMITIVE_TRIANGLES)
		_roof(roof, hall)
		extra.append_from(roof.commit(), 0, offset)
	else:
		_roof(extra, spec)
	_silhouette(tool, extra, spec)
	_trim(tool, spec)
	extra.index()
	extra.generate_tangents()
	tool.append_from(extra.commit(), 0, Transform3D.IDENTITY)
	if spec.chimney:
		var stack := spec.roof_m + 0.6
		var body := hall.size_m()
		_append_piece(tool, CHIMNEY, offset * Transform3D(Basis.from_scale(Vector3(3.0, stack, 3.0)),
				Vector3(body.x * 0.25 - 0.6, spec.height_m, -body.y * 0.2 + 0.5)))
	var arrays := tool.commit_to_arrays()
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	importer.generate_lods(25.0, 60.0, [])
	return importer.get_mesh()


## As peças paradas da silhueta (Fase 13). As que giram ficam em rotor().
static func _silhouette(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var size := spec.size_m()
	var top := spec.height_m + spec.roof_m
	match spec.silhouette:
		BuildingDef.Silhouette.HEADFRAME:
			# quatro pernas inclinadas do telhado até a plataforma da polia, travadas no meio
			var high := top + HEADFRAME_M
			var feet: Array[Vector3] = []
			var heads: Array[Vector3] = []
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				feet.append(Vector3(corner.x * minf(1.3, size.x * 0.3), top, corner.y * minf(1.0, size.y * 0.3)))
				heads.append(Vector3(corner.x * 0.55, high, corner.y * 0.3))
			for i: int in 4:
				_beam(tool, feet[i], heads[i], BEAM_M)
				var j := (i + 1) % 4
				_beam(tool, feet[i].lerp(heads[i], 0.5), feet[j].lerp(heads[j], 0.5), BEAM_M * 0.6)
				_beam(tool, heads[i], heads[j], BEAM_M * 0.6)
		BuildingDef.Silhouette.STALLS:
			# bancas no pátio, menos na coluna que leva à porta
			var step := size.x / spec.cells.x
			for row: int in spec.court_rows:
				for column: int in spec.cells.x:
					if column == spec.door_index:
						continue
					var center := Vector3(-size.x * 0.5 + step * (column + 0.5), 0.0,
							-size.y * 0.5 + spec.cell_m * (row + 0.5))
					var scale := spec.cell_m * 0.8
					_append_piece(tool, STALLS[(row + column) % STALLS.size()],
							Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * scale), center))
		BuildingDef.Silhouette.CRANE:
			# mastro no canto de trás, lança ao longo do lado e o cabo descendo fora da parede
			var mast := Vector3(size.x * 0.5 + 0.35, 0.0, size.y * 0.5 - 0.35)
			var high := top + CRANE_M
			var tip := Vector3(mast.x, high, -size.y * 0.15)
			_beam(tool, mast, mast + Vector3(0.0, high, 0.0), BEAM_M * 1.3)
			_beam(tool, mast + Vector3(0.0, high - 0.2, 0.0), tip, BEAM_M)
			_beam(tool, mast + Vector3(0.0, high - 2.2, 0.0), mast.lerp(tip, 0.5) + Vector3(0.0, high * 0.5 - 0.1, 0.0), BEAM_M * 0.6)
			_beam(tool, tip, Vector3(tip.x, 1.8, tip.z), 0.06)
			_box(extra, Vector3(tip.x, 1.4, tip.z), Vector3(0.8, 0.8, 0.8), UV_WALL)
		BuildingDef.Silhouette.CLERESTORY:
			# lanternim: uma faixa de parede mais alta ao longo da cumeeira, com o seu telhado
			var along_x := spec.roof != Roof.GABLE_Z
			var length := (size.x if along_x else size.y) * 0.7
			var ridge := spec.height_m + spec.roof_m
			_box(extra, Vector3(0.0, ridge + 0.35, 0.0), _uv_point(along_x, length, 1.3, 1.4), UV_WALL)
			_box(extra, Vector3(0.0, ridge + 1.08, 0.0), _uv_point(along_x, length + 0.4, 0.16, 2.2), UV_ROOF)
		BuildingDef.Silhouette.BANNERS:
			var hall := spec.hall()
			if hall.floors() > 1:
				# a bandeira fica sobre a parede lisa em cima da porta, um pouco à frente dela
				var place := Transform3D(Basis.IDENTITY, spec.hall_offset()) * _cell_transform(hall, 0, hall.door_index, 1)
				_append_piece(tool, BANNER, place * Transform3D(Basis.IDENTITY, Vector3(0.11, 0.0, 0.0)))


## O detalhe da casa pela classe (Fase 13). As peças do kit têm a face de fora em x = 0,5, como as
## paredes.
static func _trim(tool: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var offset := Transform3D(Basis.IDENTITY, spec.hall_offset())
	match spec.trim:
		TierDef.HouseTrim.YARD:
			if spec.court_rows == 0:
				return
			# cerca na borda da área, em volta das fileiras da frente, com o portão diante da porta
			for index: int in spec.cells.x:
				var piece := GATE if index == spec.door_index else FENCE
				_append_piece(tool, piece, _fence_place(spec, 0, index))
			for row: int in spec.court_rows:
				_append_piece(tool, FENCE, _fence_place(spec, 1, row))
				_append_piece(tool, FENCE, _fence_place(spec, 3, row))
		TierDef.HouseTrim.FLOWER_BOXES:
			# floreira debaixo de cada janela da frente, dos andares de cima
			for level: int in range(1, hall.floors()):
				for index: int in hall.cells.x:
					if slot(hall, 0, index, level) == &"window":
						var under := hall.floor_m() * (WINDOW_CENTER - WINDOW_HEIGHT * 0.5) - 0.18
						_append_piece(tool, HEDGE, offset * _face_place(hall, 0, index, level,
								Vector3(0.64, 0.9, 0.5), FLOWER_BOX_OUT_M, under))
		TierDef.HouseTrim.BALCONIES, TierDef.HouseTrim.PORTICO:
			# sacada corrida no primeiro andar (e nos do meio, nos engenheiros): piso e frente com parapeito
			var top := hall.floors() - 1 if spec.trim == TierDef.HouseTrim.BALCONIES else mini(2, hall.floors())
			for level: int in range(1, top):
				for index: int in hall.cells.x:
					_append_piece(tool, BALCONY, offset * _face_place(hall, 0, index, level,
							Vector3(1.0, hall.floor_m(), 1.0), BALCONY_OUT_M, 0.0))
					# o piso de tábuas vai da parede (x = 0 da peça) até a frente da sacada
					_append_piece(tool, PLANKS, offset * _face_place(hall, 0, index, level,
							Vector3(BALCONY_OUT_M * 2.0, 2.0, 1.0), BALCONY_OUT_M, -0.12))
			if spec.trim == TierDef.HouseTrim.PORTICO:
				# duas colunas de pedra dos lados da porta e sebe diante das outras células do térreo
				var door := _wall_point(hall, 0, hall.door_index, 0)
				var step := hall.size_m().x / hall.cells.x
				for side: float in [-0.42, 0.42]:
					var foot := door + _face_normal(0) * 0.35 + Vector3(side * step, 0.0, 0.0)
					_append_piece(tool, PILLAR, offset * Transform3D(Basis.from_scale(Vector3(1.7,
							hall.floor_m() * PORTICO_HEIGHT, 2.2)), foot))
				for index: int in hall.cells.x:
					if index != hall.door_index:
						_append_piece(tool, HEDGE, offset * _face_place(hall, 0, index, 0,
								Vector3(1.6, 3.0, 0.9), 0.45, 0.0))


## Peça presa à fachada: o meio da célula na face de fora da parede, saindo out_m dela e up_m acima do
## chão do andar, com a escala da peça (o x da escala é a profundidade: a face de fora da peça, x = 0,5,
## fica a out_m da parede).
static func _face_place(spec: Spec, face: int, index: int, level: int, scale: Vector3, out_m: float,
		up_m: float) -> Transform3D:
	var normal := _face_normal(face)
	var origin := _wall_point(spec, face, index, level) + normal * (out_m - 0.5 * scale.x) + Vector3(0.0, up_m, 0.0)
	return Transform3D(Basis(Vector3.UP, FACE_YAWS[face]) * Basis.from_scale(scale), origin)


## O meio da célula na face de fora da parede, no chão do andar.
static func _wall_point(spec: Spec, face: int, index: int, level: int) -> Vector3:
	var place := _cell_transform(spec, face, index, level)
	return place.origin + _face_normal(face) * place.basis.x.length() * 0.5


## Lanço da cerca na borda da área (não da parede): a célula da fachada, com a altura da cerca.
static func _fence_place(spec: Spec, face: int, index: int) -> Transform3D:
	var place := _cell_transform(spec, face, index, 0)
	place.basis.y = Vector3.UP * FENCE_M / 0.38
	# a borda da área fica INSET_M / 2 além da parede
	return place.translated(_face_normal(face) * INSET_M * 0.5)


## Viga da peça de madeira do kit de a até b (o comprimento da peça é 1 em y).
static func _beam(tool: SurfaceTool, a: Vector3, b: Vector3, thickness: float) -> void:
	var along := b - a
	if along.length_squared() < 1e-6:
		return
	var side := along.cross(Vector3.UP if absf(along.normalized().y) < 0.95 else Vector3.RIGHT).normalized()
	var other := side.cross(along).normalized()
	var k := thickness / BEAM_SIDE
	_append_piece(tool, BEAM, Transform3D(Basis(side * k, along, other * k), a))


## A parte que gira enquanto o prédio produz: pás do moinho, roda d'água ou polia da torre de mina.
class Rotor:
	var mesh: ArrayMesh
	## Onde fica o eixo, no referencial canônico; o giro é em torno do x local.
	var pivot: Transform3D
	var speed: float


static var _rotors: Dictionary[String, Rotor] = {}


static func rotor(spec: Spec) -> Rotor:
	if spec.silhouette not in [BuildingDef.Silhouette.WINDMILL, BuildingDef.Silhouette.WATERWHEEL,
			BuildingDef.Silhouette.HEADFRAME]:
		return null
	var key := spec.key()
	if _rotors.has(key):
		return _rotors[key]
	var size := spec.size_m()
	var result := Rotor.new()
	var piece := ""
	var scale := 1.0
	var center := Vector3.ZERO
	match spec.silhouette:
		BuildingDef.Silhouette.WINDMILL:
			# pás na frente, com o eixo para fora da fachada (o x da peça vira −Z)
			piece = WINDMILL
			scale = minf(size.x * 0.9, spec.height_m * 0.9) / WINDMILL_DIAMETER
			result.pivot = Transform3D(Basis(Vector3.UP, PI * 0.5),
					Vector3(0.0, spec.height_m + spec.roof_m * 0.35, -size.y * 0.5 - 0.6))
			result.speed = WINDMILL_SPEED
		BuildingDef.Silhouette.WATERWHEEL:
			piece = WATERWHEEL
			var diameter := minf(3.4, size.y * 0.6)
			scale = diameter / WATERWHEEL_DIAMETER
			result.pivot = Transform3D(Basis.IDENTITY, Vector3(size.x * 0.5 + 0.85, diameter * 0.38, 0.0))
			result.speed = WATERWHEEL_SPEED
		BuildingDef.Silhouette.HEADFRAME:
			piece = SHEAVE
			scale = 1.6 / SHEAVE_DIAMETER
			center = SHEAVE_CENTER
			result.pivot = Transform3D(Basis.IDENTITY, Vector3(0.0, spec.height_m + spec.roof_m + HEADFRAME_M + 0.4, 0.0))
			result.speed = SHEAVE_SPEED
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_piece(tool, piece, Transform3D(Basis.from_scale(Vector3.ONE * scale), -center * scale))
	result.mesh = tool.commit()
	_rotors[key] = result
	return result


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
