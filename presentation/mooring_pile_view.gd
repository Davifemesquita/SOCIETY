class_name MooringPileView
extends Node3D
## Fase 186: as estacas de atracação. Diante de cada entreposto, dos dois lados de onde o navio encosta (POST_SPOTS, pelo mesmo
## rumo do mar das boias da Fase 144, `HarborView.seaward`), e na ponta de cada píer (PIER_SPOTS), um feixe de estacas de madeira
## cravado na água funda o bastante (`HarborView.afloat`), girado pelo lugar (`spots`): cinco troncos de alturas diferentes
## puxados para o meio no alto, as duas voltas de cabo que os amarram e o limo escuro junto da água (`cluster_mesh`). Um
## MultiMesh; nada no save; refeito na obra, na demolição e ao trocar de mundo.

## [para o mar a partir da beira do lote (m), para o lado (m)].
const POST_SPOTS: Array[Vector2] = [Vector2(9.0, -16.0), Vector2(9.0, 16.0), Vector2(17.0, -20.0)]
const PIER_SPOTS: Array[Vector2] = [Vector2(4.0, -4.5), Vector2(4.0, 4.5)]
const PILE_RADIUS_M := 0.15
## O pé das estacas fica logo abaixo da água: mais fundo, a espuma por profundidade da água desenhava a parte submersa como uma
## coluna branca.
const FOOT_M := -0.5
const TOPS_M: Array[float] = [1.9, 1.6, 1.75, 1.45, 1.65]
const WOOD := Color(0.33, 0.27, 0.21)
const SLIME := Color(0.13, 0.17, 0.09)
const ROPE := Color(0.5, 0.42, 0.28)

var _simulation: Simulation
var _clusters := MultiMeshInstance3D.new()
## Os lugares dos feixes (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_clusters.name = "MooringPiles"
	_clusters.multimesh = MultiMesh.new()
	_clusters.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_clusters.multimesh.mesh = cluster_mesh()
	_clusters.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_clusters.material_override = material
	add_child(_clusters)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func cluster_count() -> int:
	return places.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	places.clear()
	var world := _simulation.world
	for id: int in world.building_ids():
		var record := world.building(id)
		var def := _simulation.def_of(record)
		places.append_array(spots(world, record, def, _simulation.config.cell_size_m))
	_clusters.multimesh.instance_count = places.size()
	for i: int in places.size():
		_clusters.multimesh.set_instance_transform(i, places[i])


## Os feixes de um entreposto ou píer (mundo, o pé no nível do mar), nos lugares que boiam; vazio para os outros prédios.
static func spots(world: WorldState, record: BuildingRecord, def: BuildingDef, cell_size: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var offsets: Array[Vector2] = []
	if def.is_trading_post:
		offsets = POST_SPOTS
	elif def.kind == BuildingDef.Kind.PIER:
		offsets = PIER_SPOTS
	else:
		return result
	var grid := world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var out := HarborView.seaward(world, center, area, cell_size, record.rotation)
	var across := Vector3(-out.z, 0.0, out.x)
	var reach := (area.size.x if out.x != 0.0 else area.size.y) * cell_size * 0.5
	for offset: Vector2 in offsets:
		var at := center + out * (reach + offset.x) + across * offset.y
		at.y = 0.0
		if not HarborView.afloat(world, at):
			continue
		var turn := float(posmod(roundi(at.x * 7.0 + at.z * 13.0), 360)) * PI / 180.0
		result.append(Transform3D(Basis(Vector3.UP, turn), at))
	return result


## O feixe com o nível do mar no zero: cinco estacas (uma no meio e quatro em volta) de alturas diferentes, as de fora
## puxadas para o meio no alto, o limo escuro até um pouco acima da água e duas voltas de cabo amarrando o feixe.
static func cluster_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in TOPS_M.size():
		var foot := Vector3.ZERO
		var top := Vector3(0.0, TOPS_M[k], 0.0)
		if k > 0:
			var angle := TAU * (k - 1) / 4.0 + 0.4
			var around := Vector3(cos(angle), 0.0, -sin(angle))
			foot = around * PILE_RADIUS_M * 2.3
			top += around * PILE_RADIUS_M * 1.4
		var bottom := foot + Vector3(0.0, FOOT_M, 0.0)
		# o limo até 0,35 m acima da água; a madeira daí para cima
		var slime := foot.lerp(top, 0.35 / TOPS_M[k])
		VertexShapes.cylinder(tool, bottom, slime, PILE_RADIUS_M, SLIME, 8)
		VertexShapes.cylinder(tool, slime, top, PILE_RADIUS_M, WOOD, 8)
	for y: float in [0.75, 1.15]:
		VertexShapes.cylinder(tool, Vector3(0.0, y, 0.0), Vector3(0.0, y + 0.08, 0.0), PILE_RADIUS_M * 2.9, ROPE, 12)
	tool.generate_normals()
	return tool.commit()
