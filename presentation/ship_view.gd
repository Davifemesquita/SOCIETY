class_name ShipView
extends Node3D
## Navios no mar (seção 9): casco, mastro e velas provisórios por navio (placeholder até os
## modelos), balançando nas ondas; o do comerciante com vela vermelha. Só lê a simulação: a
## posição e o rumo são interpolados entre o tick anterior e o atual. Também desenha o posto do
## comerciante no mar aberto e a marca do navio selecionado, e acha o navio sob o cursor.
## Rastro na água e gaivotas ficam para a Fase 9 (assets/TODO_ASSETS.md).

## Raio do clique em volta do navio, em pixels da tela.
const PICK_RADIUS_PX := 40.0
const BOB_AMPLITUDE_M := 0.18
const BOB_SPEED := 1.3
const ROLL_RAD := 0.035
const HULL_HEIGHT_M := 1.6
const POST_COLOR := Color(0.42, 0.32, 0.22)
const FLAG_COLOR := Color(0.72, 0.22, 0.18)
const SELECTION_COLOR := Color(1.0, 0.85, 0.3)

var selected_ship: int = 0

var _simulation: Simulation
var _nodes: Dictionary[int, Node3D] = {}
var _post: Node3D
var _selection := MeshInstance3D.new()
var _materials: Dictionary[Color, StandardMaterial3D] = {}
var _time: float = 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var ring := TorusMesh.new()
	ring.inner_radius = 9.0
	ring.outer_radius = 10.0
	ring.material = _material(SELECTION_COLOR, true)
	_selection.mesh = ring
	_selection.visible = false
	add_child(_selection)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


## Refaz tudo (mundo trocado ao carregar).
func rebuild() -> void:
	for node: Node3D in _nodes.values():
		node.queue_free()
	_nodes.clear()
	if _post != null:
		_post.queue_free()
		_post = null
	selected_ship = 0
	if _simulation.data.trader() != null:
		_post = _build_post()
		add_child(_post)
		var point := _simulation.harbors().trader_post
		_post.position = Vector3(point.x, 0.0, point.y)


func ship_count() -> int:
	return _nodes.size()


## Nó do navio (para os testes conferirem posição e rumo).
func ship_node(ship_id: int) -> Node3D:
	return _nodes.get(ship_id)


func _process(delta: float) -> void:
	_time += delta
	var world := _simulation.world
	for ship_id: int in _nodes.keys():
		if not world.ships.has(ship_id):
			_nodes[ship_id].queue_free()
			_nodes.erase(ship_id)
	var alpha := GameClock.clock.interpolation_alpha()
	for ship: Ship in world.ships.values():
		if not ship.is_placed():
			continue
		if not _nodes.has(ship.id):
			_nodes[ship.id] = _build_ship(ship)
			add_child(_nodes[ship.id])
		var node := _nodes[ship.id]
		var previous := ship.previous_position if not is_nan(ship.previous_position.x) else ship.position
		var place := previous.lerp(ship.position, alpha)
		var heading := lerp_angle(ship.previous_heading, ship.heading, alpha)
		var phase := _time * BOB_SPEED + ship.id * 1.7
		node.position = Vector3(place.x, sin(phase) * BOB_AMPLITUDE_M, place.y)
		node.basis = Basis(Vector3.UP, -heading) * Basis(Vector3.RIGHT, sin(phase * 0.8) * ROLL_RAD)
	var selected: Node3D = _nodes.get(selected_ship)
	_selection.visible = selected != null
	if selected != null:
		_selection.position = Vector3(selected.position.x, 0.3, selected.position.z)


func select(ship_id: int) -> void:
	selected_ship = ship_id


## Navio sob a posição da tela (o mais perto, até PICK_RADIUS_PX), ou 0.
func ship_at_screen(camera: Camera3D, screen_position: Vector2) -> int:
	var best := 0
	var best_gap := PICK_RADIUS_PX
	for ship_id: int in _nodes:
		var node := _nodes[ship_id]
		var point := node.position + Vector3(0.0, HULL_HEIGHT_M, 0.0)
		if camera.is_position_behind(point):
			continue
		var gap := camera.unproject_position(point).distance_to(screen_position)
		if gap < best_gap:
			best = ship_id
			best_gap = gap
	return best


## O posto do comerciante está sob a posição da tela.
func trader_post_at_screen(camera: Camera3D, screen_position: Vector2) -> bool:
	if _post == null or camera.is_position_behind(_post.position):
		return false
	return camera.unproject_position(_post.position + Vector3(0.0, 2.0, 0.0)).distance_to(screen_position) < PICK_RADIUS_PX * 1.5


## Casco (com a proa em +X), mastro e duas velas; o tamanho e as cores saem do ShipDef.
func _build_ship(ship: Ship) -> Node3D:
	var def := _simulation.data.ship(ship.def_id)
	var root := Node3D.new()
	root.name = "Ship%d" % ship.id
	var length := def.length_m
	var beam := length * 0.28
	var hull := MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(length * 0.78, HULL_HEIGHT_M, beam)
	hull_mesh.material = _material(def.hull_color)
	hull.mesh = hull_mesh
	hull.position = Vector3(-length * 0.08, HULL_HEIGHT_M * 0.3, 0.0)
	root.add_child(hull)
	var bow := MeshInstance3D.new()
	var bow_mesh := PrismMesh.new()
	bow_mesh.size = Vector3(beam, length * 0.22, HULL_HEIGHT_M)
	bow_mesh.material = _material(def.hull_color)
	bow.mesh = bow_mesh
	# o prisma tem a ponta em +Y e a espessura em Z: deitado, a ponta vai para +X (proa) e a
	# espessura fica na vertical, da altura do casco
	bow.basis = Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))
	bow.position = Vector3(length * 0.42, HULL_HEIGHT_M * 0.3, 0.0)
	root.add_child(bow)
	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(length * 0.7, 0.15, beam * 0.86)
	deck_mesh.material = _material(def.hull_color.lightened(0.3))
	deck.mesh = deck_mesh
	deck.position = Vector3(-length * 0.08, HULL_HEIGHT_M * 0.8 + 0.08, 0.0)
	root.add_child(deck)
	var mast_height := length * 0.75
	for offset: float in [length * 0.12, -length * 0.22]:
		var mast := MeshInstance3D.new()
		var mast_mesh := CylinderMesh.new()
		mast_mesh.top_radius = 0.12
		mast_mesh.bottom_radius = 0.18
		mast_mesh.height = mast_height
		mast_mesh.material = _material(def.hull_color.darkened(0.2))
		mast.mesh = mast_mesh
		mast.position = Vector3(offset, HULL_HEIGHT_M + mast_height * 0.5, 0.0)
		root.add_child(mast)
		var sail := MeshInstance3D.new()
		var sail_mesh := BoxMesh.new()
		sail_mesh.size = Vector3(0.12, mast_height * 0.6, beam * 1.5)
		sail_mesh.material = _material(def.sail_color)
		sail.mesh = sail_mesh
		sail.position = Vector3(offset + 0.3, HULL_HEIGHT_M + mast_height * 0.55, 0.0)
		root.add_child(sail)
	return root


## Plataforma de madeira sobre estacas, com o mastro da bandeira do comerciante.
func _build_post() -> Node3D:
	var root := Node3D.new()
	root.name = "TraderPost"
	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(14.0, 1.0, 10.0)
	deck_mesh.material = _material(POST_COLOR)
	deck.mesh = deck_mesh
	deck.position = Vector3(0.0, 1.6, 0.0)
	root.add_child(deck)
	for corner: Vector2 in [Vector2(-6, -4), Vector2(6, -4), Vector2(-6, 4), Vector2(6, 4)]:
		var pile := MeshInstance3D.new()
		var pile_mesh := CylinderMesh.new()
		pile_mesh.top_radius = 0.35
		pile_mesh.bottom_radius = 0.35
		pile_mesh.height = 6.0
		pile_mesh.material = _material(POST_COLOR.darkened(0.3))
		pile.mesh = pile_mesh
		pile.position = Vector3(corner.x, -1.0, corner.y)
		root.add_child(pile)
	var hut := MeshInstance3D.new()
	var hut_mesh := BoxMesh.new()
	hut_mesh.size = Vector3(6.0, 4.0, 5.0)
	hut_mesh.material = _material(POST_COLOR.lightened(0.2))
	hut.mesh = hut_mesh
	hut.position = Vector3(-2.5, 4.1, 0.0)
	root.add_child(hut)
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.1
	pole_mesh.bottom_radius = 0.12
	pole_mesh.height = 9.0
	pole_mesh.material = _material(POST_COLOR.darkened(0.4))
	pole.mesh = pole_mesh
	pole.position = Vector3(4.0, 6.6, 0.0)
	root.add_child(pole)
	var flag := MeshInstance3D.new()
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(2.6, 1.6, 0.08)
	flag_mesh.material = _material(FLAG_COLOR)
	flag.mesh = flag_mesh
	flag.position = Vector3(5.3, 10.2, 0.0)
	root.add_child(flag)
	return root


func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		if unshaded:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials[color] = material
	return _materials[color]
