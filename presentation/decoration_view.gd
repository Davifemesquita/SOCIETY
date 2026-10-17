class_name DecorationView
extends Node3D
## Decoração (Fase 16): árvore plantada, canteiro de flores e banco de praça, gerados aqui com a cor no
## vértice, um MultiMesh por tipo, no meio da área do prédio e girados com ele. Decoração sem malha própria
## fica numa caixa na cor do BuildingDef. Refeito quando prédio ou mundo muda. Só lê o mundo.

var _simulation: Simulation
var _layers: Dictionary[StringName, MultiMeshInstance3D] = {}
var _material := StandardMaterial3D.new()
var _range_m: float = 260.0
var _dirty: bool = false


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 0.9
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	for layer: MultiMeshInstance3D in _layers.values():
		layer.visibility_range_end = _range_m


## Peças de decoração à vista de um tipo (ou de todos, com o id vazio).
func piece_count(def_id: StringName = &"") -> int:
	var total := 0
	for id: StringName in _layers:
		if def_id.is_empty() or id == def_id:
			total += _layers[id].multimesh.instance_count
	return total


## As casas da ilha a até o raio de beleza da decoração (painel do prédio).
static func houses_near(simulation: Simulation, record: BuildingRecord) -> Array[int]:
	var def := simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var result: Array[int] = []
	for house_id: int in simulation.derived_state().houses:
		var house := simulation.world.building(house_id)
		if house.island_id != record.island_id:
			continue
		var house_area := Footprint.rect(house.origin, simulation.def_of(house).size, house.rotation)
		if DerivedState._rect_gap(area, house_area) <= def.beauty_radius_cells:
			result.append(house_id)
	return result


func _process(_delta: float) -> void:
	if _dirty:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places: Dictionary[StringName, Array] = {}
	var world := _simulation.world
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if not def.is_decoration():
			continue
		if not places.has(def.id):
			places[def.id] = []
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var center := world.island(record.island_id).rect_world(area)
		var list: Array = places[def.id]
		list.append(Transform3D(Basis(Vector3.UP, -PI * 0.5 * posmod(record.rotation, 4)), center))
	for id: StringName in places:
		if not _layers.has(id):
			_layers[id] = _layer(_simulation.data.building(id))
	for id: StringName in _layers:
		var list: Array = places.get(id, [])
		var multimesh := _layers[id].multimesh
		multimesh.instance_count = list.size()
		for i: int in list.size():
			var place: Transform3D = list[i]
			multimesh.set_instance_transform(i, place)


func _layer(def: BuildingDef) -> MultiMeshInstance3D:
	var layer := MultiMeshInstance3D.new()
	layer.name = String(def.id)
	layer.multimesh = MultiMesh.new()
	layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	layer.multimesh.mesh = mesh_for(def, _simulation.config.cell_size_m)
	layer.material_override = _material
	layer.visibility_range_end = _range_m
	add_child(layer)
	return layer


## A malha da decoração, de frente para −Z, com a base em y = 0 e o meio em x = z = 0.
static func mesh_for(def: BuildingDef, cell_size: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match def.id:
		&"planted_tree":
			_tree(tool)
		&"flower_bed":
			_flower_bed(tool, cell_size)
		&"park_bench":
			_bench(tool)
		_:
			_box(tool, Vector3(0.0, def.height_m * 0.5, 0.0), Vector3(def.size.x * cell_size * 0.4, def.height_m * 0.5,
					def.size.y * cell_size * 0.4), def.color)
	tool.generate_normals()
	return tool.commit()


## Árvore nova de praça: tronco fino com o tutor de madeira e a copa em três volumes.
static func _tree(tool: SurfaceTool) -> void:
	_box(tool, Vector3(0.0, 1.0, 0.0), Vector3(0.09, 1.0, 0.09), Color(0.36, 0.26, 0.18))
	_box(tool, Vector3(0.22, 0.75, 0.0), Vector3(0.03, 0.75, 0.03), Color(0.55, 0.45, 0.32))
	var leaves := Color(0.27, 0.46, 0.2)
	CarriedGoods._lump(tool, Vector3(0.0, 2.3, 0.0), Vector3(0.75, 0.6, 0.75), leaves)
	CarriedGoods._lump(tool, Vector3(0.25, 2.8, 0.15), Vector3(0.55, 0.5, 0.55), leaves.lightened(0.1))
	CarriedGoods._lump(tool, Vector3(-0.2, 2.75, -0.2), Vector3(0.5, 0.45, 0.5), leaves.darkened(0.1))


## Canteiro: moldura baixa de tábuas, terra e flores de três cores em fileiras.
static func _flower_bed(tool: SurfaceTool, cell_size: float) -> void:
	var half := cell_size * 0.42
	var wood := Color(0.42, 0.31, 0.2)
	for side: float in [-1.0, 1.0]:
		_box(tool, Vector3(side * half, 0.12, 0.0), Vector3(0.05, 0.12, half), wood)
		_box(tool, Vector3(0.0, 0.12, side * half), Vector3(half, 0.12, 0.05), wood)
	_box(tool, Vector3(0.0, 0.09, 0.0), Vector3(half - 0.05, 0.09, half - 0.05), Color(0.3, 0.22, 0.15))
	var colors: Array[Color] = [Color(0.85, 0.2, 0.3), Color(0.95, 0.8, 0.25), Color(0.6, 0.35, 0.8)]
	var rows := 4
	for row: int in rows:
		for column: int in rows:
			var x := (column + 0.5) / rows * 2.0 * (half - 0.15) - (half - 0.15)
			var z := (row + 0.5) / rows * 2.0 * (half - 0.15) - (half - 0.15)
			CarriedGoods._lump(tool, Vector3(x, 0.26, z), Vector3(0.12, 0.09, 0.12), Color(0.28, 0.5, 0.22))
			CarriedGoods._lump(tool, Vector3(x, 0.36, z), Vector3(0.07, 0.05, 0.07), colors[(row + column) % colors.size()])


## Banco de praça de ripas com pés de ferro, de frente para −Z (quem senta olha para a frente do prédio).
static func _bench(tool: SurfaceTool) -> void:
	var wood := Color(0.5, 0.36, 0.22)
	var iron := Color(0.15, 0.15, 0.16)
	for x: float in [-0.65, 0.65]:
		_box(tool, Vector3(x, 0.22, 0.0), Vector3(0.04, 0.22, 0.22), iron)
		_box(tool, Vector3(x, 0.6, 0.2), Vector3(0.04, 0.2, 0.03), iron)
	for z: float in [-0.14, 0.0, 0.14]:
		_box(tool, Vector3(0.0, 0.45, z), Vector3(0.75, 0.025, 0.055), wood)
	for y: float in [0.62, 0.76]:
		_box(tool, Vector3(0.0, y, 0.22), Vector3(0.75, 0.05, 0.02), wood)


## Caixa de meia-medida half em volta de center (as seis faces).
static func _box(tool: SurfaceTool, center: Vector3, half: Vector3, color: Color) -> void:
	tool.set_color(color)
	var corners: Array[Vector3] = []
	for i: int in 8:
		corners.append(center + Vector3(half.x if i & 1 else -half.x, half.y if i & 2 else -half.y, half.z if i & 4 else -half.z))
	# cada face com os cantos em volta (anti-horário de fora); o Godot quer o horário, então a ordem vira
	var faces := [[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4], [2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5]]
	for face: Array in faces:
		var a: Vector3 = corners[face[0]]
		var b: Vector3 = corners[face[1]]
		var c: Vector3 = corners[face[2]]
		var d: Vector3 = corners[face[3]]
		for vertex: Vector3 in [a, c, b, a, d, c]:
			tool.add_vertex(vertex)
