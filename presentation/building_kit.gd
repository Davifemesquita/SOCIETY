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
const SPIRE_SLOPE := 0.55
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
## Fase 18: madeiramento (o shader escurece), ferro (cinza-chumbo da paleta) e bronze (o marrom-cobre).
const UV_TIMBER := Vector2(4.5 / 8.0, 3.5 / 4.0)
const UV_IRON := Vector2(6.5 / 8.0, 3.5 / 4.0)
const UV_BRONZE := Vector2(4.5 / 8.0, 2.5 / 4.0)
## Pedra clara da cornija, das vergas e do frontão (o branco da paleta, que o shader acinzenta).
const UV_LIGHT_STONE := Vector2(2.5 / 8.0, 2.5 / 4.0)

enum Walls { PLASTER, WOOD }
enum Roof { GABLE_X, GABLE_Z, HIP, FLAT }
## GATE (Fase 18): o vão em arco com portão largo de duas folhas abertas, nas fábricas pesadas.
enum Door { NONE, DOOR, ARCH, GATE }

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
## coluna de pedra do pórtico e o piso da sacada (a frente de madeira do kit deu lugar à grade de ferro
## na Fase 18).
const FENCE := "fence"
const GATE := "fence-gate"
const HEDGE := "hedge"
const PILLAR := "pillar-stone"
const PLANKS := "planks-half"
## Altura da cerca, quanto a sacada e a floreira saem da parede e a altura da coluna do pórtico em
## fração do andar.
const FENCE_M := 1.0
const BALCONY_OUT_M := 0.8
const FLOWER_BOX_OUT_M := 0.16
const PORTICO_HEIGHT := 0.95
## Ornamento das casas (Fase 18), dos artesãos para cima: cornija no alto das paredes, verga de pedra
## sobre cada janela e, nos engenheiros e investidores, a faixa entre os andares; o frontão no alto da
## fachada, sobre a porta dos investidores; e grade de ferro (corrimão, travessa de baixo e balaústres a cada
## RAIL_STEP_M) no lugar do parapeito de madeira das sacadas.
const CORNICE_OUT_M := 0.16
const CORNICE_M := 0.26
const BAND_M := 0.1
const LINTEL_M := 0.12
const PEDIMENT_M := 0.7
const RAIL_M := 0.95
const RAIL_STEP_M := 0.19
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
## Guindaste de porto (Fase 23): a lança sai do mastro a CRANE_BOOM_FOOT da altura e sobe até CRANE_RISE_M
## acima do topo dele, presa por tirantes de ferro; sarilho de manivela no pé, cabo, moitão e gancho com um
## caixote pendurado a CRANE_LOAD_M do chão.
const CRANE_BOOM_FOOT := 0.3
const CRANE_RISE_M := 0.6
const CRANE_LOAD_M := 1.9
const CRANE_CRATE_M := 0.75
const CRANE_DRUM_RADIUS_M := 0.22
const CRANE_ROPE_M := 0.04
## Quanto a ponta da lança sai da parede do lado (o caixote pende longe dela).
const CRANE_REACH_M := 0.5
## Guincho do armazém com plataforma (Fase 23): a viga sai da fachada logo abaixo do beiral, sobre a porta de
## carga do sótão, até HOIST_OUT_M além da frente da área (passa do alpendre), e o caixote pende a HOIST_LOAD_M.
const HOIST_OUT_M := 0.35
const HOIST_LOAD_M := 1.5
## Giro das partes que andam (rad/s de jogo a 1x) enquanto o prédio produz.
const WINDMILL_SPEED := 0.7
const WATERWHEEL_SPEED := 0.5
const SHEAVE_SPEED := 1.6
## Campanário da igreja (Fase 18): torre quadrada no canto da frente, saindo um pouco das paredes, que
## passa do beiral, sineira aberta com o sino e a agulha com a cruz.
const BELFRY_SIDE_M := 2.4
const BELFRY_OUT_M := 0.2
const BELFRY_SHAFT_M := 3.0
const BELFRY_OPEN_M := 2.3
const BELFRY_SPIRE_M := 5.5
const BELL_HEIGHT_M := 0.95
const BELL_RADIUS_M := 0.6
## Portão da fábrica (Fase 18): largura em células, altura em fração do andar e quanto as folhas abrem
## (entreaberto: aberto de todo, a folha passava da área e entrava na rua).
const GATE_CELLS := 1.5
const GATE_HEIGHT := 0.82
const GATE_OPEN := deg_to_rad(40.0)
## Varanda da casa de engenho (Fase 23): a fileira da frente das plantações vira alpendre de tábuas, um
## pouco acima do chão, com esteios de madeira, guarda-corpo de balaústres e o telhado de uma água preso na
## parede entre os dois andares; dois degraus diante da porta.
const VERANDA_DECK_M := 0.35
const VERANDA_STEP_M := 0.35
const VERANDA_POST_M := 0.18
const VERANDA_RAIL_M := 0.8
const VERANDA_RAIL_STEP_M := 0.24
## Altura do beiral e da água na parede, em fração do andar (a água fica abaixo das janelas de cima).
const VERANDA_EAVE := 0.95
const VERANDA_WALL := 1.15
const VERANDA_OVERHANG_M := 0.25
## Plataforma de carga do armazém (Fase 23): a fileira da frente vira plataforma na altura da caçamba da
## carroça, de tijolo com tampo de tábuas e defensa de madeira, com uma rampa de pedra em cada ponta. Com o
## nível 1 ganha alpendre em mãos-francesas de ferro e portas de carga em células alternadas; no 2 (o que
## custa tijolo) as paredes passam a tijolo e o telhado a telha.
const DOCK_M := 0.8
const DOCK_RAMP_M := 1.7
const DOCK_CANOPY_LEVEL := 1
const DOCK_BRICK_LEVEL := 2
## Altura do alpendre na parede e no beiral, em fração do andar, e quanto ele sai além da plataforma.
const DOCK_CANOPY_WALL := 1.25
const DOCK_CANOPY_EAVE := 1.02
const DOCK_CANOPY_OUT_M := 0.15


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
	## Plataforma de carga do armazém (Fase 23) e o nível do armazém, que muda o alpendre e as portas dela.
	var dock: bool = false
	var level: int = 0

	func key() -> String:
		return "%d,%d|%.2f|%.2f|%d|%d|%.2f|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [cells.x, cells.y, cell_m, height_m, walls, roof,
				roof_m, door, door_index, window_style, int(sparse_windows), int(chimney), silhouette, court_rows, trim,
				int(dock), level]

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
		copy.dock = dock
		copy.level = level
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
	if not available() or def.kind in [BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER, BuildingDef.Kind.DECORATION]:
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
		# o armazém do interior (não o entreposto, que tem o cais) ganha a plataforma de carga na frente
		spec.dock = def.kind == BuildingDef.Kind.WAREHOUSE and not def.is_trading_post and def.size.y > 2
		if spec.dock:
			spec.level = record.level
			spec.court_rows = 1
	elif def.kind == BuildingDef.Kind.SERVICE and def.wall_material == BuildingMaterials.Wall.STONE:
		# igreja, teatro, universidade: quatro águas, a igreja bem alta
		spec.roof = Roof.HIP
		spec.roof_m = short * (SPIRE_SLOPE if def.id == &"church" else ROOF_SLOPE * 1.4)
		spec.door = Door.ARCH
		spec.window_style = 2
	elif def.kind == BuildingDef.Kind.PRODUCTION and def.smoke != BuildingDef.Smoke.NONE:
		spec.sparse_windows = true
		if def.smoke == BuildingDef.Smoke.HEAVY or def.silhouette == BuildingDef.Silhouette.CLERESTORY:
			spec.door = Door.GATE
	if def.height_m < 3.0 or def.deposit != &"" or def.id in [&"clay_pit", &"sand_pit"]:
		spec.roof = Roof.FLAT
		spec.roof_m = FLAT_ROOF_M
	if def.wall_material == BuildingMaterials.Wall.WOOD and not brick(spec):
		spec.window_style = 0
	if brick(spec):
		spec.walls = Walls.PLASTER
	spec.silhouette = def.silhouette
	if def.silhouette == BuildingDef.Silhouette.STALLS:
		# metade da frente vira pátio; o telhado segue o lado curto do corpo
		spec.court_rows = def.size.y / 2
		var hall := spec.hall()
		spec.roof = Roof.GABLE_X if hall.cells.x >= hall.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(hall.cells.x, hall.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.VERANDA and def.size.y > 2:
		# a fileira da frente vira varanda; o telhado segue o lado curto do corpo
		spec.court_rows = 1
		var house := spec.hall()
		spec.roof = Roof.GABLE_X if house.cells.x >= house.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(house.cells.x, house.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.WINDMILL:
		# a empena fica na frente e as pás giram nela
		spec.roof = Roof.GABLE_Z
	elif spec.dock:
		var body := spec.hall()
		spec.roof = Roof.GABLE_X if body.cells.x >= body.cells.y else Roof.GABLE_Z
		spec.roof_m = minf(body.cells.x, body.cells.y) * cell_size * ROOF_SLOPE
	elif def.silhouette == BuildingDef.Silhouette.CLERESTORY and spec.roof == Roof.FLAT:
		spec.roof = Roof.GABLE_X if def.size.x >= def.size.y else Roof.GABLE_Z
	return spec


## O armazém de nível DOCK_BRICK_LEVEL é de tijolo (Fase 23): a BuildingView troca as camadas da parede e do
## telhado.
static func brick(spec: Spec) -> bool:
	return spec.dock and spec.level >= DOCK_BRICK_LEVEL


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
		return &"arch" if spec.door in [Door.ARCH, Door.GATE] else &"door"
	if spec.silhouette == BuildingDef.Silhouette.BANNERS and face == 0 and level == 1 and index == spec.door_index:
		return &"plain"
	if spec.dock and face == 0 and level >= 1 and index == spec.door_index:
		return &"plain"
	if spec.dock and spec.level >= DOCK_CANOPY_LEVEL and face == 0 and level == 0 \
			and index % 2 == spec.door_index % 2:
		# portas de carga em células alternadas, todas dando na plataforma
		return &"arch"
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
	_trim(tool, extra, spec)
	if spec.door == Door.GATE:
		_gate(tool, extra, hall, offset)
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
			if spec.dock:
				_hoist(tool, extra, spec)
			else:
				_crane(tool, extra, spec)
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
		BuildingDef.Silhouette.BELFRY:
			_belfry(extra, spec)
		BuildingDef.Silhouette.VERANDA:
			if spec.court_rows > 0:
				_veranda(extra, spec)
	if spec.dock:
		_dock(extra, spec)


## Onde fica a plataforma de carga (Fase 23): x entre as rampas, z da frente da área até a parede do corpo,
## y do chão até o tampo.
static func dock_box(spec: Spec) -> AABB:
	var size := spec.size_m()
	var wall_z := spec.hall_offset().z - spec.hall().size_m().y * 0.5
	var front := -size.y * 0.5 + 0.15
	var left := -size.x * 0.5 + DOCK_RAMP_M
	return AABB(Vector3(left, 0.0, front), Vector3(size.x - DOCK_RAMP_M * 2.0, DOCK_M, wall_z - front))


static func _dock(tool: SurfaceTool, spec: Spec) -> void:
	var box := dock_box(spec)
	var center := box.get_center()
	var top := box.end.y
	# corpo de tijolo, tampo de tábuas que sai um pouco e a defensa de madeira na frente
	_box(tool, Vector3(center.x, (top - 0.1) * 0.5 - 0.05, center.z), Vector3(box.size.x, top - 0.1 + 0.1, box.size.z), UV_WALL)
	_box(tool, Vector3(center.x, top - 0.05, center.z - 0.05), Vector3(box.size.x + 0.1, 0.1, box.size.z + 0.1), UV_TIMBER)
	_box(tool, Vector3(center.x, top - 0.28, box.position.z - 0.08), Vector3(box.size.x, 0.22, 0.12), UV_TIMBER)
	# as rampas descem das pontas até o chão
	for side: float in [-1.0, 1.0]:
		var high := box.end.x if side > 0.0 else box.position.x
		var low := high + side * DOCK_RAMP_M
		_ramp(tool, low, high, box.position.z + 0.1, box.end.z, top - 0.02)
	if spec.level < DOCK_CANOPY_LEVEL:
		return
	# alpendre sobre a plataforma, preso na parede por mãos-francesas de ferro
	var floor_m := spec.hall().floor_m()
	var high_point := Vector3(0.0, floor_m * DOCK_CANOPY_WALL, box.end.z)
	var low_point := Vector3(0.0, floor_m * DOCK_CANOPY_EAVE, box.position.z - DOCK_CANOPY_OUT_M)
	_lean_to(tool, high_point, low_point, spec.size_m().x - 0.2)
	var bracket_step := spec.size_m().x / spec.cells.x
	for k: int in spec.cells.x + 1:
		var x := clampf(-spec.size_m().x * 0.5 + bracket_step * k, -spec.size_m().x * 0.5 + 0.2, spec.size_m().x * 0.5 - 0.2)
		var wall_foot := Vector3(x, floor_m * DOCK_CANOPY_EAVE - 0.9, box.end.z)
		var under := Vector3(x, floor_m * DOCK_CANOPY_EAVE + 0.05, box.position.z + 0.2)
		_bar(tool, wall_foot, under, 0.07, UV_IRON)
		_bar(tool, Vector3(x, high_point.y - 0.05, box.end.z), under, 0.06, UV_IRON)


## Rampa ao longo de x: do chão em low_x até "top" em high_x, de z0 a z1 (cunha: a face inclinada e os dois lados).
static func _ramp(tool: SurfaceTool, low_x: float, high_x: float, z0: float, z1: float, top: float) -> void:
	var away := Vector3(signf(low_x - high_x), 1.0, 0.0)
	_quad(tool, Vector3(low_x, 0.0, z0), Vector3(low_x, 0.0, z1), Vector3(high_x, top, z1), Vector3(high_x, top, z0), away, UV_STONE)
	for z: float in [z0, z1]:
		_triangle(tool, Vector3(low_x, 0.0, z), Vector3(high_x, 0.0, z), Vector3(high_x, top, z),
				Vector3(0.0, 0.0, signf(z - (z0 + z1) * 0.5)), UV_STONE)
	# o meio-fio de madeira da beira da rampa
	for z: float in [z0 + 0.05, z1 - 0.05]:
		_bar(tool, Vector3(low_x, 0.05, z), Vector3(high_x, top + 0.05, z), 0.1, UV_TIMBER)


## Barra de seção quadrada de a até b, numa caixa girada.
static func _bar(tool: SurfaceTool, a: Vector3, b: Vector3, thickness: float, uv: Vector2) -> void:
	var along := b - a
	if along.length_squared() < 1e-6:
		return
	var z := along.normalized()
	var x := (Vector3.UP if absf(z.y) < 0.95 else Vector3.RIGHT).cross(z).normalized()
	var y := z.cross(x)
	_box_at(tool, Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(thickness, thickness, along.length()), uv)


## Telhado de uma água de "high" (na parede) até "low" (o beiral), com a largura em x.
static func _lean_to(tool: SurfaceTool, high: Vector3, low: Vector3, width: float) -> void:
	var along := (low - high).normalized()
	# x de lado a lado, z subindo a água e y para fora dela
	var basis := Basis(Vector3.RIGHT, -along.cross(Vector3.RIGHT).normalized(), -along)
	_box_at(tool, Transform3D(basis, (high + low) * 0.5 + basis.y * ROOF_THICKNESS_M * 0.5),
			Vector3(width, ROOF_THICKNESS_M, high.distance_to(low)), UV_ROOF)


## Onde fica a varanda (Fase 23): x de um lado ao outro da área, z da frente da área até a parede do corpo,
## y do chão até o alto da água na parede.
static func veranda_box(spec: Spec) -> AABB:
	var size := spec.size_m()
	var hall := spec.hall()
	var wall_z := spec.hall_offset().z - hall.size_m().y * 0.5
	var front := -size.y * 0.5
	return AABB(Vector3(-size.x * 0.5, 0.0, front), Vector3(size.x, hall.floor_m() * VERANDA_WALL, wall_z - front))


static func _veranda(tool: SurfaceTool, spec: Spec) -> void:
	var box := veranda_box(spec)
	var hall := spec.hall()
	var floor_m := hall.floor_m()
	var left := box.position.x
	var right := box.end.x
	var wall := box.end.z
	# o assoalho começa VERANDA_STEP_M para dentro: na frente da porta ficam os degraus
	var front := box.position.z + VERANDA_STEP_M
	var deck := VERANDA_DECK_M
	_box(tool, Vector3(0.0, (deck - 0.1) * 0.5, (front + wall) * 0.5), Vector3(right - left, deck + 0.1, wall - front), UV_TIMBER)
	var step := (right - left) / spec.cells.x
	var door_x := left + step * (spec.door_index + 0.5)
	var stair := step * 0.7
	_box(tool, Vector3(door_x, deck / 3.0, front - VERANDA_STEP_M * 0.25), Vector3(stair, deck * 2.0 / 3.0, VERANDA_STEP_M * 0.5), UV_STONE)
	_box(tool, Vector3(door_x, deck / 6.0, front - VERANDA_STEP_M * 0.75), Vector3(stair, deck / 3.0, VERANDA_STEP_M * 0.5), UV_STONE)
	# esteios na frente, um em cada divisa de célula, e a viga do beiral em cima deles
	var eave := floor_m * VERANDA_EAVE
	var post_z := front + VERANDA_POST_M * 0.5 + 0.04
	var post_xs: Array[float] = []
	for k: int in spec.cells.x + 1:
		post_xs.append(clampf(left + step * k, left + VERANDA_POST_M * 0.5, right - VERANDA_POST_M * 0.5))
	for x: float in post_xs:
		_box(tool, Vector3(x, (deck + eave) * 0.5, post_z), Vector3(VERANDA_POST_M, eave - deck, VERANDA_POST_M), UV_TIMBER)
		# mão-francesa: o braço do esteio até a viga
		_box(tool, Vector3(x, eave - 0.12, post_z), Vector3(VERANDA_POST_M * 2.2, 0.08, VERANDA_POST_M * 0.8), UV_TIMBER)
	_box(tool, Vector3(0.0, eave + 0.09, post_z), Vector3(right - left, 0.18, VERANDA_POST_M * 1.1), UV_TIMBER)
	# guarda-corpo entre os esteios, menos no vão da porta, e nas duas pontas até a parede
	for k: int in spec.cells.x:
		if k == spec.door_index:
			continue
		_railing(tool, Vector3(post_xs[k], deck, post_z), Vector3(post_xs[k + 1], deck, post_z), UV_TIMBER,
				VERANDA_RAIL_M, 0.06, VERANDA_RAIL_STEP_M)
	for x: float in [post_xs[0], post_xs[post_xs.size() - 1]]:
		_railing(tool, Vector3(x, deck, post_z), Vector3(x, deck, wall), UV_TIMBER, VERANDA_RAIL_M, 0.06, VERANDA_RAIL_STEP_M)
	# telhado de uma água, da parede (entre os andares) até um pouco além dos esteios
	_lean_to(tool, Vector3(0.0, floor_m * VERANDA_WALL, wall), Vector3(0.0, eave + 0.18, post_z - VERANDA_OVERHANG_M),
			right - left + VERANDA_OVERHANG_M * 2.0)


## Guindaste de porto (Fase 23): o mastro no canto de trás, por fora da parede do lado, e a lança subindo
## para a frente ao longo dela.
static func crane_mast(spec: Spec) -> Vector3:
	var size := spec.size_m()
	return Vector3(size.x * 0.5 + 0.35, 0.0, size.y * 0.5 - 0.35)


static func crane_height(spec: Spec) -> float:
	return spec.height_m + spec.roof_m + CRANE_M


static func crane_tip(spec: Spec) -> Vector3:
	var mast := crane_mast(spec)
	return Vector3(mast.x + CRANE_REACH_M, crane_height(spec) + CRANE_RISE_M, -spec.size_m().y * 0.2)


## Onde fica o gancho (o caixote pende logo abaixo).
static func crane_hook(spec: Spec) -> Vector3:
	var tip := crane_tip(spec)
	return Vector3(tip.x, CRANE_LOAD_M + CRANE_CRATE_M + 0.45, tip.z)


static func _crane(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var mast := crane_mast(spec)
	var high := crane_height(spec)
	var top := mast + Vector3(0.0, high, 0.0)
	var tip := crane_tip(spec)
	var foot := mast + Vector3(0.0, high * CRANE_BOOM_FOOT, 0.0)
	# soco de pedra, mastro, escora para a frente e a lança com os tirantes de ferro do topo à ponta
	_box(extra, mast + Vector3(0.0, 0.2, 0.0), Vector3(1.0, 0.4 + FOUNDATION_DOWN_M, 1.0), UV_STONE)
	_beam(tool, mast, top, BEAM_M * 1.3)
	_beam(tool, mast + Vector3(0.0, 0.0, -1.5), mast + Vector3(0.0, high * 0.4, 0.0), BEAM_M * 0.7)
	_beam(tool, foot, tip, BEAM_M)
	for side: float in [-1.0, 1.0]:
		var spread := Vector3(side * 0.12, 0.0, 0.0)
		_bar(extra, top + spread, tip + spread + Vector3(0.0, 0.1, 0.0), 0.06, UV_IRON)
	_box(extra, top + Vector3(0.0, 0.12, 0.0), Vector3(0.6, 0.24, 0.6), UV_TIMBER)
	# sarilho no pé do mastro: dois montantes, o tambor e as manivelas de ferro
	var drum := mast + Vector3(0.0, 0.75, -0.7)
	for side: float in [-1.0, 1.0]:
		_box(extra, drum + Vector3(side * 0.38, -0.38, 0.0), Vector3(0.1, 0.9, 0.5), UV_TIMBER)
		var crank := drum + Vector3(side * 0.48, 0.0, 0.0)
		_bar(extra, crank, crank + Vector3(0.0, 0.3, -0.12), 0.05, UV_IRON)
		_bar(extra, crank + Vector3(0.0, 0.3, -0.12), crank + Vector3(side * 0.22, 0.3, -0.12), 0.05, UV_IRON)
	_drum(extra, drum, CRANE_DRUM_RADIUS_M, 0.66, UV_TIMBER)
	# cabo do tambor à ponta, moitão e o cabo descendo até o gancho, com o caixote nas lingas
	_bar(extra, drum + Vector3(0.0, CRANE_DRUM_RADIUS_M, 0.0), tip, CRANE_ROPE_M, UV_IRON)
	_box(extra, tip + Vector3(0.0, -0.2, 0.0), Vector3(0.22, 0.34, 0.3), UV_TIMBER)
	_hanging_crate(extra, tip + Vector3(0.0, -0.35, 0.0), crane_hook(spec), CRANE_LOAD_M)


## Guincho do armazém com plataforma: a ponta da viga, sobre a coluna da porta.
static func hoist_tip(spec: Spec) -> Vector3:
	var hall := spec.hall()
	var size := spec.size_m()
	var x := -size.x * 0.5 + size.x / spec.cells.x * (spec.door_index + 0.5)
	return Vector3(x, hall.height_m - 0.3, -size.y * 0.5 - HOIST_OUT_M)


static func _hoist(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var tip := hoist_tip(spec)
	var wall_z := spec.hall_offset().z - hall.size_m().y * 0.5
	# portas de carga de tábuas nos andares de cima, sobre a porta de baixo
	for level: int in range(1, hall.floors()):
		var bottom := level * hall.floor_m() + 0.1
		var height := hall.floor_m() * 0.78
		_box(extra, Vector3(tip.x, bottom + height * 0.5, wall_z - 0.05), Vector3(1.1, height, 0.1), UV_TIMBER)
		_box(extra, Vector3(tip.x, bottom + height * 0.5, wall_z - 0.11), Vector3(0.08, height, 0.04), UV_IRON)
	# a viga entra na parede e a mão-francesa de ferro a segura por baixo
	var root := Vector3(tip.x, tip.y, wall_z + 0.3)
	_beam(tool, root, tip, BEAM_M * 0.8)
	_bar(extra, Vector3(tip.x, tip.y - 1.1, wall_z), tip.lerp(root, 0.45) + Vector3(0.0, -0.1, 0.0), 0.07, UV_IRON)
	# moitão, cabo e o caixote nas lingas
	_box(extra, tip + Vector3(0.0, -0.3, 0.0), Vector3(0.22, 0.34, 0.3), UV_TIMBER)
	var hook := Vector3(tip.x, HOIST_LOAD_M + CRANE_CRATE_M + 0.45, tip.z)
	_hanging_crate(extra, tip + Vector3(0.0, -0.45, 0.0), hook, HOIST_LOAD_M)


## Cabo de "from" até o gancho e o caixote pendurado nele pelas lingas, com o fundo em "bottom".
static func _hanging_crate(tool: SurfaceTool, from: Vector3, hook: Vector3, bottom: float) -> void:
	_bar(tool, from, hook, CRANE_ROPE_M, UV_IRON)
	_box(tool, hook + Vector3(0.0, -0.08, 0.0), Vector3(0.14, 0.16, 0.14), UV_IRON)
	var crate := Vector3(hook.x, bottom + CRANE_CRATE_M * 0.5, hook.z)
	_box(tool, crate, Vector3.ONE * CRANE_CRATE_M, UV_TIMBER)
	var half := CRANE_CRATE_M * 0.5 - 0.05
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		_bar(tool, hook + Vector3(0.0, -0.16, 0.0), crate + Vector3(corner.x * half, CRANE_CRATE_M * 0.5, corner.y * half),
				0.03, UV_TIMBER)


## Tambor de oito faces ao longo de x, com as tampas.
static func _drum(tool: SurfaceTool, center: Vector3, radius: float, length: float, uv: Vector2) -> void:
	var near := center - Vector3(length * 0.5, 0.0, 0.0)
	var far := center + Vector3(length * 0.5, 0.0, 0.0)
	for i: int in 8:
		var a0 := TAU * i / 8.0
		var a1 := TAU * (i + 1) / 8.0
		var d0 := Vector3(0.0, cos(a0), sin(a0)) * radius
		var d1 := Vector3(0.0, cos(a1), sin(a1)) * radius
		_quad(tool, near + d0, far + d0, far + d1, near + d1, (d0 + d1) * 0.5, uv)
		_triangle(tool, near, near + d0, near + d1, Vector3.LEFT, uv)
		_triangle(tool, far, far + d0, far + d1, Vector3.RIGHT, uv)


## Campanário (Fase 18) no canto da frente à esquerda: o fuste de parede até BELFRY_SHAFT_M acima do
## beiral, a sineira (quatro pilares, laje de pedra embaixo e em cima) com o sino pendurado na trave, e
## a agulha de quatro águas com a cruz de ferro.
static func belfry_center(spec: Spec) -> Vector3:
	var size := spec.size_m()
	var half := BELFRY_SIDE_M * 0.5
	return Vector3(-size.x * 0.5 + half - BELFRY_OUT_M, 0.0, -size.y * 0.5 + half - BELFRY_OUT_M)


static func belfry_top(spec: Spec) -> float:
	return spec.height_m + BELFRY_SHAFT_M + BELFRY_OPEN_M + 0.3 + BELFRY_SPIRE_M


static func _belfry(tool: SurfaceTool, spec: Spec) -> void:
	var center := belfry_center(spec)
	var side := BELFRY_SIDE_M
	var shaft := spec.height_m + BELFRY_SHAFT_M
	_box(tool, center + Vector3(0.0, shaft * 0.5 - FOUNDATION_DOWN_M * 0.5, 0.0),
			Vector3(side, shaft + FOUNDATION_DOWN_M, side), UV_WALL)
	# cornija no alto do fuste e no beiral da igreja
	for height: float in [spec.height_m - 0.1, shaft - 0.15]:
		_box(tool, center + Vector3(0.0, height, 0.0), Vector3(side + 0.24, 0.3, side + 0.24), UV_STONE)
	var pier := 0.42
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var at := center + Vector3(corner.x, 0.0, corner.y) * (side - pier) * 0.5
		_box(tool, at + Vector3(0.0, shaft + BELFRY_OPEN_M * 0.5, 0.0), Vector3(pier, BELFRY_OPEN_M, pier), UV_WALL)
	var cap := shaft + BELFRY_OPEN_M
	_box(tool, center + Vector3(0.0, cap + 0.15, 0.0), Vector3(side + 0.3, 0.3, side + 0.3), UV_STONE)
	# trave de madeira de um lado ao outro e o sino pendurado nela
	var yoke := cap - 0.25
	_box(tool, center + Vector3(0.0, yoke, 0.0), Vector3(side - pier, 0.16, 0.2), UV_TIMBER)
	_bell(tool, center + Vector3(0.0, yoke - 0.1 - BELL_HEIGHT_M, 0.0))
	# agulha
	var base := cap + 0.3
	var half := side * 0.5 + 0.1
	var tip := center + Vector3(0.0, base + BELFRY_SPIRE_M, 0.0)
	var ring: Array[Vector3] = []
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		ring.append(center + Vector3(corner.x * half, base, corner.y * half))
	for i: int in 4:
		var a := ring[i]
		var b := ring[(i + 1) % 4]
		var middle := (a + b) * 0.5 - center
		_triangle(tool, a, b, tip, Vector3(middle.x, 0.5, middle.z), UV_ROOF)
	_box(tool, tip + Vector3(0.0, 0.55, 0.0), Vector3(0.08, 1.1, 0.08), UV_IRON)
	_box(tool, tip + Vector3(0.0, 0.75, 0.0), Vector3(0.55, 0.08, 0.08), UV_IRON)


## Sino de bronze: tronco de cone de BELL_SEGMENTS faces que se abre na boca, com a coroa em cima; a
## boca fica em "mouth".
const BELL_SEGMENTS := 12
const BELL_PROFILE: Array[Vector2] = [Vector2(0.38, 1.0), Vector2(0.55, 0.62), Vector2(0.72, 0.22), Vector2(1.0, 0.0)]


static func _bell(tool: SurfaceTool, mouth: Vector3) -> void:
	for k: int in BELL_PROFILE.size() - 1:
		var upper := BELL_PROFILE[k]
		var lower := BELL_PROFILE[k + 1]
		for i: int in BELL_SEGMENTS:
			var a0 := TAU * i / BELL_SEGMENTS
			var a1 := TAU * (i + 1) / BELL_SEGMENTS
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			var y_up := Vector3.UP * upper.y * BELL_HEIGHT_M
			var y_low := Vector3.UP * lower.y * BELL_HEIGHT_M
			_quad(tool, mouth + d0 * lower.x * BELL_RADIUS_M + y_low, mouth + d1 * lower.x * BELL_RADIUS_M + y_low,
					mouth + d1 * upper.x * BELL_RADIUS_M + y_up, mouth + d0 * upper.x * BELL_RADIUS_M + y_up,
					(d0 + d1) * 0.5 + Vector3.UP * 0.3, UV_BRONZE)
	var crown := BELL_PROFILE[0].x * BELL_RADIUS_M
	_box(tool, mouth + Vector3(0.0, BELL_HEIGHT_M + 0.02, 0.0), Vector3(crown * 1.6, 0.06, crown * 1.6), UV_BRONZE)


## Portão largo (Fase 18) diante do vão em arco da fábrica: dois esteios e a verga de madeira, e as duas
## folhas de tábua abertas para fora, presas nos esteios.
static func _gate(tool: SurfaceTool, extra: SurfaceTool, hall: Spec, offset: Transform3D) -> void:
	var door := offset * _wall_point(hall, 0, hall.door_index, 0)
	var width := hall.size_m().x / hall.cells.x * GATE_CELLS
	var height := hall.floor_m() * GATE_HEIGHT
	var out := _face_normal(0) * 0.12
	for side: float in [-1.0, 1.0]:
		var post := door + out + Vector3(side * width * 0.5, 0.0, 0.0)
		_beam(tool, post, post + Vector3(0.0, height + 0.25, 0.0), 0.24)
		# a folha sai do esteio para o meio do vão e gira para fora
		var swing := Basis(Vector3.UP, -side * GATE_OPEN)
		var leaf := width * 0.5 - 0.1
		var along := swing * Vector3(-side, 0.0, 0.0)
		_box_at(extra, Transform3D(Basis.looking_at(along.cross(Vector3.UP), Vector3.UP),
				post + along * (leaf * 0.5 + 0.1) + Vector3(0.0, height * 0.5, 0.0)),
				Vector3(leaf, height, 0.08), UV_TIMBER)
	_beam(tool, door + out + Vector3(-width * 0.5 - 0.2, height + 0.2, 0.0),
			door + out + Vector3(width * 0.5 + 0.2, height + 0.2, 0.0), 0.26)


## Caixa girada: a caixa do _box no referencial "place" (x, y e z da base são largura, altura e fundo).
static func _box_at(tool: SurfaceTool, place: Transform3D, size: Vector3, uv: Vector2) -> void:
	var local := SurfaceTool.new()
	local.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(local, Vector3.ZERO, size, uv)
	tool.append_from(local.commit(), 0, place)


## O detalhe da casa pela classe (Fase 13). As peças do kit têm a face de fora em x = 0,5, como as
## paredes.
static func _trim(tool: SurfaceTool, extra: SurfaceTool, spec: Spec) -> void:
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
			# sacada corrida no primeiro andar (e nos do meio, nos engenheiros): piso de tábuas e grade de ferro
			var top := hall.floors() - 1 if spec.trim == TierDef.HouseTrim.BALCONIES else mini(2, hall.floors())
			for level: int in range(1, top):
				for index: int in hall.cells.x:
					# o piso de tábuas vai da parede (x = 0 da peça) até a frente da sacada
					_append_piece(tool, PLANKS, offset * _face_place(hall, 0, index, level,
							Vector3(BALCONY_OUT_M * 2.0, 2.0, 1.0), BALCONY_OUT_M, -0.12))
				# grade de ferro na frente e nas duas pontas da sacada corrida
				var floor_y := level * hall.floor_m()
				var half := hall.size_m() * 0.5
				var wall := spec.hall_offset() + Vector3(0.0, floor_y, -half.y)
				var out := Vector3(0.0, 0.0, -BALCONY_OUT_M)
				_railing(extra, wall + out + Vector3(-half.x, 0.0, 0.0), wall + out + Vector3(half.x, 0.0, 0.0))
				for end: float in [-half.x, half.x]:
					_railing(extra, wall + Vector3(end, 0.0, 0.0), wall + out + Vector3(end, 0.0, 0.0))
			if spec.trim == TierDef.HouseTrim.PORTICO:
				# duas colunas de pedra dos lados da porta e sebe diante das outras células do térreo
				var door := _wall_point(hall, 0, hall.door_index, 0)
				var step := hall.size_m().x / hall.cells.x
				for side: float in [-0.42, 0.42]:
					var foot := door + _face_normal(0) * 0.35 + Vector3(side * step, 0.0, 0.0)
					_append_piece(tool, PILLAR, offset * Transform3D(Basis.from_scale(Vector3(1.7,
							hall.floor_m() * PORTICO_HEIGHT, 2.2)), foot))
				# o frontão fica no alto da fachada, sobre a porta: em cima do pórtico ele atravessava a sacada
				_pediment(extra, offset * door, step * 1.4, hall.height_m)
				for index: int in hall.cells.x:
					if index != hall.door_index:
						_append_piece(tool, HEDGE, offset * _face_place(hall, 0, index, 0,
								Vector3(1.6, 3.0, 0.9), 0.45, 0.0))
	if spec.trim in [TierDef.HouseTrim.FLOWER_BOXES, TierDef.HouseTrim.BALCONIES, TierDef.HouseTrim.PORTICO]:
		_ornament(extra, spec)


## Cornija, vergas das janelas e (engenheiros e investidores) a faixa entre os andares, em pedra clara.
static func _ornament(tool: SurfaceTool, spec: Spec) -> void:
	var hall := spec.hall()
	var center := spec.hall_offset()
	var size := hall.size_m()
	_box(tool, center + Vector3(0.0, hall.height_m - CORNICE_M * 0.5, 0.0),
			Vector3(size.x + CORNICE_OUT_M * 2.0, CORNICE_M, size.y + CORNICE_OUT_M * 2.0), UV_LIGHT_STONE)
	if spec.trim != TierDef.HouseTrim.FLOWER_BOXES:
		for level: int in range(1, hall.floors()):
			_box(tool, center + Vector3(0.0, level * hall.floor_m(), 0.0),
					Vector3(size.x + 0.12, BAND_M, size.y + 0.12), UV_LIGHT_STONE)
	for face: int in 4:
		var count := hall.cells.x if face % 2 == 0 else hall.cells.y
		var step := (size.x if face % 2 == 0 else size.y) / count
		for level: int in hall.floors():
			for index: int in count:
				if slot(hall, face, index, level) != &"window":
					continue
				var top := hall.floor_m() * (WINDOW_CENTER + WINDOW_HEIGHT * 0.5) + LINTEL_M
				var at := center + _wall_point(hall, face, index, level) + Vector3(0.0, top, 0.0) \
						+ _face_normal(face) * 0.04
				var width := step * WINDOW_WIDTH * 1.5
				_box(tool, at, Vector3(width, LINTEL_M, 0.1) if face % 2 == 0 else Vector3(0.1, LINTEL_M, width), UV_LIGHT_STONE)


## Frontão: a base de pedra em "height" (o alto da parede) e o triângulo sobre ela, centrados em "front"
## (o ponto da fachada no chão) e de frente para −Z.
static func _pediment(tool: SurfaceTool, front: Vector3, width: float, height: float) -> void:
	var depth := 0.7
	_box(tool, front + Vector3(0.0, height + 0.13, 0.0), Vector3(width, 0.26, depth), UV_LIGHT_STONE)
	var base := height + 0.26
	var half := width * 0.5
	var near := front.z - depth * 0.5
	var far := front.z + depth * 0.5
	var apex_near := Vector3(front.x, base + PEDIMENT_M, near)
	var apex_far := Vector3(front.x, base + PEDIMENT_M, far)
	var left_near := Vector3(front.x - half, base, near)
	var right_near := Vector3(front.x + half, base, near)
	var left_far := Vector3(front.x - half, base, far)
	var right_far := Vector3(front.x + half, base, far)
	_triangle(tool, left_near, right_near, apex_near, Vector3.FORWARD, UV_LIGHT_STONE)
	_triangle(tool, left_far, right_far, apex_far, Vector3.BACK, UV_LIGHT_STONE)
	_quad(tool, left_near, apex_near, apex_far, left_far, Vector3(-1.0, 1.0, 0.0), UV_LIGHT_STONE)
	_quad(tool, right_near, apex_near, apex_far, right_far, Vector3(1.0, 1.0, 0.0), UV_LIGHT_STONE)


## Grade de ferro de a até b (no chão da sacada, em x ou em z): corrimão, travessa de baixo e balaústres. A
## varanda da casa de engenho (Fase 23) usa a mesma, de madeira, mais baixa e de balaústre grosso.
static func _railing(tool: SurfaceTool, a: Vector3, b: Vector3, uv := UV_IRON, height := RAIL_M, bar := 0.03,
		step := RAIL_STEP_M) -> void:
	var along := b - a
	var length := along.length()
	if length < 0.05:
		return
	var along_x := absf(along.x) > absf(along.z)
	var middle := (a + b) * 0.5
	for rail: Vector2 in [Vector2(height, bar * 2.0), Vector2(0.12, bar * 1.3)]:
		_box(tool, middle + Vector3(0.0, rail.x, 0.0),
				Vector3(length, rail.y, rail.y) if along_x else Vector3(rail.y, rail.y, length), uv)
	var count := maxi(1, roundi(length / step))
	for i: int in count + 1:
		var at := a + along * (float(i) / count)
		_box(tool, at + Vector3(0.0, height * 0.5, 0.0), Vector3(bar, height, bar), uv)


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
