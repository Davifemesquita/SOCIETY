class_name ScarecrowView
extends Node3D
## Fase 175: o espantalho no campo. Num campo de trigo ou de batata (`CROPS`, pela fazenda dona dele) a cada SCARECROW_EVERY
## pelo id, um espantalho de pau no vão do meio entre as fileiras (`spot`, a mesma conta das fileiras da `CropView`), um pouco
## fora do meio ao longo delas e torto à toa: o poste e a travessa, o casaco com as mangas abertas na travessa, a calça
## pendurada, a palha saindo das mangas e da barra, a cabeça de saco e o chapéu de aba larga (`scarecrow_mesh`). Um MultiMesh;
## nada no save; refeito na obra, na demolição e ao trocar de mundo (o dono do campo sai do estado derivado).

const CROPS: Array[int] = [BuildingDef.Crop.GRAIN, BuildingDef.Crop.TUBER]
const SCARECROW_EVERY := 3
const SCARECROW_REST := 0
## Quanto o espantalho sai do meio ao longo das fileiras (fração da meia largura útil) e quanto entorta.
const ALONG_SHARE := 0.35
const MAX_LEAN := 0.07
const ARM_Y := 1.48
const ARM_M := 0.66
const POLE := Color(0.4, 0.31, 0.22)
const COAT := Color(0.3, 0.32, 0.36)
const TROUSERS := Color(0.42, 0.36, 0.27)
const SACK := Color(0.72, 0.63, 0.46)
const HAT := Color(0.24, 0.2, 0.16)
const STRAW := Color(0.86, 0.74, 0.42)

var _simulation: Simulation
var _scarecrows := MultiMeshInstance3D.new()
## Os lugares dos espantalhos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	_scarecrows.name = "Scarecrows"
	_scarecrows.multimesh = MultiMesh.new()
	_scarecrows.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_scarecrows.multimesh.mesh = scarecrow_mesh()
	_scarecrows.material_override = material
	add_child(_scarecrows)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func scarecrow_count() -> int:
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
	_scarecrows.multimesh.instance_count = places.size()
	for i: int in places.size():
		_scarecrows.multimesh.set_instance_transform(i, places[i])
	_scarecrows.multimesh.custom_aabb = WorldBounds.of(_simulation.config)


## Onde fica o espantalho do campo (mundo: o pé no chão, o x ao longo das fileiras) ou null: só no campo do resto certo cuja
## fazenda planta uma das CROPS.
static func spot(simulation: Simulation, record: BuildingRecord, owners: Dictionary[int, int]) -> Variant:
	if record == null or posmod(record.id, SCARECROW_EVERY) != SCARECROW_REST:
		return null
	var def := simulation.def_of(record)
	if def == null or def.kind != BuildingDef.Kind.MODULE or def.id == CropView.PASTURE:
		return null
	var owner_id: int = owners.get(record.id, 0)
	var farm := simulation.world.building(owner_id)
	if farm == null:
		return null
	var crop := simulation.def_of(farm).crop
	if crop not in CROPS:
		return null
	var grid := simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var frame := CropView._row_frame(record)
	var half := Vector2(area.size) * simulation.config.cell_size_m * 0.5 - Vector2(CropView.HEADLAND_M, CropView.MARGIN_M)
	var spacing: Vector2 = CropView.SPACING[crop]
	var rows := maxi(1, floori(half.y * 2.0 / spacing.y) + 1)
	var start := -(rows - 1) * spacing.y * 0.5
	# o vão do meio entre duas fileiras
	var gap := floori(maxi(rows - 2, 0) / 2.0)
	var random := RandomNumberGenerator.new()
	random.seed = hash([record.id, &"espantalho"])
	var along := random.randf_range(-ALONG_SHARE, ALONG_SHARE) * half.x
	var point := center + frame * Vector3(along, 0.0, start + (gap + 0.5) * spacing.y)
	point.y = grid.height_at(point.x, point.z)
	var lean := Basis(Vector3.RIGHT, random.randf_range(-MAX_LEAN, MAX_LEAN)) * Basis(Vector3.BACK,
			random.randf_range(-MAX_LEAN, MAX_LEAN))
	var turn := Basis(Vector3.UP, random.randf_range(-0.25, 0.25))
	return Transform3D(frame * turn * lean, point)


## O espantalho com o pé no zero, os braços ao longo de x: o poste e a travessa, o casaco com as mangas na travessa e a barra
## mais larga, a calça pendurada, a palha nas pontas, a cabeça de saco e o chapéu.
static func scarecrow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.cylinder(tool, Vector3(0.0, -0.15, 0.0), Vector3(0.0, 1.62, 0.0), 0.035, POLE, 6)
	VertexShapes.cylinder(tool, Vector3(-ARM_M, ARM_Y, 0.0), Vector3(ARM_M, ARM_Y, 0.0), 0.03, POLE, 6)
	# o casaco: o corpo, a barra mais larga e as mangas abertas até perto da ponta da travessa
	VertexShapes.cylinder(tool, Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.56, 0.0), 0.2, COAT, 7)
	VertexShapes.cylinder(tool, Vector3(0.0, 0.8, 0.0), Vector3(0.0, 1.04, 0.0), 0.26, COAT, 7)
	for side: float in [-1.0, 1.0]:
		VertexShapes.cylinder(tool, Vector3(side * 0.16, ARM_Y + 0.01, 0.0), Vector3(side * 0.52, ARM_Y - 0.03, 0.0), 0.075,
				COAT, 6)
		# a palha saindo da manga, em leque
		for k: int in 4:
			var spread := (k - 1.5) * 0.045
			VertexShapes.strut(tool, Vector3(side * 0.5, ARM_Y - 0.03, 0.0),
					Vector3(side * (0.62 + absf(spread)), ARM_Y - 0.06 + spread, spread * 0.8), 0.008, 0.008, STRAW)
		# a perna da calça, pendurada da barra, com a palha na boca
		VertexShapes.cylinder(tool, Vector3(side * 0.09, 0.84, 0.0), Vector3(side * 0.1, 0.42, 0.02), 0.065, TROUSERS, 6)
		for k: int in 3:
			var spread := (k - 1.0) * 0.04
			VertexShapes.strut(tool, Vector3(side * 0.1, 0.44, 0.02), Vector3(side * 0.1 + spread, 0.32, 0.02 + spread * 0.5),
					0.007, 0.007, STRAW)
	# a palha da barra do casaco
	for k: int in 6:
		var angle := TAU * k / 6.0 + 0.3
		var at := Vector3(cos(angle) * 0.24, 0.82, -sin(angle) * 0.24)
		VertexShapes.strut(tool, at, at * Vector3(1.15, 1.0, 1.15) + Vector3(0.0, -0.12, 0.0), 0.008, 0.008, STRAW)
	# a cabeça de saco amarrada no pescoço e o chapéu de aba larga
	VertexShapes.cylinder(tool, Vector3(0.0, 1.55, 0.0), Vector3(0.0, 1.6, 0.0), 0.07, POLE, 6)
	VertexShapes.cylinder(tool, Vector3(0.0, 1.6, 0.0), Vector3(0.0, 1.84, 0.0), 0.12, SACK, 7)
	VertexShapes.cylinder(tool, Vector3(0.0, 1.84, 0.0), Vector3(0.0, 1.86, 0.0), 0.26, HAT, 10)
	VertexShapes.cylinder(tool, Vector3(0.0, 1.86, 0.0), Vector3(0.0, 2.0, 0.0), 0.13, HAT, 8)
	tool.generate_normals()
	return tool.commit()
