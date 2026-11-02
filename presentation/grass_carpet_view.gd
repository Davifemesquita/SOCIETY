class_name GrassCarpetView
extends Node3D
## Fase 286: o tapete de capim perto da câmera. Em volta do ponto do chão que a câmera olha, até `radius_m` (RADIUS_M vezes o
## alcance dos detalhes do nível gráfico), tufos de folhas (`tuft_mesh`) nas células de capim livre (`grows_at`: terra sem
## árvore, prédio, estrada nem trilho, fora da praia e da margem do rio, quase plana), TUFTS_PER_CELL por célula em lugares
## sorteados pela célula (`tufts`). Um MultiMesh por bloco de BLOCK_CELLS × BLOCK_CELLS células, sem sombra, no
## `shaders/grass_carpet.gdshader` (que os encolhe com a distância e os faz crescer nas manchas do prado da Fase 285).
## É a primeira vista que segue a câmera, não o mundo: refaz só os blocos que entram no raio, até BUILDS_PER_FRAME por quadro,
## o mais perto primeiro, e solta os que saem; uma obra, uma estrada, uma derrubada de árvores ou um trilho marca os blocos da
## ilha para refazer aos poucos. Com a câmera alta (mais de MAX_CAMERA_M até o chão) fica escondido. Nada no save.

const BLOCK_CELLS := 8
const RADIUS_M := 90.0
const TUFTS_PER_CELL := 8
const BUILDS_PER_FRAME := 3
const MAX_CAMERA_M := 150.0
## Célula mais íngreme que isto (diferença entre os cantos) fica sem tapete: o tufo flutuaria no detalhe da encosta.
const MAX_RELIEF_M := 0.6
## A praia e a margem do rio (como no ArchipelagoGenerator: BEACH_CELLS + 1 e RIVER_BANK_CELLS) ficam sem tapete.
const SHORE_CELLS := 3
const BANK_CELLS := 2
const SALT := 286
const BLADES := 7
## Meia largura da folha no pé (m).
const BLADE_HALF_M := 0.04
const BLADE_HEIGHT_M := Vector2(0.4, 0.75)
const BASE_COLOR := Color(0.2, 0.34, 0.09)
const TIP_COLOR := Color(0.5, 0.68, 0.22)

var _simulation: Simulation
var _material: ShaderMaterial
var _mesh: ArrayMesh
## (ilha, bloco x, bloco y) → o MultiMeshInstance3D do bloco; e os lugares dos tufos dele (testes: sem tela o MultiMesh devolve
## transformações zeradas).
var _blocks: Dictionary[Vector3i, MultiMeshInstance3D] = {}
var block_places: Dictionary[Vector3i, Array] = {}
var _stale: Dictionary[Vector3i, bool] = {}
var radius_m := RADIUS_M
## Testes e capturas: o ponto que a câmera olha, no lugar do da câmera (INF: o da câmera).
var focus_override := Vector3.INF


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_mesh = tuft_mesh()
	_material = ShaderMaterial.new()
	_material.shader = load("res://shaders/grass_carpet.gdshader") as Shader
	_apply_motion()
	EventBus.building_placed.connect(_on_building)
	EventBus.building_removed.connect(_on_building)
	EventBus.roads_changed.connect(_mark_island)
	EventBus.trees_changed.connect(_on_trees)
	EventBus.world_replaced.connect(clear)
	EventBus.settings_changed.connect(_apply_motion)


## O nível gráfico: o raio segue o alcance dos detalhes.
func set_quality(preset: GraphicsPresetDef) -> void:
	radius_m = RADIUS_M * (preset.visibility_scale if preset != null else 1.0)


## Reduzir movimento (Fase 43): o capim não balança.
func _apply_motion() -> void:
	var still := Settings.reduce_motion
	_material.set_shader_parameter(&"sway_calm", 0.0 if still else 0.03)
	_material.set_shader_parameter(&"sway_wind", 0.0 if still else 0.12)


func _on_building(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record != null:
		_mark_island(record.island_id)
	else:
		# demolido: a ilha não está mais no registro
		for key: Vector3i in _blocks:
			_stale[key] = true


func _on_trees(island_id: int, _area: Rect2i) -> void:
	_mark_island(island_id)


func _mark_island(island_id: int) -> void:
	for key: Vector3i in _blocks:
		if key.x == island_id:
			_stale[key] = true


## Solta todos os blocos (o mundo trocou).
func clear() -> void:
	for node: MultiMeshInstance3D in _blocks.values():
		remove_child(node)
		node.queue_free()
	_blocks.clear()
	block_places.clear()
	_stale.clear()


func block_count() -> int:
	return _blocks.size()


func tuft_count() -> int:
	var total := 0
	for places: Array in block_places.values():
		total += places.size()
	return total


func _process(_delta: float) -> void:
	if _simulation != null:
		refresh(BUILDS_PER_FRAME)


## Acompanha o ponto da câmera: solta os blocos que saíram do raio e refaz até budget dos que faltam ou estão marcados, o mais
## perto primeiro.
func refresh(budget: int) -> void:
	var focus := _focus()
	visible = focus != Vector3.INF
	if not visible:
		return
	var wanted := wanted_blocks(_simulation.world, Vector2(focus.x, focus.z), radius_m)
	for key: Vector3i in _blocks.keys():
		if not wanted.has(key):
			_drop(key)
	var todo: Array[Vector3i] = []
	for key: Vector3i in wanted:
		if not _blocks.has(key) or _stale.has(key):
			todo.append(key)
	todo.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return wanted[a] < wanted[b])
	for i: int in mini(budget, todo.size()):
		_build(todo[i])


## O ponto do chão que a câmera olha, ou INF sem câmera ou com ela alta demais.
func _focus() -> Vector3:
	if focus_override != Vector3.INF:
		return focus_override
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return Vector3.INF
	var forward := -camera.global_basis.z
	if forward.y > -0.05:
		return Vector3.INF
	var focus := camera.global_position + forward * (-camera.global_position.y / forward.y)
	if camera.global_position.distance_to(focus) > MAX_CAMERA_M:
		return Vector3.INF
	return focus


## Os blocos (ilha, bx, by) que o raio em volta de focus toca, com a distância do meio de cada um.
static func wanted_blocks(world: WorldState, focus: Vector2, radius: float) -> Dictionary[Vector3i, float]:
	var result: Dictionary[Vector3i, float] = {}
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		if grid.flat:
			continue
		var rect := grid.world_rect().grow(radius)
		if not rect.has_point(focus):
			continue
		var block_m := BLOCK_CELLS * grid.cell_size
		var reach := radius + block_m * 0.71
		var local := (focus - Vector2(grid.origin_m)) / block_m
		var span := ceili(reach / block_m)
		var blocks := Vector2i(ceili(grid.size.x / float(BLOCK_CELLS)), ceili(grid.size.y / float(BLOCK_CELLS)))
		for by: int in range(maxi(floori(local.y) - span, 0), mini(floori(local.y) + span + 1, blocks.y)):
			for bx: int in range(maxi(floori(local.x) - span, 0), mini(floori(local.x) + span + 1, blocks.x)):
				var middle := Vector2(grid.origin_m) + (Vector2(bx, by) + Vector2(0.5, 0.5)) * block_m
				var meters := middle.distance_to(focus)
				if meters <= reach:
					result[Vector3i(island_id, bx, by)] = meters
	return result


func _drop(key: Vector3i) -> void:
	var node := _blocks[key]
	remove_child(node)
	node.queue_free()
	_blocks.erase(key)
	block_places.erase(key)
	_stale.erase(key)


## Refaz o bloco: os tufos de todas as células de capim livre dele.
func _build(key: Vector3i) -> void:
	if _blocks.has(key):
		_drop(key)
	var grid := _simulation.world.island(key.x)
	var places: Array[Transform3D] = []
	for cy: int in range(key.z * BLOCK_CELLS, mini((key.z + 1) * BLOCK_CELLS, grid.size.y)):
		for cx: int in range(key.y * BLOCK_CELLS, mini((key.y + 1) * BLOCK_CELLS, grid.size.x)):
			var cell := Vector2i(cx, cy)
			if grows_at(grid, cell):
				places.append_array(tufts(grid, key.x, cell))
	var node := MultiMeshInstance3D.new()
	node.name = "Grass_%d_%d_%d" % [key.x, key.y, key.z]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override = _material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _mesh
	multimesh.instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
	node.multimesh = multimesh
	add_child(node)
	_blocks[key] = node
	block_places[key] = places
	_stale.erase(key)


## Se a célula leva tapete: terra sem árvore, prédio, estrada nem trilho, longe do mar e do rio (praia e margem), quase plana.
static func grows_at(grid: IslandGrid, cell: Vector2i) -> bool:
	var index := grid.index(cell)
	if grid.ground[index] != IslandGrid.Ground.LAND or grid.trees[index] > 0 or grid.occupancy[index] != 0 \
			or grid.roads[index] != 0 or (not grid.rails.is_empty() and grid.rails[index] != 0):
		return false
	if grid.area_relief(Rect2i(cell, Vector2i.ONE)) > MAX_RELIEF_M:
		return false
	for dy: int in range(-SHORE_CELLS, SHORE_CELLS + 1):
		for dx: int in range(-SHORE_CELLS, SHORE_CELLS + 1):
			var other := cell + Vector2i(dx, dy)
			if not grid.in_bounds(other):
				# fora da grade é mar
				return false
			var ground := grid.ground[grid.index(other)]
			if ground == IslandGrid.Ground.SEA:
				return false
			if ground == IslandGrid.Ground.RIVER and absi(dx) <= BANK_CELLS and absi(dy) <= BANK_CELLS:
				return false
	return true


## Os tufos da célula: TUFTS_PER_CELL em lugares, giros e tamanhos sorteados pela célula, no chão.
static func tufts(grid: IslandGrid, island_id: int, cell: Vector2i) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for k: int in TUFTS_PER_CELL:
		var noise := FireflyView.cell_hash(island_id, cell.x, cell.y, SALT + k)
		var x := grid.origin_m.x + (cell.x + float(noise % 1000) / 1000.0) * grid.cell_size
		var z := grid.origin_m.y + (cell.y + float(noise / 1000 % 1000) / 1000.0) * grid.cell_size
		var turn := float(noise / 1000000 % 628) / 100.0
		var scale := 0.75 + float(noise / 7 % 50) / 100.0
		result.append(Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * scale), Vector3(x, grid.height_at(x, z) - 0.02, z)))
	return result


## O tufo, com o pé na origem: BLADES folhas finas em leque (um triângulo cada, da base estreita à ponta), em alturas e inclinações
## diferentes, escuras no pé e claras na ponta; a normal para cima (o tufo pega a luz do chão).
static func tuft_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b: int in BLADES:
		var angle := TAU * b / BLADES + 0.4 * sin(b * 2.3)
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-out.z, 0.0, out.x)
		var height := lerpf(BLADE_HEIGHT_M.x, BLADE_HEIGHT_M.y, fposmod(b * 0.618, 1.0))
		var lean := 0.25 + 0.2 * fposmod(b * 0.37, 1.0)
		var foot := out * 0.03
		var tip := foot + out * height * lean + Vector3.UP * height
		for corner: Array in [[foot - side * BLADE_HALF_M, BASE_COLOR], [tip, TIP_COLOR], [foot + side * BLADE_HALF_M, BASE_COLOR]]:
			var point: Vector3 = corner[0]
			var color: Color = corner[1]
			tool.set_normal(Vector3.UP)
			tool.set_color(color)
			tool.add_vertex(point)
	return tool.commit()
