class_name CartView
extends Node3D
## Carroças na estrada (seção 9): a carroça do Kenney Fantasy Town Kit (as peças juntas numa malha
## só, para o MultiMesh) com a carga na forma do bem (Fase 13: sacos, barris, caixotes, toras ou monte,
## as peças do CargoKit, uma por tonelada) na ida e vazia na volta, puxada por um cavalo (Fase 13, o bicho
## da AnimalView andando); sem o modelo, uma caixa marrom. Só lê as carroças da simulação; a posição é interpolada entre o tick anterior e o
## atual, para andar liso a 60 quadros com 5 ticks por segundo (seção 12).

const BODY_COLOR := Color(0.42, 0.3, 0.2)
const BODY_SIZE := Vector3(1.4, 0.8, 2.3)
const CARGO_SIZE := Vector3(1.0, 0.6, 1.2)
## Carga de peças (Fase 13): onde fica o fundo da caçamba, o tamanho da peça na carroça e onde vai cada
## tonelada (frente e trás da caçamba).
const BED_M := 0.8
const CARGO_SCALE := 0.75
const CARGO_SLOTS: Array[float] = [-0.45, 0.45]
const HEIGHT_M := 0.5
const MODEL_PATH := "res://assets/models/props/cart.glb"
const MODEL_TEXTURE := "res://assets/models/props/Textures/colormap.png"
## Comprimento da carroça de modelo no mundo, e o giro que põe a frente dela (os varais) em −Z (para
## onde Basis.looking_at aponta). Até a Fase 13 ela andava de ré: sem o cavalo não se via.
const MODEL_LENGTH_M := 2.6
const MODEL_YAW := 0.0
## O cavalo entra entre os varais: quanto ele avança sobre a ponta da carroça.
const HORSE_OVERLAP_M := 0.5

var _simulation: Simulation
var _cell_size: float
var _bodies := MultiMeshInstance3D.new()
var _loads := MultiMeshInstance3D.new()
## Uma camada por tipo de peça (GoodDef.Pile); o bem sem peça (o porco) usa a caixa colorida.
var _cargo: Dictionary[int, MultiMeshInstance3D] = {}
## O cavalo de cada carroça (null sem o modelo do bicho).
var _horses: MultiMeshInstance3D


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	var body: Mesh = model_mesh()
	if body == null:
		var box := BoxMesh.new()
		box.size = BODY_SIZE
		var body_material := StandardMaterial3D.new()
		body_material.albedo_color = BODY_COLOR
		box.material = body_material
		body = box
	_bodies.multimesh = _multimesh(body, false)
	var cargo := BoxMesh.new()
	cargo.size = CARGO_SIZE
	var cargo_material := StandardMaterial3D.new()
	cargo_material.vertex_color_use_as_albedo = true
	cargo.material = cargo_material
	_loads.multimesh = _multimesh(cargo, true)
	add_child(_bodies)
	add_child(_loads)
	for pile: int in GoodDef.Pile.values():
		var mesh := CargoKit.mesh(pile)
		if mesh == null:
			continue
		var layer := MultiMeshInstance3D.new()
		layer.name = "Cargo%d" % pile
		layer.multimesh = _multimesh(mesh, CargoKit.tinted(pile))
		add_child(layer)
		_cargo[pile] = layer
	_horses = AnimalView.layer(&"horse")
	if _horses != null:
		_horses.name = "Horses"
		_horses.multimesh.visible_instance_count = 0
		add_child(_horses)


## As peças do modelo numa malha só, já no tamanho, no giro e com a base em y = −HEIGHT_M (a
## instância sobe HEIGHT_M). Null sem o modelo.
static func model_mesh() -> ArrayMesh:
	if not ResourceLoader.exists(MODEL_PATH):
		return null
	var model := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := 0.0
	var parts: Array[MeshInstance3D] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		parts.append(node as MeshInstance3D)
	var box := AABB()
	for index: int in parts.size():
		var local := ShipView._transform_to(model, parts[index]) * parts[index].get_aabb()
		box = local if index == 0 else box.merge(local)
	length = maxf(box.size.z, 0.001)
	var scale_factor := MODEL_LENGTH_M / length
	var place := Transform3D(Basis(Vector3.UP, MODEL_YAW).scaled(Vector3.ONE * scale_factor), Vector3(0.0, -HEIGHT_M, 0.0))
	for part: MeshInstance3D in parts:
		var transform := place * ShipView._transform_to(model, part)
		for surface: int in part.mesh.get_surface_count():
			tool.append_from(part.mesh, surface, transform)
	model.free()
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(MODEL_TEXTURE) as Texture2D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.9
	mesh.surface_set_material(0, material)
	return mesh


func _multimesh(mesh: Mesh, colored: bool) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = colored
	multimesh.mesh = mesh
	return multimesh


func visible_carts() -> int:
	return _bodies.multimesh.visible_instance_count


func visible_horses() -> int:
	return _horses.multimesh.visible_instance_count if _horses != null else 0


## Peças de carga à vista, de um tipo (GoodDef.Pile) ou de todos (-1).
func cargo_items(pile: int = -1) -> int:
	var total := 0
	for kind: int in _cargo:
		if pile < 0 or kind == pile:
			total += _cargo[kind].multimesh.visible_instance_count
	return total


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
	if _horses != null:
		if _horses.multimesh.instance_count < away.size():
			_horses.multimesh.instance_count = away.size() + 16
		_horses.multimesh.visible_instance_count = away.size()
	var items: Dictionary[int, Array] = {}
	for kind: int in _cargo:
		items[kind] = []
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
		if _horses != null:
			# o cavalo vai na frente da carroça (o −Z da base), com o pé no chão
			var reach := MODEL_LENGTH_M * 0.5 + float(AnimalView.LENGTH_M[&"horse"]) * 0.5 - HORSE_OVERLAP_M
			AnimalView.place(_horses.multimesh, index, &"horse", Transform3D(basis, place + basis * Vector3(0.0, 0.0, -reach)),
					cart.home_id, &"walk")
		var tons := cart.tons()
		var good := _cargo_good(cart)
		var pile := good.pile if good != null else GoodDef.Pile.NONE
		if tons > 0.0 and _cargo.has(pile):
			# uma peça por tonelada começada, da frente da caçamba para trás; a caixa fica escondida
			_loads.multimesh.set_instance_transform(index, Transform3D(basis.scaled(Vector3.ZERO), place))
			for slot: int in mini(ceili(tons - 0.000001), CARGO_SLOTS.size()):
				var offset := basis * Vector3(0.0, BED_M, CARGO_SLOTS[slot])
				items[pile].append([Transform3D(basis.scaled(Vector3.ONE * CARGO_SCALE), place + offset), CargoKit.color_of(good)])
			continue
		var load_basis := basis.scaled(Vector3.ONE * clampf(tons / 2.0, 0.0, 1.0)) if tons > 0.0 else basis.scaled(Vector3.ZERO)
		_loads.multimesh.set_instance_transform(index, Transform3D(load_basis, place + Vector3(0.0, HEIGHT_M + 0.45, 0.0)))
		_loads.multimesh.set_instance_color(index, _cargo_color(cart))
	for kind: int in items:
		var multimesh := _cargo[kind].multimesh
		var list: Array = items[kind]
		if multimesh.instance_count < list.size():
			multimesh.instance_count = list.size() + 16
		multimesh.visible_instance_count = list.size()
		for slot: int in list.size():
			var item: Array = list[slot]
			var where: Transform3D = item[0]
			multimesh.set_instance_transform(slot, where)
			if multimesh.use_colors:
				var color: Color = item[1]
				multimesh.set_instance_color(slot, color)


## Ponto da rota na posição contínua (2,5 = meio entre a célula 2 e a 3).
func _point(grid: IslandGrid, path: PackedInt32Array, position: float) -> Vector3:
	var clamped := clampf(position, 0.0, path.size() - 1)
	var index := floori(clamped)
	var next := mini(index + 1, path.size() - 1)
	var from := grid.surface_world(grid.cell_at(path[index]))
	var to := grid.surface_world(grid.cell_at(path[next]))
	return from.lerp(to, clamped - index)


func _cargo_good(cart: Cart) -> GoodDef:
	for good: StringName in cart.cargo:
		return _simulation.data.good(good)
	return null


func _cargo_color(cart: Cart) -> Color:
	for good: StringName in cart.cargo:
		return _simulation.data.good(good).color
	return Color.WHITE
