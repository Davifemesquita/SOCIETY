class_name ChestnutRoasterView
extends Node3D
## Fase 234: o fogareiro de castanhas. No canto de dentro de parte das esquinas calçadas (a mesma busca das colunas de anúncios da
## Fase 150, `AdColumnView`, nas esquinas do resto ROASTER_REST de ROASTER_EVERY, que nunca cai numa coluna, e fora das células dos
## outros enfeites, `cells`): o carrinho de duas rodas do vendedor, com o fogareiro de ferro redondo, a panela furada de assar por
## cima, a chaminezinha, o saco de castanhas e o cesto (`roaster_mesh`), virado para a esquina; as brasas na boca do fogareiro
## acesas à noite (`ember_mesh`, `shaders/night_glow.gdshader`). Dois MultiMesh; nada no save; refeito na obra, na demolição, na
## estrada, no trilho e ao trocar de mundo.

const ROASTER_EVERY := 6
const ROASTER_REST := 3
const CORNER_M := 0.35
const IRON := Color(0.16, 0.16, 0.17)
const WOOD := Color(0.48, 0.36, 0.24)
const SACK := Color(0.62, 0.52, 0.36)
const CHESTNUT := Color(0.36, 0.2, 0.12)
const EMBER := Color(1.0, 0.45, 0.15)

var _simulation: Simulation
var _carts := MultiMeshInstance3D.new()
var _embers := MultiMeshInstance3D.new()
## Os lugares (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	for pair: Array in [[_carts, "ChestnutRoasters", roaster_mesh(), material], [_embers, "ChestnutEmbers", ember_mesh(),
			LampView._glow_material()]]:
		var layer: MultiMeshInstance3D = pair[0]
		layer.name = pair[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = pair[2]
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = pair[3]
		add_child(layer)
	_embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func roaster_count() -> int:
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
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		var found := cells(world, _simulation.data, island_id)
		for cell: Vector2i in found:
			var corner: Vector2i = found[cell]
			var toward := Vector3(corner.x, 0.0, corner.y).normalized()
			var at := grid.cell_world(cell) + toward * CORNER_M
			at.y = grid.height_at(at.x, at.z)
			# o carrinho de frente (−z) para a esquina; base de mão direita
			var z := -toward
			var x := Vector3.UP.cross(z).normalized()
			places.append(Transform3D(Basis(x, Vector3.UP, z), at))
	for layer: MultiMeshInstance3D in [_carts, _embers]:
		layer.multimesh.instance_count = places.size()
		for i: int in places.size():
			layer.multimesh.set_instance_transform(i, places[i])


## As células dos fogareiros da ilha → o lado da esquina (a soma dos dois lados de rua): a busca das colunas de anúncios, no resto
## ROASTER_REST de ROASTER_EVERY (ímpar: as colunas ficam no resto 0 de 2), fora das células dos outros enfeites.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	var grid := world.island(island_id)
	if grid == null:
		return result
	var taken: Dictionary[Vector2i, bool] = {}
	var looked := false
	var index := grid.roads.find(IslandGrid.Road.PAVED)
	while index >= 0:
		var road := grid.cell_at(index)
		index = grid.roads.find(IslandGrid.Road.PAVED, index + 1)
		for diagonal: Vector2i in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var cell := road + Vector2i(diagonal.x, 0)
			if result.has(cell) or posmod(cell.x * 7 + cell.y * 11, ROASTER_EVERY) != ROASTER_REST:
				continue
			var side_a := Vector2i(-diagonal.x, 0)
			var side_b := Vector2i(0, diagonal.y)
			if not AdColumnView._paved(grid, cell + side_a) or not AdColumnView._paved(grid, cell + side_b):
				continue
			if not AdColumnView._free(grid, cell):
				continue
			if not looked:
				taken = AdColumnView._taken(world, data, island_id)
				looked = true
			if taken.has(cell):
				continue
			result[cell] = side_a + side_b
	return result


## O carrinho com o pé no chão, a frente (−z) para a esquina: as duas rodas e o eixo, a caixa de tábuas com os varais para trás, o
## fogareiro redondo de ferro em cima com a boca na frente, a panela furada com as castanhas, a chaminezinha, o saco e o cesto.
static func roaster_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wheel_r := 0.32
	for side: float in [-1.0, 1.0]:
		var hub := Vector3(side * 0.42, wheel_r, 0.15)
		for k: int in 10:
			var a0 := TAU * k / 10.0
			var a1 := TAU * (k + 1) / 10.0
			VertexShapes.strut(tool, hub + Vector3(0.0, sin(a0), cos(a0)) * wheel_r, hub + Vector3(0.0, sin(a1), cos(a1)) * wheel_r,
					0.02, 0.018, IRON)
		for k: int in 5:
			var angle := TAU * k / 5.0
			VertexShapes.strut(tool, hub, hub + Vector3(0.0, sin(angle), cos(angle)) * wheel_r, 0.008, 0.008, IRON)
	VertexShapes.strut(tool, Vector3(-0.45, wheel_r, 0.15), Vector3(0.45, wheel_r, 0.15), 0.015, 0.015, IRON)
	VertexShapes.box(tool, Vector3(0.0, 0.5, 0.0), Vector3(0.36, 0.1, 0.42), WOOD)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * 0.3, 0.45, 0.4), Vector3(side * 0.3, 0.55, 1.05), 0.02, 0.02, WOOD)
	VertexShapes.strut(tool, Vector3(0.0, 0.42, -0.35), Vector3(0.0, 0.0, -0.4), 0.025, 0.025, WOOD)
	# o fogareiro, a boca na frente e a panela com as castanhas
	var drum := Vector3(0.0, 0.6, -0.08)
	VertexShapes.cylinder(tool, drum, drum + Vector3(0.0, 0.42, 0.0), 0.24, IRON, 12)
	VertexShapes.cylinder(tool, drum + Vector3(0.0, 0.42, 0.0), drum + Vector3(0.0, 0.47, 0.0), 0.3, IRON, 12)
	for k: int in 6:
		var angle := TAU * k / 6.0
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.035, 0.03, 0.035)), drum + Vector3(cos(angle) * 0.14,
				0.5, sin(angle) * 0.14)), CHESTNUT)
	VertexShapes.cylinder(tool, drum + Vector3(0.12, 0.47, 0.14), drum + Vector3(0.12, 0.95, 0.14), 0.04, IRON, 6)
	# o saco e o cesto
	PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3(0.14, 0.18, 0.12)), Vector3(0.22, 0.78, 0.25)), SACK)
	VertexShapes.cylinder(tool, Vector3(-0.2, 0.6, 0.25), Vector3(-0.2, 0.75, 0.25), 0.11, WOOD.lightened(0.15), 8)
	tool.generate_normals()
	return tool.commit()


## As brasas na boca do fogareiro, na frente dele, marcadas como vidro (alfa 0) para o night_glow: escuras de dia, acesas à
## noite (a chama, alfa 1, encolhe para o pé da malha, que aqui é o chão).
static func ember_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.0, 0.72, -0.31), Vector3(0.09, 0.06, 0.012), Color(EMBER, 0.0))
	tool.generate_normals()
	return tool.commit()
