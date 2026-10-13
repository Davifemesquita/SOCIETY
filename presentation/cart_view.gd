class_name CartView
extends Node3D
## Carroças na estrada (seção 9): caixa marrom com a carga na cor do bem na ida e vazia na
## volta. Só lê as carroças da simulação; a posição é interpolada entre o tick anterior e o
## atual, para andar liso a 60 quadros com 5 ticks por segundo (seção 12).

const BODY_COLOR := Color(0.42, 0.3, 0.2)
const BODY_SIZE := Vector3(1.4, 0.8, 2.3)
const CARGO_SIZE := Vector3(1.2, 0.8, 1.5)
const HEIGHT_M := 0.5

var _simulation: Simulation
var _cell_size: float
var _bodies := MultiMeshInstance3D.new()
var _loads := MultiMeshInstance3D.new()


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	var body := BoxMesh.new()
	body.size = BODY_SIZE
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = BODY_COLOR
	body.material = body_material
	_bodies.multimesh = _multimesh(body, false)
	var cargo := BoxMesh.new()
	cargo.size = CARGO_SIZE
	var cargo_material := StandardMaterial3D.new()
	cargo_material.vertex_color_use_as_albedo = true
	cargo.material = cargo_material
	_loads.multimesh = _multimesh(cargo, true)
	add_child(_bodies)
	add_child(_loads)


func _multimesh(mesh: Mesh, colored: bool) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = colored
	multimesh.mesh = mesh
	return multimesh


func visible_carts() -> int:
	return _bodies.multimesh.visible_instance_count


func _process(_delta: float) -> void:
	var world := _simulation.world
	var alpha := GameClock.clock.interpolation_alpha()
	var away: Array[Cart] = []
	for cart: Cart in world.carts.values():
		if cart.is_away() and cart.path.size() > 0:
			away.append(cart)
	if _bodies.multimesh.instance_count < away.size():
		_bodies.multimesh.instance_count = away.size() + 16
		_loads.multimesh.instance_count = away.size() + 16
	_bodies.multimesh.visible_instance_count = away.size()
	_loads.multimesh.visible_instance_count = away.size()
	for index: int in away.size():
		var cart := away[index]
		var grid := world.island(world.building(cart.home_id).island_id)
		var position := lerpf(cart.previous_position, cart.position, alpha)
		var place := _point(grid, cart.path, position)
		var ahead := _point(grid, cart.path, position + (0.5 if cart.state == Cart.State.OUTBOUND else -0.5))
		var basis := Basis.IDENTITY
		if not ahead.is_equal_approx(place):
			basis = Basis.looking_at((ahead - place).normalized(), Vector3.UP)
		_bodies.multimesh.set_instance_transform(index, Transform3D(basis, place + Vector3(0.0, HEIGHT_M, 0.0)))
		var tons := cart.tons()
		var load_basis := basis.scaled(Vector3.ONE * clampf(tons / 2.0, 0.0, 1.0)) if tons > 0.0 else basis.scaled(Vector3.ZERO)
		_loads.multimesh.set_instance_transform(index, Transform3D(load_basis, place + Vector3(0.0, HEIGHT_M + 0.6, 0.0)))
		_loads.multimesh.set_instance_color(index, _cargo_color(cart))


## Ponto da rota na posição contínua (2,5 = meio entre a célula 2 e a 3).
func _point(grid: IslandGrid, path: PackedInt32Array, position: float) -> Vector3:
	var clamped := clampf(position, 0.0, path.size() - 1)
	var index := floori(clamped)
	var next := mini(index + 1, path.size() - 1)
	var from := grid.surface_world(grid.cell_at(path[index]))
	var to := grid.surface_world(grid.cell_at(path[next]))
	return from.lerp(to, clamped - index)


func _cargo_color(cart: Cart) -> Color:
	for good: StringName in cart.cargo:
		return _simulation.data.good(good).color
	return Color.WHITE
