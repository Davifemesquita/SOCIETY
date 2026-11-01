class_name FieldStoneView
extends Node3D
## Fase 249: os montes de pedra nos campos. Num campo com dono (pelo `module_owner`) das ilhas temperadas a cada STONE_EVERY pelo id
## (resto STONE_REST), as pedras tiradas da terra arada amontoadas num canto da cabeceira (`spot`, no referencial das fileiras da
## `CropView`, depois do fim delas, sem tocar nas plantas): um monte baixo de pedras de vários tamanhos e tons, em três camadas
## (`heap_mesh`). Um MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de mundo (o dono do campo sai do estado
## derivado).

const STONE_EVERY := 3
const STONE_REST := 1
## O monte: as pedras de cada camada (de baixo para cima), o raio de cada camada e as meias medidas da pedra média.
const LAYERS: Array[int] = [7, 4, 1]
const LAYER_RADIUS_M: Array[float] = [0.28, 0.15, 0.0]
const STONE_HALF := Vector3(0.12, 0.08, 0.1)
const STONES: Array[Color] = [Color(0.56, 0.54, 0.5), Color(0.48, 0.46, 0.42), Color(0.62, 0.58, 0.52), Color(0.44, 0.4, 0.36)]

var _simulation: Simulation
var _heaps := MultiMeshInstance3D.new()
## Os lugares dos montes (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	_heaps.name = "FieldStones"
	_heaps.multimesh = MultiMesh.new()
	_heaps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_heaps.multimesh.mesh = heap_mesh()
	_heaps.material_override = material
	add_child(_heaps)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func heap_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var owners := _simulation.derived_state().module_owner
	for id: int in _simulation.world.building_ids():
		var found: Variant = spot(_simulation, _simulation.world.building(id), owners)
		if found is Transform3D:
			places.append(found)
	_heaps.multimesh.instance_count = places.size()
	for i: int in places.size():
		_heaps.multimesh.set_instance_transform(i, places[i])
	_heaps.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## Onde fica o monte de pedras do campo (mundo: o pé no chão) ou null: só no campo do resto certo, com dono, numa ilha temperada.
## O canto da cabeceira sai do id: uma das quatro pontas, depois do fim das fileiras e para dentro da borda.
static func spot(simulation: Simulation, record: BuildingRecord, owners: Dictionary[int, int]) -> Variant:
	if record == null or posmod(record.id, STONE_EVERY) != STONE_REST:
		return null
	var def := simulation.def_of(record)
	if def == null or def.kind != BuildingDef.Kind.MODULE or def.id == CropView.PASTURE:
		return null
	var owner_id: int = owners.get(record.id, 0)
	if simulation.world.building(owner_id) == null:
		return null
	if simulation.world.is_tropical(record.island_id, simulation.data):
		return null
	var grid := simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var frame := CropView._row_frame(record)
	var half := Vector2(area.size) * simulation.config.cell_size_m * 0.5 - Vector2(CropView.HEADLAND_M, CropView.MARGIN_M)
	var sx := 1.0 if posmod(record.id / STONE_EVERY, 2) == 0 else -1.0
	var sz := 1.0 if posmod(record.id / (STONE_EVERY * 2), 2) == 0 else -1.0
	var point := center + frame * Vector3(sx * (half.x + CropView.HEADLAND_M * 0.55), 0.0, sz * maxf(half.y - 0.35, 0.0))
	point.y = grid.height_at(point.x, point.z)
	return Transform3D(frame * Basis(Vector3.UP, float(posmod(record.id * 37, 360)) * PI / 180.0), point)


## O monte com o pé no zero: as pedras em três camadas, cada uma um bloco girado à toa, de tamanho e tom pelo número dela.
static func heap_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 0
	var y := STONE_HALF.y * 1.05
	for layer: int in LAYERS.size():
		var stones: int = LAYERS[layer]
		for k: int in stones:
			var angle := TAU * k / stones + 0.4 * layer
			var radius: float = LAYER_RADIUS_M[layer] * (0.85 + 0.1 * (count % 3))
			var size := STONE_HALF * (0.75 + 0.15 * float(posmod(count * 5, 4)))
			var turn := Basis(Vector3.UP, 0.9 * count) * Basis(Vector3.RIGHT, 0.25 * float(posmod(count * 3, 5) - 2)) \
					* Basis(Vector3.BACK, 0.2 * float(posmod(count * 7, 5) - 2))
			VertexShapes.oriented_box(tool, Transform3D(turn, Vector3(cos(angle) * radius, y, sin(angle) * radius)), size,
					STONES[count % STONES.size()])
			count += 1
		y += STONE_HALF.y * 1.2
	tool.generate_normals()
	return tool.commit()
