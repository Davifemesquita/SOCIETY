class_name TownFlagView
extends Node3D
## Fase 238: a bandeira na prefeitura. Em cada prefeitura (Fase 66), no alto da cúpula (o remate do lanternim da Fase 97,
## `BuildingKit.dome_finial`; sem cúpula, no meio da cumeeira), o mastro de ferro com a bola dourada (`pole_mesh`) e a bandeira
## da cidade — o campo vermelho com o losango dourado no meio e a orla dourada na ponta, nenhuma bandeira de verdade
## (`flag_mesh`) — numa `WindFlag` (Fase 22), que o `WeatherView` vira para o vento e faz tremular. Um nó por prefeitura; nada no
## save; refeito na obra, na demolição e ao trocar de mundo.

const BUILDINGS: Array[StringName] = [&"town_hall"]
## O mastro (acima do pé) e a bandeira (largura e altura), a quanto do alto do mastro ela fica presa.
const POLE_M := 4.2
const FLAG_M := Vector2(2.1, 1.35)
const FLAG_BELOW_M := 0.2
const IRON := Color(0.2, 0.2, 0.21)
const GILT := Color(0.8, 0.64, 0.25)
const FIELD := Color(0.66, 0.1, 0.1)

var _simulation: Simulation
var _nodes: Array[Node3D] = []
var _pole_mesh: ArrayMesh
var _cloth_material: StandardMaterial3D
## Os pés dos mastros (testes).
var places: Array[Vector3] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var painted := StandardMaterial3D.new()
	painted.vertex_color_use_as_albedo = true
	painted.vertex_color_is_srgb = true
	painted.roughness = 0.6
	painted.metallic = 0.3
	_pole_mesh = pole_mesh()
	_pole_mesh.surface_set_material(0, painted)
	_cloth_material = StandardMaterial3D.new()
	_cloth_material.vertex_color_use_as_albedo = true
	_cloth_material.vertex_color_is_srgb = true
	_cloth_material.roughness = 0.9
	_cloth_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func flag_count() -> int:
	return _nodes.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	for node: Node3D in _nodes:
		remove_child(node)
		node.queue_free()
	_nodes.clear()
	places.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var found: Variant = foot_of(_simulation, world.building(id))
		if found is Vector3:
			var foot: Vector3 = found
			places.append(foot)
			_add_flag(foot)


func _add_flag(foot: Vector3) -> void:
	var root := Node3D.new()
	root.name = "TownFlag%d" % _nodes.size()
	root.position = foot
	var body := MeshInstance3D.new()
	body.mesh = _pole_mesh
	root.add_child(body)
	var flag := WindFlag.new()
	flag.name = "Flag"
	flag.position = Vector3(0.05, POLE_M - FLAG_BELOW_M - FLAG_M.y * 0.5, 0.0)
	var cloth := MeshInstance3D.new()
	cloth.name = "Cloth"
	cloth.mesh = flag_mesh()
	cloth.material_override = _cloth_material
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flag.add_child(cloth)
	flag.add_to_group(WindFlag.GROUP)
	root.add_child(flag)
	add_child(root)
	_nodes.append(root)


## O pé do mastro da prefeitura (no mundo): o remate da cúpula ou, sem ela, o meio da cumeeira; null nos outros prédios.
static func foot_of(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or record.def_id not in BUILDINGS:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return null
	var local := BuildingKit.dome_finial(spec) if spec.dome else Vector3(0.0, spec.height_m + spec.roof_m, 0.0)
	var def := simulation.def_of(record)
	var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
	return model * local


## O mastro com o pé no zero: o colar de ferro, a haste afinando e a bola dourada no alto.
static func pole_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3.ZERO, Vector3(0.0, 0.18, 0.0), 0.09, IRON, 8)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.18, 0.0), Vector3(0.0, POLE_M * 0.5, 0.0), 0.05, IRON, 6)
	VertexShapes.cylinder(tool, Vector3(0.0, POLE_M * 0.5, 0.0), Vector3(0.0, POLE_M, 0.0), 0.035, IRON, 6)
	VertexShapes.box(tool, Vector3(0.0, POLE_M + 0.08, 0.0), Vector3(0.08, 0.08, 0.08), GILT)
	tool.generate_normals()
	return tool.commit()


## A bandeira ao longo de +x a partir do mastro, no plano xy, com o meio da altura no zero: o campo vermelho, a orla dourada na
## ponta e o losango dourado no meio (um pouquinho à frente e atrás do campo, para aparecer dos dois lados).
static func flag_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := FLAG_M.x
	var h := FLAG_M.y * 0.5
	var fringe := 0.12
	_quad(tool, Vector3(0.0, h, 0.0), Vector3(w - fringe, h, 0.0), Vector3(w - fringe, -h, 0.0), Vector3(0.0, -h, 0.0), FIELD)
	_quad(tool, Vector3(w - fringe, h, 0.0), Vector3(w, h, 0.0), Vector3(w, -h, 0.0), Vector3(w - fringe, -h, 0.0), GILT)
	var middle := Vector3(w * 0.45, 0.0, 0.0)
	for z: float in [0.004, -0.004]:
		var at := middle + Vector3(0.0, 0.0, z)
		_quad(tool, at + Vector3(0.0, h * 0.55, 0.0), at + Vector3(w * 0.16, 0.0, 0.0), at + Vector3(0.0, -h * 0.55, 0.0),
				at + Vector3(-w * 0.16, 0.0, 0.0), GILT)
	return tool.commit()


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.set_color(color)
		tool.set_normal(Vector3.BACK)
		tool.add_vertex(point)
