class_name RailSignalView
extends Node3D
## Fase 230: o sinal no trilho. Em cada ponta de linha do trilho da Fase 70 (a célula de trilho com um só vizinho de trilho pelos
## lados: a chegada ao poço e à usina, `ends`), ao lado da linha, à direita de quem chega (`place_of`): o poste de madeira com a
## escada de ferro, o braço do sinal pintado de vermelho com a faixa branca, erguido a meio (via livre), a lanterna do braço e
## o contrapeso (`signal_mesh`), e o vidro da lanterna aceso à noite (`glass_mesh`, `shaders/night_glow.gdshader`). Dois
## MultiMesh; nada no save; refeito na obra, na demolição, no trilho e ao trocar de mundo.

const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Do meio da célula para o lado da linha e o quanto o poste fica antes da ponta.
const ASIDE_M := 0.95
const BACK_M := 0.4
const POST_M := 4.6
const ARM_M := 1.1
const ARM_TILT := 0.6
const WOOD := Color(0.4, 0.3, 0.2)
const IRON := Color(0.16, 0.16, 0.17)
const RED := Color(0.66, 0.14, 0.11)
const WHITE := Color(0.9, 0.88, 0.82)

var _simulation: Simulation
var _posts := MultiMeshInstance3D.new()
var _glass := MultiMeshInstance3D.new()
## Os lugares dos sinais (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.75
	for pair: Array in [[_posts, "SignalPosts", signal_mesh(), material], [_glass, "SignalGlass", glass_mesh(),
			LampView._glow_material()]]:
		var layer: MultiMeshInstance3D = pair[0]
		layer.name = pair[1]
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = pair[2]
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = pair[3]
		add_child(layer)
	_glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.rails_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func signal_count() -> int:
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
		var found := ends(grid)
		for cell: Vector2i in found:
			places.append(place_of(grid, cell, found[cell]))
	for layer: MultiMeshInstance3D in [_posts, _glass]:
		layer.multimesh.instance_count = places.size()
		for i: int in places.size():
			layer.multimesh.set_instance_transform(i, places[i])


## As pontas de linha da ilha: a célula de trilho com um só vizinho de trilho pelos lados → o lado para onde a linha segue.
static func ends(grid: IslandGrid) -> Dictionary[Vector2i, Vector2i]:
	var result: Dictionary[Vector2i, Vector2i] = {}
	if grid == null:
		return result
	var index := grid.rails.find(1)
	while index >= 0:
		var cell := grid.cell_at(index)
		index = grid.rails.find(1, index + 1)
		var count := 0
		var toward := Vector2i.ZERO
		for side: Vector2i in SIDES:
			if grid.has_rail(cell + side):
				count += 1
				toward = side
		if count == 1:
			result[cell] = toward
	return result


## O lugar do sinal: na célula da ponta, ASIDE_M à direita de quem chega pela linha (vindo de toward) e BACK_M antes da ponta, no
## chão; o +z do sinal para fora da linha e o −x para quem chega.
static func place_of(grid: IslandGrid, cell: Vector2i, toward: Vector2i) -> Transform3D:
	# quem chega anda para a ponta, contra o lado da linha (toward); a direita dele no plano x-z: andar (dx, dz) → (−dz, dx)
	var travel := Vector3(-toward.x, 0.0, -toward.y)
	var right := Vector3(-travel.z, 0.0, travel.x)
	var at := grid.cell_world(cell) + right * ASIDE_M - travel * BACK_M
	at.y = grid.height_at(at.x, at.z)
	# base de mão direita: x = a marcha, y = cima, z = x × y = a direita (para fora da linha)
	return Transform3D(Basis(travel, Vector3.UP, right), at)


## O sinal com o pé no chão, o −x para quem chega e o braço para +z, para fora da linha: o poste, os
## degraus da escada de ferro, o braço vermelho com a faixa branca erguido a ARM_TILT, a armação da lanterna e o contrapeso.
static func signal_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.strut(tool, Vector3.ZERO, Vector3(0.0, POST_M, 0.0), 0.08, 0.08, WOOD)
	VertexShapes.box(tool, Vector3(0.0, POST_M + 0.06, 0.0), Vector3(0.12, 0.06, 0.12), IRON)
	for k: int in 12:
		var y := 0.4 + k * 0.3
		VertexShapes.strut(tool, Vector3(-0.1, y, -0.08), Vector3(-0.1, y, 0.08), 0.012, 0.012, IRON)
	VertexShapes.strut(tool, Vector3(-0.1, 0.3, -0.09), Vector3(-0.1, POST_M - 0.6, -0.09), 0.012, 0.012, IRON)
	VertexShapes.strut(tool, Vector3(-0.1, 0.3, 0.09), Vector3(-0.1, POST_M - 0.6, 0.09), 0.012, 0.012, IRON)
	# o braço, girado em volta do x no pivô, para +z e para cima
	var pivot := Vector3(0.1, POST_M - 0.5, 0.0)
	var arm := Basis(Vector3.RIGHT, -ARM_TILT)
	VertexShapes.oriented_box(tool, Transform3D(arm, pivot + arm * Vector3(0.0, 0.0, ARM_M * 0.5)), Vector3(0.025, 0.11,
			ARM_M * 0.5), RED)
	# a faixa branca perto da ponta, nas duas faces do braço
	for side: float in [-1.0, 1.0]:
		VertexShapes.oriented_box(tool, Transform3D(arm, pivot + arm * Vector3(side * 0.028, 0.0, ARM_M * 0.72)), Vector3(0.004,
				0.112, 0.07), WHITE)
	# a armação da lanterna junto do pivô e o contrapeso do outro lado
	VertexShapes.box(tool, pivot + Vector3(0.05, -0.32, 0.0), Vector3(0.1, 0.02, 0.1), IRON)
	VertexShapes.box(tool, pivot + Vector3(0.05, -0.08, 0.0), Vector3(0.1, 0.02, 0.1), IRON)
	VertexShapes.strut(tool, pivot + arm * Vector3(0.0, 0.0, -0.25), pivot + arm * Vector3(0.0, 0.0, -0.05), 0.02, 0.02, IRON)
	VertexShapes.box(tool, pivot + arm * Vector3(0.0, 0.0, -0.3), Vector3(0.05, 0.07, 0.05), IRON)
	tool.generate_normals()
	return tool.commit()


## O vidro da lanterna do sinal, entre a base e o chapéu da armação, marcado como vidro (alfa 0) para o night_glow.
static func glass_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	VertexShapes.box(tool, Vector3(0.15, POST_M - 0.5 - 0.2, 0.0), Vector3(0.08, 0.1, 0.08), Color(LampView.LAMP_COLOR, 0.0))
	tool.generate_normals()
	return tool.commit()
