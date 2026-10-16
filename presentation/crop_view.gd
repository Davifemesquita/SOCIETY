class_name CropView
extends Node3D
## Plantações nos campos (Fase 14): o campo que tem dono ganha fileiras da planta da fazenda dele
## (BuildingDef.crop), crescendo com o ciclo da fazenda (BuildingRecord.progress): curta e verde no começo,
## alta (e dourada, no cereal) perto da colheita. Campo sem dono fica só a terra arada. As plantas são
## geradas aqui (cor no vértice), um MultiMesh por planta; o crescimento reescreve só as instâncias do
## campo que mudou. Só lê o mundo.

const REFRESH_SECONDS := 0.5
## O crescimento anda em degraus (menos reescrita), e a planta nova já aparece com este tamanho.
const GROWTH_STEPS := 20
const MIN_GROWTH := 0.25
## Folga das plantas até a borda do campo e quanto cada uma sai do lugar da grade.
const MARGIN_M := 0.45
const JITTER_M := 0.08
## Cereal verde no começo do ciclo (a cor da instância multiplica a do vértice).
const GREEN_TINT := Color(0.55, 1.0, 0.45)

## Por planta: espaço entre plantas na fileira e entre fileiras (m).
const SPACING := {
	BuildingDef.Crop.GRAIN: Vector2(0.45, 0.45),
	BuildingDef.Crop.TUBER: Vector2(0.6, 0.75),
	BuildingDef.Crop.HOPS: Vector2(1.2, 1.5),
	BuildingDef.Crop.VINE: Vector2(0.9, 1.5),
	BuildingDef.Crop.CANE: Vector2(0.6, 0.8),
	BuildingDef.Crop.BUSH: Vector2(1.1, 1.2),
	BuildingDef.Crop.BROADLEAF: Vector2(0.8, 0.9),
}

var _simulation: Simulation
var _layers: Dictionary[int, MultiMeshInstance3D] = {}
## Por campo: [planta, primeira instância, quantidade, lugares (Array[Transform3D]), id da fazenda].
var _fields: Dictionary[int, Array] = {}
var _growth: Dictionary[int, int] = {}
var _range_m: float = 260.0
var _refresh_left: float = 0.0
var _dirty: bool = false

static var _meshes: Dictionary[int, ArrayMesh] = {}


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	for crop: int in SPACING:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = plant_mesh(crop)
		multimesh.visible_instance_count = 0
		var layer := MultiMeshInstance3D.new()
		layer.name = "Crop%d" % crop
		layer.multimesh = multimesh
		layer.material_override = material
		add_child(layer)
		_layers[crop] = layer
	_apply_range()
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	_apply_range()


## Plantas à vista de uma planta (BuildingDef.Crop) ou de todas (-1).
func plant_count(crop: int = -1) -> int:
	var total := 0
	for kind: int in _layers:
		if crop < 0 or kind == crop:
			total += _layers[kind].multimesh.visible_instance_count
	return total


## Quanto o campo cresceu (0..1, em degraus); -1 se ele não tem plantas.
func growth_of(field_id: int) -> float:
	return float(_growth[field_id]) / GROWTH_STEPS if _growth.has(field_id) else -1.0


## Lugar da planta index do campo (mundo), já com o tamanho do crescimento.
func plant_transform(field_id: int, index: int) -> Transform3D:
	var field: Array = _fields[field_id]
	var crop: int = field[0]
	var first: int = field[1]
	return _layers[crop].multimesh.get_instance_transform(first + index)


func _process(delta: float) -> void:
	if _dirty:
		rebuild()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()


## Refaz a grade de plantas de todos os campos com dono.
func rebuild() -> void:
	_dirty = false
	_fields.clear()
	_growth.clear()
	var world := _simulation.world
	var derived := _simulation.derived_state()
	var lists: Dictionary[int, Array] = {}
	for crop: int in _layers:
		lists[crop] = []
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if def.kind != BuildingDef.Kind.MODULE:
			continue
		var owner_id: int = derived.module_owner.get(building_id, 0)
		var farm := world.building(owner_id)
		if farm == null:
			continue
		var crop := _simulation.def_of(farm).crop
		if not _layers.has(crop):
			continue
		var places := _plant_places(record, def, crop)
		var list: Array = lists[crop]
		_fields[building_id] = [crop, list.size(), places.size(), places, owner_id]
		list.append_array(places)
	for crop: int in lists:
		var multimesh := _layers[crop].multimesh
		var count: int = lists[crop].size()
		if multimesh.instance_count < count:
			multimesh.visible_instance_count = -1
			multimesh.instance_count = count + 64
		multimesh.visible_instance_count = count
	for field_id: int in _fields:
		_draw_field(field_id)


## Confere o ciclo de cada fazenda e redesenha os campos que cresceram (ou foram colhidos).
func refresh() -> void:
	for field_id: int in _fields:
		var field: Array = _fields[field_id]
		var farm_id: int = field[4]
		var farm := _simulation.world.building(farm_id)
		if farm == null:
			_dirty = true
			return
		if _step(farm) != _growth.get(field_id, -1):
			_draw_field(field_id)


func _step(farm: BuildingRecord) -> int:
	return clampi(roundi(farm.progress * GROWTH_STEPS), 0, GROWTH_STEPS)


func _draw_field(field_id: int) -> void:
	var field: Array = _fields[field_id]
	var crop: int = field[0]
	var first: int = field[1]
	var places: Array = field[3]
	var farm_id: int = field[4]
	var farm := _simulation.world.building(farm_id)
	var step := _step(farm)
	_growth[field_id] = step
	var growth := lerpf(MIN_GROWTH, 1.0, float(step) / GROWTH_STEPS)
	var size := Vector3(lerpf(0.6, 1.0, growth), growth, lerpf(0.6, 1.0, growth))
	var tint := GREEN_TINT.lerp(Color.WHITE, float(step) / GROWTH_STEPS) if crop == BuildingDef.Crop.GRAIN else Color.WHITE
	var multimesh := _layers[crop].multimesh
	for index: int in places.size():
		var place: Transform3D = places[index]
		multimesh.set_instance_transform(first + index, Transform3D(place.basis.scaled_local(size), place.origin))
		multimesh.set_instance_color(first + index, tint)


## Lugares das plantas no campo (mundo, tamanho cheio): fileiras pelo espaço da planta, com a folga da
## borda, um pouco tortas e giradas pelo id (o mesmo depois de carregar).
func _plant_places(record: BuildingRecord, def: BuildingDef, crop: int) -> Array:
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area) + Vector3(0.0, def.height_m, 0.0)
	var cell_size := _simulation.config.cell_size_m
	var half := Vector2(area.size) * cell_size * 0.5 - Vector2(MARGIN_M, MARGIN_M)
	var spacing: Vector2 = SPACING[crop]
	var columns := maxi(1, floori(half.x * 2.0 / spacing.x) + 1)
	var rows := maxi(1, floori(half.y * 2.0 / spacing.y) + 1)
	var start := Vector2(-(columns - 1) * spacing.x * 0.5, -(rows - 1) * spacing.y * 0.5)
	var result: Array = []
	for row: int in rows:
		for column: int in columns:
			var noise := hash([record.id, row, column])
			var jitter := Vector2(float(noise % 1000) / 1000.0 - 0.5, float(noise / 1000 % 1000) / 1000.0 - 0.5) * 2.0 * JITTER_M
			var turn := float(noise / 1000000 % 628) / 100.0
			# parreira e lúpulo seguem a fileira: giro só de meia volta
			if crop in [BuildingDef.Crop.VINE, BuildingDef.Crop.HOPS]:
				turn = PI * float(noise % 2)
			var offset := start + Vector2(column * spacing.x, row * spacing.y) + jitter
			result.append(Transform3D(Basis(Vector3.UP, turn), center + Vector3(offset.x, 0.0, offset.y)))
	return result


func _apply_range() -> void:
	for layer: MultiMeshInstance3D in _layers.values():
		layer.visibility_range_end = _range_m
		layer.visibility_range_end_margin = _range_m * 0.1
		layer.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


## A planta de cada tipo, com a base em y = 0 e a altura cheia (cor no vértice), feita uma vez.
static func plant_mesh(crop: int) -> ArrayMesh:
	if _meshes.has(crop):
		return _meshes[crop]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match crop:
		BuildingDef.Crop.GRAIN:
			# touceira de colmos com a espiga em cima
			for i: int in 6:
				var angle := TAU * i / 6.0
				var lean := Basis(Vector3(cos(angle), 0.0, sin(angle)).cross(Vector3.UP), 0.12)
				var foot := Vector3(cos(angle), 0.0, sin(angle)) * 0.06
				_part(tool, _box(Vector3(0.025, 0.9, 0.025)), Transform3D(lean, foot + lean * Vector3(0.0, 0.45, 0.0)),
						Color(0.78, 0.66, 0.3))
				_part(tool, _box(Vector3(0.06, 0.2, 0.06)), Transform3D(lean, foot + lean * Vector3(0.0, 0.98, 0.0)),
						Color(0.9, 0.74, 0.32))
		BuildingDef.Crop.TUBER:
			for i: int in 3:
				var angle := TAU * i / 3.0
				_part(tool, _sphere(0.22), Transform3D(Basis.from_scale(Vector3(1.0, 0.65, 1.0)),
						Vector3(cos(angle), 0.0, sin(angle)) * 0.13 + Vector3(0.0, 0.14, 0.0)), Color(0.24, 0.42, 0.17))
		BuildingDef.Crop.HOPS:
			_part(tool, _cylinder(0.04, 3.2), Transform3D(Basis.IDENTITY, Vector3(0.0, 1.6, 0.0)), Color(0.42, 0.31, 0.2))
			_part(tool, _cylinder(0.2, 2.5), Transform3D(Basis.IDENTITY, Vector3(0.0, 1.65, 0.0)), Color(0.32, 0.52, 0.2))
			_part(tool, _sphere(0.26), Transform3D(Basis.IDENTITY, Vector3(0.0, 2.95, 0.0)), Color(0.42, 0.6, 0.25))
		BuildingDef.Crop.VINE:
			_part(tool, _box(Vector3(0.06, 1.3, 0.06)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.65, 0.0)), Color(0.4, 0.3, 0.2))
			_part(tool, _box(Vector3(0.25, 0.6, 0.85)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.85, 0.0)), Color(0.27, 0.44, 0.19))
			for i: int in 3:
				_part(tool, _sphere(0.08), Transform3D(Basis.IDENTITY, Vector3(0.14 * (1 - 2 * (i % 2)), 0.55, -0.25 + 0.25 * i)),
						Color(0.32, 0.12, 0.3))
		BuildingDef.Crop.CANE:
			for i: int in 5:
				var angle := TAU * i / 5.0
				var foot := Vector3(cos(angle), 0.0, sin(angle)) * 0.1
				var lean := Basis(Vector3(cos(angle), 0.0, sin(angle)).cross(Vector3.UP), 0.08)
				_part(tool, _cylinder(0.035, 2.4), Transform3D(lean, foot + lean * Vector3(0.0, 1.2, 0.0)), Color(0.48, 0.62, 0.26))
				_part(tool, _box(Vector3(0.6, 0.02, 0.08)), Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.BACK, -0.5),
						foot + Vector3(0.0, 2.1, 0.0)), Color(0.36, 0.56, 0.2))
		BuildingDef.Crop.BUSH:
			_part(tool, _sphere(0.45), Transform3D(Basis.from_scale(Vector3(1.0, 1.1, 1.0)), Vector3(0.0, 0.55, 0.0)),
					Color(0.17, 0.34, 0.14))
			for i: int in 5:
				var angle := TAU * i / 5.0
				_part(tool, _sphere(0.06), Transform3D(Basis.IDENTITY, Vector3(cos(angle) * 0.42, 0.55 + 0.15 * (i % 2),
						sin(angle) * 0.42)), Color(0.72, 0.16, 0.1))
		BuildingDef.Crop.BROADLEAF:
			_part(tool, _cylinder(0.03, 0.9), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.45, 0.0)), Color(0.4, 0.55, 0.22))
			for i: int in 6:
				var angle := TAU * i / 6.0 + i * 0.4
				var height := 0.2 + 0.12 * i
				_part(tool, _box(Vector3(0.5 - 0.04 * i, 0.02, 0.2)), Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.BACK, -0.35),
						Vector3(cos(-angle), 0.0, sin(-angle)) * 0.2 + Vector3(0.0, height, 0.0)), Color(0.34, 0.54, 0.2))
	tool.index()
	var mesh := tool.commit()
	_meshes[crop] = mesh
	return mesh


static func _part(tool: SurfaceTool, mesh: PrimitiveMesh, place: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index: int in indices:
		tool.set_color(color)
		tool.set_normal((place.basis * normals[index]).normalized())
		tool.add_vertex(place * vertices[index])


static func _box(size: Vector3) -> BoxMesh:
	var box := BoxMesh.new()
	box.size = size
	return box


static func _sphere(radius: float) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	return sphere


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 6
	cylinder.rings = 1
	return cylinder
