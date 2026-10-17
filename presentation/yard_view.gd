class_name YardView
extends Node3D
## Quintal (Fase 15): varal com roupa estendida atrás de parte das casas de camponeses e operários e vasos de
## flor dos dois lados da porta. O varal vai na célula de trás, livre (a mesma da fogueira da LampView), numa
## casa a cada CLOTHESLINE_EVERY pelo id, com resto diferente do da fogueira: as duas nunca disputam o lugar.
## Os vasos vão na frente do corpo da casa (no quintal cercado dos camponeses, que recua a casa uma fileira).
## Tudo gerado aqui, cor no vértice ou na instância, um MultiMesh por peça. Só lê o mundo.

const TIERS: Array[StringName] = [&"peasants", &"workers"]
## Varal: casa sim pelo id (resto CLOTHESLINE_REST; a fogueira usa o resto 0 de 3), altura da corda,
## meia distância entre os postes e as peças de roupa (largura, comprimento) penduradas nela.
const CLOTHESLINE_EVERY := 3
const CLOTHESLINE_REST := 1
const LINE_HEIGHT_M := 1.7
const LINE_HALF_M := 0.85
const CLOTHES_PER_LINE := 4
const CLOTH_SIZE := Vector2(0.32, 0.5)
## Vasos: casa sim pelo id, distância da porta e quanto ficam à frente da parede.
const POT_EVERY := 2
const POT_SIDE_M := 0.9
const POT_OUT_M := 0.35
const POLE_COLOR := Color(0.4, 0.3, 0.2)
const ROPE_COLOR := Color(0.78, 0.72, 0.6)
## Roupa de varal: linho cru, camisa azul, pano vermelho, avental branco, saia parda.
const CLOTH_COLORS: Array[Color] = [Color(0.86, 0.82, 0.72), Color(0.42, 0.52, 0.66), Color(0.7, 0.3, 0.25),
		Color(0.93, 0.92, 0.88), Color(0.55, 0.45, 0.33)]

var _simulation: Simulation
var _poles := MultiMeshInstance3D.new()
var _ropes := MultiMeshInstance3D.new()
var _clothes := MultiMeshInstance3D.new()
var _pots := MultiMeshInstance3D.new()
var _dirty: bool = false


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pole := BoxMesh.new()
	pole.size = Vector3(0.08, LINE_HEIGHT_M + 0.1, 0.08)
	var rope := BoxMesh.new()
	rope.size = Vector3(LINE_HALF_M * 2.0, 0.015, 0.015)
	for part: Array in [[_poles, "Poles", pole], [_ropes, "Ropes", rope], [_clothes, "Clothes", cloth_mesh()],
			[_pots, "Pots", pot_mesh()]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = true
		layer.multimesh.mesh = part[2]
		layer.material_override = material
		add_child(layer)
	set_quality(null)
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.house_upgraded.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	var scale := preset.visibility_scale if preset != null else 1.0
	for layer: MultiMeshInstance3D in [_poles, _ropes, _clothes, _pots]:
		layer.visibility_range_end = _simulation.config.building_detail_range_m * scale


func clothesline_count() -> int:
	return _ropes.multimesh.instance_count


func cloth_count() -> int:
	return _clothes.multimesh.instance_count


func pot_count() -> int:
	return _pots.multimesh.instance_count


func pot_transform(index: int) -> Transform3D:
	return _pots.multimesh.get_instance_transform(index)


func _process(_delta: float) -> void:
	if _dirty:
		rebuild()


func rebuild() -> void:
	_dirty = false
	var poles: Array = []
	var ropes: Array = []
	var clothes: Array = []
	var pots: Array = []
	var world := _simulation.world
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		if not record.is_house() or not TIERS.has(record.tier):
			continue
		if building_id % CLOTHESLINE_EVERY == CLOTHESLINE_REST:
			var spot: Variant = LampView.bonfire_spot(_simulation, record)
			if spot is Vector3:
				var point: Vector3 = spot
				_clothesline(record, point, poles, ropes, clothes)
		if building_id % POT_EVERY == 0:
			for place: Transform3D in pot_places(_simulation, record):
				pots.append([place, Color.WHITE])
	_fill(_poles, poles)
	_fill(_ropes, ropes)
	_fill(_clothes, clothes)
	_fill(_pots, pots)


## O varal no meio da célula de trás, de través (paralelo à parede de trás), com a roupa pendurada.
func _clothesline(record: BuildingRecord, spot: Vector3, poles: Array, ropes: Array, clothes: Array) -> void:
	var front := Footprint.front_direction(record.rotation)
	var along := Vector3(front.y, 0.0, -front.x)
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	for side: float in [-1.0, 1.0]:
		var foot := spot + along * side * LINE_HALF_M
		poles.append([Transform3D(Basis.IDENTITY, foot + Vector3(0.0, (LINE_HEIGHT_M + 0.1) * 0.5, 0.0)), Color(POLE_COLOR)])
	ropes.append([Transform3D(basis, spot + Vector3(0.0, LINE_HEIGHT_M, 0.0)), Color(ROPE_COLOR)])
	for i: int in CLOTHES_PER_LINE:
		var offset := (i + 0.5) / CLOTHES_PER_LINE * 2.0 - 1.0
		var hang := spot + along * offset * (LINE_HALF_M - 0.15) + Vector3(0.0, LINE_HEIGHT_M, 0.0)
		# cada peça um pouco torta, da cor sorteada pelo id e pela posição
		var tilt := Basis(along, sin(record.id * 1.7 + i) * 0.15)
		var color: Color = CLOTH_COLORS[(record.id * 3 + i) % CLOTH_COLORS.size()]
		clothes.append([Transform3D(tilt * basis, hang), color])


## Os dois vasos de cada lado da porta, encostados na frente do corpo da casa (no quintal cercado dos
## camponeses, a casa recua uma fileira).
static func pot_places(simulation: Simulation, record: BuildingRecord) -> Array[Transform3D]:
	var def := simulation.def_of(record)
	var grid := simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var cell := simulation.config.cell_size_m
	var front := Footprint.front_direction(record.rotation)
	var outward := Vector3(front.x, 0.0, front.y)
	var along := Vector3(front.y, 0.0, -front.x)
	var depth := area.size.y if posmod(record.rotation, 2) == 0 else area.size.x
	var court := 1 if simulation.data.tier(record.tier).house_trim == TierDef.HouseTrim.YARD else 0
	var face := center + outward * ((depth * 0.5 - court) * cell + POT_OUT_M)
	var places: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		places.append(Transform3D(Basis(Vector3.UP, record.id + side), face + along * side * POT_SIDE_M))
	return places


static func _fill(layer: MultiMeshInstance3D, items: Array) -> void:
	layer.multimesh.instance_count = items.size()
	for i: int in items.size():
		var item: Array = items[i]
		var place: Transform3D = item[0]
		var color: Color = item[1]
		layer.multimesh.set_instance_transform(i, place)
		layer.multimesh.set_instance_color(i, color)


## Peça de roupa: pano retangular pendurado da corda (y = 0) para baixo, com um leve caimento no meio.
static func cloth_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_color(Color.WHITE)
	var half := CLOTH_SIZE.x * 0.5
	var drop := CLOTH_SIZE.y
	var top_l := Vector3(-half, 0.0, 0.0)
	var top_r := Vector3(half, 0.0, 0.0)
	var mid := Vector3(0.0, -drop * 0.5, 0.04)
	var low_l := Vector3(-half * 0.95, -drop, 0.0)
	var low_r := Vector3(half * 0.95, -drop, 0.0)
	for vertex: Vector3 in [top_l, top_r, mid, top_r, low_r, mid, low_r, low_l, mid, low_l, top_l, mid]:
		tool.add_vertex(vertex)
	tool.generate_normals()
	return tool.commit()


## Vaso de barro com a planta florida saindo dele (cor no vértice).
static func pot_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 8
	var clay := Color(0.66, 0.36, 0.22)
	tool.set_color(clay)
	for i: int in sides:
		var a := TAU * i / sides
		var b := TAU * (i + 1) / sides
		var low_a := Vector3(cos(a), 0.0, sin(a)) * 0.13
		var low_b := Vector3(cos(b), 0.0, sin(b)) * 0.13
		var high_a := Vector3(cos(a) * 0.18, 0.32, sin(a) * 0.18)
		var high_b := Vector3(cos(b) * 0.18, 0.32, sin(b) * 0.18)
		for vertex: Vector3 in [low_a, high_a, high_b, low_a, high_b, low_b]:
			tool.add_vertex(vertex)
	# a folhagem (um volume verde) e três flores (pontas vermelhas e amarelas)
	CarriedGoods._lump(tool, Vector3(0.0, 0.42, 0.0), Vector3(0.2, 0.16, 0.2), Color(0.28, 0.48, 0.2))
	var flowers: Array[Color] = [Color(0.85, 0.2, 0.25), Color(0.95, 0.8, 0.25), Color(0.85, 0.2, 0.25)]
	for i: int in flowers.size():
		var a := TAU * i / flowers.size()
		CarriedGoods._lump(tool, Vector3(cos(a) * 0.1, 0.56, sin(a) * 0.1), Vector3(0.05, 0.04, 0.05), flowers[i])
	tool.generate_normals()
	return tool.commit()
