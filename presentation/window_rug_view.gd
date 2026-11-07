class_name WindowRugView
extends Node3D
## Fase 232: o tapete na janela. Numa casa dos operários e dos artesãos a cada RUG_EVERY pelo id (resto RUG_REST), na primeira
## janela do andar de cima da fachada da frente (`spot`, no referencial das janelas da Fase 39, pelo `_cell_transform`: o balanço
## do enxaimel e a ala acompanham), o tapete estendido no peitoril para tomar ar: a dobra por cima do peitoril e o pano caindo
## pela parede, listrado nas cores do tapete com a franja embaixo (`rug_mesh`); a cor das listras pela casa (a cor da instância).
## Um MultiMesh; nada no save; refeito na obra, na demolição, na subida de classe e ao trocar de mundo.

const TIERS: Array[StringName] = [&"workers", &"artisans"]
const RUG_EVERY := 5
const RUG_REST := 2
## O tapete: a largura, o quanto cai pela parede, a dobra por cima e o quanto fica para fora da parede.
const WIDTH_M := 0.62
const DROP_M := 0.85
const FOLD_M := 0.14
const OUT_M := 0.08
const STRIPES := 7
const BASE := Color(0.62, 0.2, 0.15)
const PALE := Color(0.88, 0.8, 0.62)
const FRINGE := Color(0.84, 0.78, 0.64)
const TINTS: Array[Color] = [Color(1.0, 1.0, 1.0), Color(0.5, 0.75, 1.0), Color(0.75, 1.0, 0.6), Color(1.0, 0.8, 0.45)]

var _simulation: Simulation
var _rugs := MultiMeshInstance3D.new()
## Os lugares (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rugs.name = "WindowRugs"
	_rugs.multimesh = MultiMesh.new()
	_rugs.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_rugs.multimesh.use_colors = true
	_rugs.multimesh.mesh = rug_mesh()
	_rugs.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_rugs.material_override = material
	_rugs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rugs)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.house_upgraded.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rug_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var colors: Array[Color] = []
	var world := _simulation.world
	for id: int in world.building_ids():
		var found: Variant = spot(_simulation, world.building(id))
		if found is Transform3D:
			var place: Transform3D = found
			places.append(place)
			colors.append(TINTS[posmod(id / RUG_EVERY, TINTS.size())])
	_rugs.multimesh.instance_count = places.size()
	for i: int in places.size():
		_rugs.multimesh.set_instance_transform(i, places[i])
		_rugs.multimesh.set_instance_color(i, colors[i])


## O lugar do tapete da casa (o meio do peitoril, o x ao longo da parede, o +z para fora dela), ou null: casa das classes certas
## e do resto certo, com uma janela no andar de cima da fachada da frente.
static func spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	if record == null or not record.is_house() or record.tier not in TIERS or posmod(record.id, RUG_EVERY) != RUG_REST:
		return null
	var grid := simulation.world.island(record.island_id)
	var spec := BuildingKit.spec_for(simulation, record, grid.cell_size)
	if spec == null:
		return null
	var hall := spec.hall()
	if hall.floors() < 2:
		return null
	for index: int in hall.cells.x:
		if BuildingKit.slot(hall, 0, index, 1) != &"window":
			continue
		var def := simulation.def_of(record)
		var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, def.size, record.rotation))
		var cell := model * Transform3D(Basis.IDENTITY, spec.hall_offset()) * BuildingKit._cell_transform(hall, 0, index, 1)
		var sill := cell * Vector3(0.5, BuildingKit.WINDOW_CENTER - BuildingKit.WINDOW_HEIGHT * 0.5, 0.0)
		var out := cell.basis.x.normalized()
		var along := cell.basis.z.normalized()
		# base de mão direita: x ao longo, y para cima, z para fora
		var up := out.cross(along).normalized()
		if up.y < 0.0:
			along = -along
			up = -up
		return Transform3D(Basis(along, up, out), sill + out * OUT_M)
	return null


## O tapete com o meio do peitoril na origem, a parede em z = −OUT_M: a dobra por cima do peitoril, o pano caindo pela parede
## (afastado dela no pé) em STRIPES listras e a franja embaixo.
static func rug_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WIDTH_M * 0.5
	# a dobra: do lado de dentro do peitoril até a beira de fora
	VertexShapes.quad(tool, Vector3(-half, 0.02, -OUT_M - FOLD_M), Vector3(half, 0.02, -OUT_M - FOLD_M), Vector3(half, 0.03, 0.0),
			Vector3(-half, 0.03, 0.0), BASE)
	for k: int in STRIPES:
		var t0 := float(k) / STRIPES
		var t1 := float(k + 1) / STRIPES
		var color := PALE if k % 3 == 1 else BASE
		var a := Vector3(-half, -t0 * DROP_M, 0.02 * t0)
		var b := Vector3(half, -t0 * DROP_M, 0.02 * t0)
		var c := Vector3(half, -t1 * DROP_M, 0.02 * t1)
		var d := Vector3(-half, -t1 * DROP_M, 0.02 * t1)
		VertexShapes.quad(tool, a, b, c, d, color)
	# a borda de cima, da dobra para o pano
	VertexShapes.quad(tool, Vector3(-half, 0.03, 0.0), Vector3(half, 0.03, 0.0), Vector3(half, 0.0, 0.0), Vector3(-half, 0.0, 0.0),
			BASE)
	for k: int in 5:
		var x := -half + 0.04 + k * (WIDTH_M - 0.08) / 4.0
		VertexShapes.strut(tool, Vector3(x, -DROP_M, 0.02), Vector3(x, -DROP_M - 0.06, 0.022), 0.006, 0.003, FRINGE)
	tool.generate_normals()
	return tool.commit()
