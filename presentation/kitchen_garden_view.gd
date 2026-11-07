class_name KitchenGardenView
extends Node3D
## Fase 163: a horta no quintal. Na célula livre atrás de uma casa de camponeses ou operários a cada GARDEN_EVERY pelo id, com o
## resto GARDEN_REST (a fogueira da LampView usa o resto 0 e o varal da YardView o 1: os três nunca disputam a célula), o
## canteiro de terra escura com a beirada de tábuas, uma fileira de couves, uma de alfaces e três varas de feijão amarradas em
## tenda com as folhas subindo (`garden_mesh`), as fileiras ao longo da parede de trás. O recheio e as bombas d'água deixam a
## célula limpa (`cells`). Uma malha só para o arquipélago; nada no save; refeita na obra, na demolição, na subida de classe, na
## estrada e ao trocar de mundo.

const TIERS: Array[StringName] = [&"peasants", &"workers"]
const GARDEN_EVERY := 3
const GARDEN_REST := 2
## O canteiro: o lado (cabe na célula de 2 m com folga), a altura da terra e a beirada.
const BED_M := 1.7
const BED_UP_M := 0.08
const EDGE_M := 0.05
const SOIL := Color(0.24, 0.17, 0.11)
const BOARD := Color(0.42, 0.31, 0.2)
const CABBAGE := Color(0.32, 0.5, 0.26)
const CABBAGE_DARK := Color(0.22, 0.38, 0.2)
const LETTUCE := Color(0.5, 0.68, 0.28)
const POLE := Color(0.46, 0.36, 0.24)
const BEAN_LEAF := Color(0.27, 0.46, 0.18)

var _simulation: Simulation
var _gardens := MeshInstance3D.new()
var _count := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_gardens.name = "KitchenGardens"
	_gardens.material_override = material
	add_child(_gardens)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func garden_count() -> int:
	return _count


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_count = 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var record := world.building(found[cell])
			var back := -Footprint.front_direction(record.rotation)
			var middle := grid.surface_world(cell)
			# o x do canteiro ao longo da parede de trás, o +Z para longe da casa (base de mão direita: x = cima × fora)
			var out := Vector3(back.x, 0.0, back.y)
			garden_mesh(tool, Transform3D(Basis(Vector3.UP.cross(out), Vector3.UP, out), middle))
			_count += 1
	if _count == 0:
		_gardens.mesh = null
		return
	tool.generate_normals()
	_gardens.mesh = tool.commit()


## As hortas da ilha: a célula de cada uma → o id da casa.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id or not record.is_house() or not TIERS.has(record.tier) \
				or posmod(id, GARDEN_EVERY) != GARDEN_REST:
			continue
		var found: Variant = spot(world, data, record)
		if found is Vector2i:
			var cell: Vector2i = found
			result[cell] = id
	return result


## A célula da horta da casa (a de trás, a mesma da fogueira e do varal: LampView.bonfire_spot) ou null se ela não está livre.
static func spot(world: WorldState, data: GameData, record: BuildingRecord) -> Variant:
	var grid := world.island(record.island_id)
	var def := data.building(record.def_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var back := -Footprint.front_direction(record.rotation)
	var entrance := Footprint.entrance_cell(record.origin, def.size, record.rotation)
	# a célula de entrada fica fora, na frente: a de trás está a profundidade + 1 depois dela
	var depth := area.size.y if posmod(record.rotation, 2) == 0 else area.size.x
	var behind := entrance + back * (depth + 1)
	if not grid.in_bounds(behind) or area.has_point(behind) or grid.building_at(behind) != 0 or grid.has_road(behind) \
			or not grid.is_land(behind):
		return null
	return behind


## A horta no referencial place (x ao longo da parede de trás, +Z para longe da casa, o pé no chão): o canteiro com a beirada,
## as couves na fileira de perto da casa, as alfaces no meio e a tenda de feijão no fundo.
static func garden_mesh(tool: SurfaceTool, place: Transform3D) -> void:
	var half := BED_M * 0.5
	VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, BED_UP_M * 0.5 - 0.03, 0.0)),
			Vector3(half - EDGE_M, BED_UP_M * 0.5 + 0.03, half - EDGE_M), SOIL)
	for side: float in [-1.0, 1.0]:
		VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(0.0, BED_UP_M * 0.5, side * (half - EDGE_M * 0.5))),
				Vector3(half, BED_UP_M * 0.5 + 0.02, EDGE_M * 0.5), BOARD)
		VertexShapes.oriented_box(tool, place * Transform3D(Basis.IDENTITY, Vector3(side * (half - EDGE_M * 0.5), BED_UP_M * 0.5, 0.0)),
				Vector3(EDGE_M * 0.5, BED_UP_M * 0.5 + 0.02, half - EDGE_M), BOARD)
	var top := BED_UP_M
	# couves: quatro bolas de folhas, cada uma com a cabeça e duas folhas abertas
	for k: int in 4:
		var at := Vector3(-half + 0.3 + k * 0.37, top, -0.45)
		_blob(tool, 0.13, place * Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.0)),
				at + Vector3(0.0, 0.1, 0.0)), CABBAGE if k % 2 == 0 else CABBAGE_DARK)
		for leaf: int in 2:
			var angle := k * 1.3 + leaf * PI
			_blob(tool, 0.1, place * Transform3D(Basis(Vector3.UP, angle)
					* Basis.from_scale(Vector3(1.4, 0.35, 0.8)), at + Vector3(cos(angle) * 0.1, 0.04, sin(angle) * 0.1)),
					CABBAGE_DARK)
	# alfaces: cinco rosetas baixas e claras
	for k: int in 5:
		var at := Vector3(-half + 0.25 + k * 0.3, top, 0.0)
		_blob(tool, 0.1, place * Transform3D(Basis.from_scale(Vector3(1.2, 0.55, 1.2)),
				at + Vector3(0.0, 0.05, 0.0)), LETTUCE)
	# feijão: três varas amarradas no alto em tenda, com as folhas subindo por elas
	var tie := place * Vector3(0.0, top + 1.45, 0.48)
	for k: int in 3:
		var angle := TAU * k / 3.0 + 0.3
		var foot := place * Vector3(cos(angle) * 0.38, top, 0.48 + sin(angle) * 0.28)
		VertexShapes.strut(tool, foot, tie + (tie - foot).normalized() * 0.1, 0.015, 0.015, POLE)
		for leaf: int in 4:
			var at := foot.lerp(tie, 0.2 + leaf * 0.2)
			_blob(tool, 0.07, Transform3D(place.basis * Basis(Vector3.UP, leaf * 1.9)
					* Basis.from_scale(Vector3(1.3, 0.5, 1.0)), at), BEAN_LEAF)


## Uma bolinha de folhas de raio radius no referencial place (a esfera baixa do CropView, sem normal: o generate_normals da
## horta a faz junto com as caixas, que também chegam sem).
static func _blob(tool: SurfaceTool, radius: float, place: Transform3D, color: Color) -> void:
	var arrays := CropView._sphere(radius).get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index: int in indices:
		tool.set_color(color)
		tool.add_vertex(place * vertices[index])
