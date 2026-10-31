class_name FurnaceGlowView
extends Node3D
## Fase 137: a boca do forno acesa. Nas fábricas de forno (FURNACES: padaria, olaria, vidraria, fundição e a de vigas de
## aço), no térreo de uma fachada do lado, numa célula de parede lisa perto do meio (`mouth`), uma boca de forno em arco:
## o contorno de tijolo saindo da parede, a soleira de pedra e a portinhola de ferro aberta para um lado (`frame_mesh`); e,
## dentro dela, o fogo (`glow_mesh`, `shaders/furnace_glow.gdshader`), mais claro embaixo e tremulando, aceso enquanto a
## fábrica produz e mais forte à noite; parada, fica a brasa escura. À noite, a boca acesa deixa uma poça de luz laranja
## no chão diante dela (o `shaders/light_pool.gdshader` da Fase 119). Nada no save; refeito na obra, na demolição e ao
## trocar de mundo; o estado conferido a cada CHECK_S.

const FURNACES: Array[StringName] = [&"bakery", &"brickworks", &"glassworks", &"furnace", &"steel_beam_works"]
## A boca: meia largura do vão, a altura em que o arco começa (sobre a soleira), a soleira, e o contorno de tijolo.
const HALF_W := 0.55
const SPRING_M := 0.55
const HEARTH_M := 0.16
const SURROUND_M := 0.18
const PROUD_M := 0.14
const ARCH_SEGMENTS := 8
## O vidro do fogo fica este tanto à frente da parede (atrás do contorno).
const GLOW_OUT_M := 0.03
## A poça de luz: o meio a POOL_OUT_M da parede, o diâmetro e a cor.
const POOL_OUT_M := 1.3
const POOL_SIZE_M := 3.0
const POOL_COLOR := Color(1.0, 0.5, 0.18)
const CHECK_S := 0.5
const BRICK := Color(0.42, 0.2, 0.14)
const BRICK_DARK := Color(0.32, 0.15, 0.1)
const STONE := Color(0.6, 0.58, 0.54)
const IRON := Color(0.16, 0.16, 0.17)

var _simulation: Simulation
var _frames := MultiMeshInstance3D.new()
var _glows := MultiMeshInstance3D.new()
var _pools := MultiMeshInstance3D.new()
var _ids: Array[int] = []
## Aceso ou não, por boca (sem tela o MultiMesh não devolve o que se grava nele).
var _lit: Array[bool] = []
var _dirty := true
var _wait := 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var frame_material := StandardMaterial3D.new()
	frame_material.vertex_color_use_as_albedo = true
	frame_material.vertex_color_is_srgb = true
	frame_material.roughness = 0.9
	# a portinhola aparece dos dois lados
	frame_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var glow_material := ShaderMaterial.new()
	glow_material.shader = load("res://shaders/furnace_glow.gdshader") as Shader
	var quad := QuadMesh.new()
	quad.size = Vector2(POOL_SIZE_M, POOL_SIZE_M)
	quad.orientation = PlaneMesh.FACE_Y
	var pool_material := ShaderMaterial.new()
	pool_material.shader = load("res://shaders/light_pool.gdshader") as Shader
	quad.material = pool_material
	for part: Array in [[_frames, "Frames", frame_mesh(), frame_material], [_glows, "Glows", glow_mesh(), glow_material],
			[_pools, "Pools", quad, null]]:
		var layer: MultiMeshInstance3D = part[0]
		layer.name = part[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = part[2]
		if part[3] != null:
			var material: Material = part[3]
			layer.material_override = material
		add_child(layer)
	_glows.multimesh.use_custom_data = true
	_glows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pools.multimesh.use_colors = true
	_pools.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func mouth_count() -> int:
	return _ids.size()


## Quantas bocas estão acesas agora.
func lit_count() -> int:
	return _lit.count(true)


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	_wait -= delta
	if _wait <= 0.0:
		_wait = CHECK_S
		refresh_state()


func rebuild() -> void:
	_dirty = false
	_ids.clear()
	var places: Array[Transform3D] = []
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		if not FURNACES.has(record.def_id):
			continue
		var place: Variant = mouth(_simulation, record)
		if place is Transform3D:
			_ids.append(id)
			places.append(place)
	for layer: MultiMeshInstance3D in [_frames, _glows, _pools]:
		layer.multimesh.instance_count = places.size()
		layer.multimesh.custom_aabb = WorldBounds.of(_simulation.config)
	for i: int in places.size():
		var place := places[i]
		_frames.multimesh.set_instance_transform(i, place)
		_glows.multimesh.set_instance_transform(i, place)
		var ahead := place.origin + place.basis.z.normalized() * POOL_OUT_M
		var grid := world.island(world.building(_ids[i]).island_id)
		_pools.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY,
				Vector3(ahead.x, grid.height_at(ahead.x, ahead.z) + 0.05, ahead.z)))
	refresh_state()


## Acende o fogo (e a poça) das fábricas produzindo e apaga o das paradas.
func refresh_state() -> void:
	var world := _simulation.world
	_lit.resize(_ids.size())
	for i: int in _ids.size():
		var record := world.building(_ids[i])
		var lit := burning(record)
		_lit[i] = lit
		_glows.multimesh.set_instance_custom_data(i, Color(1.0 if lit else 0.0, 0.0, 0.0, 0.0))
		_pools.multimesh.set_instance_color(i, Color(POOL_COLOR, 1.0 if lit else 0.0))


## O forno está aceso: a fábrica produzindo e não pausada.
static func burning(record: BuildingRecord) -> bool:
	return record != null and record.state == BuildingRecord.State.PRODUCING and not record.paused


## Onde fica a boca do forno do prédio (mundo, com o +Z para fora da parede e o pé na soleira), ou null sem modelo: no
## térreo da fachada do lado (+X do prédio, senão −X), na célula de parede lisa mais perto do meio (com janela em todas, a
## do meio, embaixo dela).
static func mouth(simulation: Simulation, record: BuildingRecord) -> Variant:
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return null
	var def := simulation.def_of(record)
	var body := spec.hall() if spec.court_rows > 0 else spec
	var offset := spec.hall_offset() if spec.court_rows > 0 else Vector3.ZERO
	var place := Transform3D(Basis(Vector3.UP, -PI * 0.5 * posmod(record.rotation, 4)),
			BuildingKit.seat(grid, Footprint.rect(record.origin, def.size, record.rotation)))
	for face: int in [1, 3]:
		var count := body.cells.y
		var middle := count / 2
		var best := -1
		for index: int in count:
			var slot := BuildingKit.slot(body, face, index, 0)
			if slot == &"none":
				continue
			if slot == &"plain" and (best < 0 or absi(index - middle) < absi(best - middle)
					or BuildingKit.slot(body, face, best, 0) != &"plain"):
				best = index
			elif best < 0:
				best = index
		if best < 0:
			continue
		var normal := BuildingKit._face_normal(face)
		var origin := BuildingKit._wall_point(body, face, best, 0) + offset
		return place * Transform3D(Basis.looking_at(-normal, Vector3.UP), origin)
	return null


## O contorno da boca de frente para +Z, com o pé na parede (z = 0): soleira de pedra, ombreiras e arco de tijolo em
## aduelas de tons alternados saindo PROUD_M da parede e a portinhola de ferro aberta para fora.
static func frame_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer := HALF_W + SURROUND_M
	var z := PROUD_M * 0.5
	# soleira e o chão do forno
	VertexShapes.box(tool, Vector3(0.0, HEARTH_M * 0.5, z + 0.04), Vector3(outer + 0.06, HEARTH_M * 0.5, PROUD_M * 0.5 + 0.04),
			STONE)
	# ombreiras
	for side: float in [-1.0, 1.0]:
		VertexShapes.box(tool, Vector3(side * (HALF_W + SURROUND_M * 0.5), HEARTH_M + SPRING_M * 0.5, z),
				Vector3(SURROUND_M * 0.5, SPRING_M * 0.5, PROUD_M * 0.5), BRICK)
	# arco em aduelas
	var center := Vector3(0.0, HEARTH_M + SPRING_M, z)
	for k: int in ARCH_SEGMENTS:
		var a0 := PI * k / ARCH_SEGMENTS
		var a1 := PI * (k + 1) / ARCH_SEGMENTS
		var color := BRICK if k % 2 == 0 else BRICK_DARK
		var inner0 := center + Vector3(cos(a0), sin(a0), 0.0) * HALF_W
		var inner1 := center + Vector3(cos(a1), sin(a1), 0.0) * HALF_W
		var outer0 := center + Vector3(cos(a0), sin(a0), 0.0) * outer
		var outer1 := center + Vector3(cos(a1), sin(a1), 0.0) * outer
		var front := Vector3(0.0, 0.0, PROUD_M * 0.5)
		var back := -front
		# frente, intradorso e extradorso (o fundo encosta na parede)
		VertexShapes.quad(tool, inner0 + front, inner1 + front, outer1 + front, outer0 + front, color)
		VertexShapes.quad(tool, inner0 + back, inner1 + back, inner1 + front, inner0 + front, color.darkened(0.2))
		VertexShapes.quad(tool, outer0 + front, outer1 + front, outer1 + back, outer0 + back, color)
	# portinhola de ferro aberta para +X, presa na ombreira
	var hinge := Vector3(outer, HEARTH_M, PROUD_M)
	var leaf := Transform3D(Basis(Vector3.UP, 1.2), hinge)
	VertexShapes.oriented_box(tool, leaf * Transform3D(Basis.IDENTITY, Vector3(-HALF_W * 0.9, SPRING_M * 0.55, 0.015)),
			Vector3(HALF_W * 0.9, SPRING_M * 0.55, 0.015), IRON)
	tool.generate_normals()
	return tool.commit()


## O fogo no vão do arco, de frente para +Z, logo à frente da parede: o retângulo da soleira até o começo do arco e o meio
## círculo em leque, com UV.y subindo de 0 na soleira a 1 no alto do arco.
static func glow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := SPRING_M + HALF_W
	var z := GLOW_OUT_M
	var corners: Array[Vector3] = [Vector3(-HALF_W, HEARTH_M, z), Vector3(HALF_W, HEARTH_M, z),
			Vector3(HALF_W, HEARTH_M + SPRING_M, z), Vector3(-HALF_W, HEARTH_M + SPRING_M, z)]
	for index: int in [0, 2, 1, 0, 3, 2]:
		var point := corners[index]
		tool.set_uv(Vector2((point.x + HALF_W) / (HALF_W * 2.0), (point.y - HEARTH_M) / top))
		tool.add_vertex(point)
	var center := Vector3(0.0, HEARTH_M + SPRING_M, z)
	for k: int in ARCH_SEGMENTS:
		var a0 := PI * k / ARCH_SEGMENTS
		var a1 := PI * (k + 1) / ARCH_SEGMENTS
		for point: Vector3 in [center, center + Vector3(cos(a1), sin(a1), 0.0) * HALF_W,
				center + Vector3(cos(a0), sin(a0), 0.0) * HALF_W]:
			tool.set_uv(Vector2((point.x + HALF_W) / (HALF_W * 2.0), (point.y - HEARTH_M) / top))
			tool.add_vertex(point)
	tool.set_normal(Vector3(0.0, 0.0, 1.0))
	tool.generate_normals()
	return tool.commit()
