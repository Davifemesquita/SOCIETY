class_name MarketCartView
extends Node3D
## Fase 203: o carrinho de feira. Junto de cada mercado, na célula livre encostada nele que dá para a rua e fica mais perto da
## porta (a busca da bomba d'água: `WaterPumpView.beside_street`, fora das células que as outras peças já tomam), o carrinho
## de mão de duas rodas com o tabuleiro inclinado cheio de maçãs, couves, cenouras e batatas, os varais e o guarda-sol
## listrado num mastro (`cart_mesh`), de comprido ao longo da rua. A bomba e o poço desviam dele, e o recheio deixa a célula
## limpa. Só a ilha com relevo; um MultiMesh; nada no save; refeito na obra, na demolição, na estrada, na derrubada de árvores
## e ao trocar de mundo.

const MARKETS: Array[StringName] = [&"market"]
## O carrinho: a caixa, as rodas, o tabuleiro e o guarda-sol.
const BOX_M := Vector3(0.8, 0.32, 1.2)
## O tabuleiro logo acima da caixa.
const BED_M := 0.05
const WHEEL_M := 0.36
const POLE_M := 2.05
const SHADE_M := 0.95
const GORES := 8
const WOOD := Color(0.48, 0.34, 0.2)
const WOOD_DARK := Color(0.33, 0.24, 0.15)
const IRON := Color(0.15, 0.15, 0.16)
const STRIPE_A := Color(0.74, 0.16, 0.14)
const STRIPE_B := Color(0.94, 0.9, 0.8)
const PRODUCE: Array[Color] = [Color(0.72, 0.1, 0.08), Color(0.4, 0.62, 0.2), Color(0.9, 0.48, 0.12), Color(0.6, 0.45, 0.26),
		Color(0.85, 0.72, 0.2)]

var _simulation: Simulation
var _carts := MultiMeshInstance3D.new()
## Os lugares dos carrinhos (testes: sem tela o MultiMesh devolve transformações zeradas).
var places: Array[Transform3D] = []
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_carts.name = "MarketCarts"
	_carts.multimesh = MultiMesh.new()
	_carts.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_carts.multimesh.mesh = cart_mesh()
	_carts.multimesh.custom_aabb = WorldBounds.of(simulation.config)
	_carts.material_override = material
	add_child(_carts)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.trees_changed.connect(func(_island_id: int, _area: Rect2i) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func cart_count() -> int:
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
			var street: Vector2i = found[cell]
			var x := grid.origin_m.x + (cell.x + 0.5) * grid.cell_size
			var z := grid.origin_m.y + (cell.y + 0.5) * grid.cell_size
			# de comprido ao longo da rua: o z da malha de través dela, os varais (−z) para o lado da rua
			places.append(Transform3D(Basis.looking_at(Vector3(street.x, 0.0, street.y), Vector3.UP),
					Vector3(x, grid.height_at(x, z), z)))
	_carts.multimesh.instance_count = places.size()
	for i: int in places.size():
		_carts.multimesh.set_instance_transform(i, places[i])


## As células dos carrinhos na ilha → o lado da rua. Vazio na ilha plana.
static func cells(world: WorldState, data: GameData, island_id: int) -> Dictionary[Vector2i, Vector2i]:
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		var none: Dictionary[Vector2i, Vector2i] = {}
		return none
	var ids: Array[int] = []
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id == island_id and record.def_id in MARKETS:
			ids.append(id)
	ids.sort()
	return WaterPumpView.beside_street(world, data, island_id, ids, WaterPumpView.taken_cells(world, data, island_id))


## O carrinho com o pé no zero e os varais para −z: a caixa de tábuas sobre o eixo, as duas rodas de raios, o pé de trás, os
## dois varais, o tabuleiro inclinado com a fruta e a verdura em montinhos e o guarda-sol de gomos listrados no mastro.
static func cart_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := BOX_M * 0.5
	var bottom := WHEEL_M + 0.02
	VertexShapes.box(tool, Vector3(0.0, bottom + half.y, 0.0), half, WOOD)
	# as rodas no eixo do meio, de lado
	for side: float in [-1.0, 1.0]:
		var hub := Vector3(side * (half.x + 0.06), WHEEL_M, 0.0)
		VertexShapes.cylinder(tool, hub - Vector3(0.025, 0.0, 0.0), hub + Vector3(0.025, 0.0, 0.0), WHEEL_M, WOOD_DARK, 14)
		VertexShapes.cylinder(tool, hub - Vector3(0.035, 0.0, 0.0), hub + Vector3(0.035, 0.0, 0.0), 0.06, IRON, 8)
	VertexShapes.strut(tool, Vector3(-half.x - 0.06, WHEEL_M, 0.0), Vector3(half.x + 0.06, WHEEL_M, 0.0), 0.025, 0.025, IRON)
	# o pé de trás e os varais para a frente
	VertexShapes.strut(tool, Vector3(0.0, bottom, half.z - 0.05), Vector3(0.0, 0.0, half.z + 0.05), 0.03, 0.03, WOOD_DARK)
	for side: float in [-1.0, 1.0]:
		VertexShapes.strut(tool, Vector3(side * (half.x - 0.06), bottom + 0.05, -half.z + 0.1),
				Vector3(side * (half.x - 0.12), 0.45, -half.z - 0.75), 0.025, 0.025, WOOD_DARK)
	# o tabuleiro inclinado para a frente e os montinhos
	var tilt := Basis(Vector3.RIGHT, -0.18)
	var bed := Vector3(0.0, bottom + BOX_M.y + BED_M, 0.0)
	VertexShapes.oriented_box(tool, Transform3D(tilt, bed), Vector3(half.x + 0.04, 0.02, half.z + 0.04), WOOD_DARK)
	var k := 0
	for row: int in 3:
		for col: int in 4:
			var at := Vector3(lerpf(-half.x + 0.12, half.x - 0.12, col / 3.0), 0.07,
					lerpf(-half.z + 0.18, half.z - 0.18, row / 2.0))
			var color := PRODUCE[(row * 4 + col * 3) % PRODUCE.size()]
			for lump: int in 4:
				var offset := Vector3(0.05 * ((lump % 2) * 2 - 1), 0.04 * (lump / 2), 0.05 * (((lump + k) % 3) - 1))
				PerchedGullView._blob(tool, Transform3D(Basis.from_scale(Vector3.ONE * 0.065), bed + tilt * (at + offset)),
						color)
			k += 1
	# o mastro e o guarda-sol de gomos
	var pole_foot := Vector3(half.x - 0.06, bottom + BOX_M.y, half.z - 0.06)
	var top := Vector3(pole_foot.x, POLE_M, pole_foot.z)
	VertexShapes.strut(tool, pole_foot, top + Vector3(0.0, 0.12, 0.0), 0.02, 0.02, WOOD_DARK)
	var rim := Vector3(pole_foot.x, POLE_M - 0.1, pole_foot.z)
	var apex := Vector3(pole_foot.x, POLE_M + 0.12, pole_foot.z)
	for g: int in GORES:
		var a0 := TAU * g / GORES
		var a1 := TAU * (g + 1) / GORES
		var p0 := rim + Vector3(cos(a0), 0.0, sin(a0)) * SHADE_M
		var p1 := rim + Vector3(cos(a1), 0.0, sin(a1)) * SHADE_M
		VertexShapes.tri(tool, apex, p0, p1, STRIPE_A if g % 2 == 0 else STRIPE_B)
	tool.generate_normals()
	return tool.commit()
