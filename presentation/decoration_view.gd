class_name DecorationView
extends Node3D
## Decoração (Fase 16): árvore plantada, canteiro de flores, banco de praça, praça calçada com chafariz, estátua e
## coreto,
## gerados aqui com a cor no vértice, um MultiMesh por tipo, no meio da área do prédio e girados com ele. O
## jato do chafariz é um CPUParticles3D por praça. Decoração sem malha própria fica numa caixa na cor do
## BuildingDef. Refeito quando prédio ou mundo muda. Só lê o mundo.

## Chafariz: altura da bica (acima do chão da praça) e quantas gotas no ar.
const SPOUT_HEIGHT_M := 2.1
const JET_DROPS := 48
const WATER := Color(0.45, 0.62, 0.72)
const STONE := Color(0.62, 0.6, 0.56)
## Bronze com azinhavre (estátua) e o branco do coreto.
const BRONZE := Color(0.32, 0.45, 0.38)
const PAINT := Color(0.9, 0.88, 0.82)

var _simulation: Simulation
var _layers: Dictionary[StringName, MultiMeshInstance3D] = {}
## Jato de cada chafariz, pelo id da praça.
var _jets: Dictionary[int, CPUParticles3D] = {}
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
	for jet: CPUParticles3D in _jets.values():
		jet.visibility_range_end = _range_m


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


func jet_count() -> int:
	return _jets.size()


func _process(_delta: float) -> void:
	if _dirty:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var places: Dictionary[StringName, Array] = {}
	var world := _simulation.world
	var fountains: Dictionary[int, Vector3] = {}
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
		if def.id == &"fountain_square":
			fountains[building_id] = center
	for building_id: int in _jets.keys():
		if not fountains.has(building_id):
			_jets[building_id].queue_free()
			_jets.erase(building_id)
	for building_id: int in fountains:
		if not _jets.has(building_id):
			_jets[building_id] = _jet()
			add_child(_jets[building_id])
		_jets[building_id].position = fountains[building_id] + Vector3(0.0, SPOUT_HEIGHT_M, 0.0)
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
			_bench(tool, Vector3.ZERO, false)
		&"fountain_square":
			_fountain_square(tool, def.size.x * cell_size)
		&"statue":
			_statue(tool, def.size.x * cell_size)
		&"bandstand":
			_bandstand(tool, def.size.x * cell_size)
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


## Banco de praça de ripas com pés de ferro em at, de frente para −Z (quem senta olha para a frente do
## prédio); flip vira para +Z.
static func _bench(tool: SurfaceTool, at: Vector3, flip: bool) -> void:
	var wood := Color(0.5, 0.36, 0.22)
	var iron := Color(0.15, 0.15, 0.16)
	var back := -1.0 if flip else 1.0
	for x: float in [-0.65, 0.65]:
		_box(tool, at + Vector3(x, 0.22, 0.0), Vector3(0.04, 0.22, 0.22), iron)
		_box(tool, at + Vector3(x, 0.6, 0.2 * back), Vector3(0.04, 0.2, 0.03), iron)
	for z: float in [-0.14, 0.0, 0.14]:
		_box(tool, at + Vector3(0.0, 0.45, z), Vector3(0.75, 0.025, 0.055), wood)
	for y: float in [0.62, 0.76]:
		_box(tool, at + Vector3(0.0, y, 0.22 * back), Vector3(0.75, 0.05, 0.02), wood)


## Praça calçada de side metros: lajes de pedra em tons, meio-fio em volta, chafariz de bacia octogonal com
## a coluna e a taça de cima no meio, e dois bancos virados para ele.
static func _fountain_square(tool: SurfaceTool, side: float) -> void:
	var half := side * 0.5 - 0.05
	var tile := 0.75
	var count := int(half * 2.0 / tile)
	for i: int in count:
		for k: int in count:
			var x := -half + (i + 0.5) * half * 2.0 / count
			var z := -half + (k + 0.5) * half * 2.0 / count
			var tone := 0.92 + fposmod((i * 7 + k * 13) * 0.618, 1.0) * 0.16
			_box(tool, Vector3(x, 0.05, z), Vector3(half / count - 0.025, 0.05, half / count - 0.025), STONE * tone)
	for edge: float in [-1.0, 1.0]:
		_box(tool, Vector3(edge * half, 0.09, 0.0), Vector3(0.08, 0.09, half), STONE.darkened(0.15))
		_box(tool, Vector3(0.0, 0.09, edge * half), Vector3(half, 0.09, 0.08), STONE.darkened(0.15))
	# bacia: oito muretas em volta da água
	var radius := 1.3
	for i: int in 8:
		var angle := TAU * i / 8.0
		var wall := Vector3(cos(angle), 0.0, sin(angle)) * radius
		_wall(tool, wall + Vector3(0.0, 0.3, 0.0), angle, Vector3(0.12, 0.2, radius * 0.42), STONE.lightened(0.05))
	_box(tool, Vector3(0.0, 0.32, 0.0), Vector3(radius * 0.88, 0.02, radius * 0.88), WATER)
	_box(tool, Vector3(0.0, 1.0, 0.0), Vector3(0.14, 0.7, 0.14), STONE)
	CarriedGoods._lump(tool, Vector3(0.0, 1.75, 0.0), Vector3(0.5, 0.12, 0.5), STONE.lightened(0.08))
	_box(tool, Vector3(0.0, 1.9, 0.0), Vector3(0.06, 0.2, 0.06), STONE.darkened(0.1))
	_bench(tool, Vector3(0.0, 0.1, -half + 0.45), true)
	_bench(tool, Vector3(0.0, 0.1, half - 0.45), false)


## Estátua de bronze sobre pedestal de dois degraus, num canteiro de grama: uma figura de pé, de casaca, com o
## braço direito estendido para a frente (−Z). Figura genérica, sem personagem.
static func _statue(tool: SurfaceTool, side: float) -> void:
	var half := side * 0.5 - 0.1
	_box(tool, Vector3(0.0, 0.03, 0.0), Vector3(half, 0.03, half), Color(0.33, 0.52, 0.25))
	_box(tool, Vector3(0.0, 0.15, 0.0), Vector3(1.1, 0.15, 1.1), STONE.darkened(0.08))
	_box(tool, Vector3(0.0, 0.4, 0.0), Vector3(0.85, 0.1, 0.85), STONE)
	_box(tool, Vector3(0.0, 1.05, 0.0), Vector3(0.5, 0.55, 0.5), STONE.lightened(0.05))
	_box(tool, Vector3(0.0, 1.65, 0.0), Vector3(0.6, 0.05, 0.6), STONE.darkened(0.05))
	var base := 1.7
	for x: float in [-0.12, 0.12]:
		_box(tool, Vector3(x, base + 0.45, 0.0), Vector3(0.08, 0.45, 0.09), BRONZE)
	CarriedGoods._lump(tool, Vector3(0.0, base + 1.25, 0.0), Vector3(0.3, 0.45, 0.2), BRONZE)
	CarriedGoods._lump(tool, Vector3(0.0, base + 0.95, 0.04), Vector3(0.28, 0.3, 0.22), BRONZE.darkened(0.08))
	CarriedGoods._lump(tool, Vector3(0.0, base + 1.85, 0.0), Vector3(0.13, 0.16, 0.13), BRONZE.lightened(0.05))
	_box(tool, Vector3(0.24, base + 1.45, -0.28), Vector3(0.05, 0.05, 0.3), BRONZE)
	_box(tool, Vector3(-0.24, base + 1.05, 0.0), Vector3(0.05, 0.3, 0.05), BRONZE)


## Coreto: piso octogonal elevado com degrau, oito colunas finas de ferro, guarda-corpo baixo entre elas
## (aberto na frente, −Z, para a escada) e telhado de oito águas com o pináculo.
static func _bandstand(tool: SurfaceTool, side: float) -> void:
	# o raio deixa a escada da frente dentro da área do prédio
	var radius := side * 0.5 - 0.7
	var floor_y := 0.6
	var iron := Color(0.18, 0.2, 0.2)
	for i: int in 8:
		var angle := TAU * (i + 0.5) / 8.0
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var tangent := radius * 0.42
		_wall(tool, out * (radius - 0.5) + Vector3(0.0, floor_y * 0.5, 0.0), angle, Vector3(0.5, floor_y * 0.5, tangent),
				STONE)
		_wall(tool, out * (radius + 0.15) + Vector3(0.0, 0.15, 0.0), angle, Vector3(0.18, 0.15, tangent + 0.08),
				STONE.darkened(0.1))
	# piso de tábuas em oito lados, com os cantos onde as muretas se encontram
	tool.set_color(Color(0.55, 0.42, 0.28))
	var corner := radius / cos(PI / 8.0)
	var deck := Vector3(0.0, floor_y + 0.02, 0.0)
	for i: int in 8:
		var a := TAU * i / 8.0
		var b := TAU * (i + 1) / 8.0
		for vertex: Vector3 in [Vector3(cos(a) * corner, deck.y, sin(a) * corner), Vector3(cos(b) * corner, deck.y, sin(b) * corner), deck]:
			tool.add_vertex(vertex)
	var top := floor_y + 2.6
	for i: int in 8:
		var angle := TAU * i / 8.0
		var post := Vector3(cos(angle), 0.0, sin(angle)) * (radius - 0.1)
		_box(tool, post + Vector3(0.0, (floor_y + top) * 0.5, 0.0), Vector3(0.06, (top - floor_y) * 0.5, 0.06), iron)
		var next_angle := TAU * (i + 1) / 8.0
		var next := Vector3(cos(next_angle), 0.0, sin(next_angle)) * (radius - 0.1)
		var middle := (post + next) * 0.5
		var facing := atan2(middle.z, middle.x)
		# guarda-corpo, menos no vão da escada (o lado que olha para −Z)
		if middle.z > -radius * 0.8:
			_wall(tool, middle + Vector3(0.0, floor_y + 0.5, 0.0), facing, Vector3(0.03, 0.04, post.distance_to(next) * 0.5), PAINT)
			_wall(tool, middle + Vector3(0.0, floor_y + 0.2, 0.0), facing, Vector3(0.03, 0.03, post.distance_to(next) * 0.5), PAINT)
	# a escada da frente
	for step: int in 3:
		# o degrau de cima fica no nível do piso (floor_y = 3 × 0,2)
		var rise := (step + 1) * floor_y / 3.0
		_box(tool, Vector3(0.0, rise * 0.5, -radius - 0.6 + step * 0.3), Vector3(0.7, rise * 0.5, 0.15), STONE)
	var roof := Color(0.32, 0.42, 0.38)
	var eave := radius + 0.35
	var apex := Vector3(0.0, top + 1.4, 0.0)
	tool.set_color(roof)
	for i: int in 8:
		var a := TAU * i / 8.0
		var b := TAU * (i + 1) / 8.0
		var p := Vector3(cos(a) * eave, top, sin(a) * eave)
		var q := Vector3(cos(b) * eave, top, sin(b) * eave)
		for vertex: Vector3 in [p, q, apex, q, p, Vector3(0.0, top, 0.0)]:
			tool.add_vertex(vertex)
	_box(tool, apex + Vector3(0.0, 0.25, 0.0), Vector3(0.04, 0.3, 0.04), iron)
	CarriedGoods._lump(tool, apex + Vector3(0.0, 0.55, 0.0), Vector3(0.08, 0.08, 0.08), Color(0.75, 0.6, 0.25))


## Mureta girada angle em torno de y (a meia-medida half no referencial dela, com x para fora).
static func _wall(tool: SurfaceTool, center: Vector3, angle: float, half: Vector3, color: Color) -> void:
	tool.set_color(color)
	var basis := Basis(Vector3.UP, -angle)
	var corners: Array[Vector3] = []
	for i: int in 8:
		corners.append(center + basis * Vector3(half.x if i & 1 else -half.x, half.y if i & 2 else -half.y,
				half.z if i & 4 else -half.z))
	_faces(tool, corners)


## O jato do chafariz: gotas subindo da bica e caindo na bacia.
func _jet() -> CPUParticles3D:
	var jet := CPUParticles3D.new()
	jet.name = "Jet"
	jet.amount = JET_DROPS
	jet.lifetime = 0.9
	jet.direction = Vector3.UP
	jet.spread = 28.0
	jet.initial_velocity_min = 1.6
	jet.initial_velocity_max = 2.2
	jet.gravity = Vector3(0.0, -6.0, 0.0)
	jet.scale_amount_min = 0.6
	jet.scale_amount_max = 1.0
	var drop := SphereMesh.new()
	drop.radius = 0.035
	drop.height = 0.07
	drop.radial_segments = 6
	drop.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(WATER.lightened(0.35), 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.1
	drop.material = material
	jet.mesh = drop
	jet.visibility_range_end = _range_m
	return jet


## Caixa de meia-medida half em volta de center (as seis faces).
static func _box(tool: SurfaceTool, center: Vector3, half: Vector3, color: Color) -> void:
	tool.set_color(color)
	var corners: Array[Vector3] = []
	for i: int in 8:
		corners.append(center + Vector3(half.x if i & 1 else -half.x, half.y if i & 2 else -half.y, half.z if i & 4 else -half.z))
	_faces(tool, corners)


## As seis faces de uma caixa pelos oito cantos (bit 0 = x, bit 1 = y, bit 2 = z).
static func _faces(tool: SurfaceTool, corners: Array[Vector3]) -> void:
	# cada face com os cantos em volta (anti-horário de fora); o Godot quer o horário, então a ordem vira
	var faces := [[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4], [2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5]]
	for face: Array in faces:
		var a: Vector3 = corners[face[0]]
		var b: Vector3 = corners[face[1]]
		var c: Vector3 = corners[face[2]]
		var d: Vector3 = corners[face[3]]
		for vertex: Vector3 in [a, c, b, a, d, c]:
			tool.add_vertex(vertex)
