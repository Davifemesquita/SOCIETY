class_name ShipView
extends Node3D
## Navios no mar (seção 9): casco, mastro e velas provisórios por navio (placeholder até os
## modelos), balançando nas ondas; o do comerciante com vela vermelha. Só lê a simulação: a
## posição e o rumo são interpolados entre o tick anterior e o atual. Também desenha o posto do
## comerciante no mar aberto e a marca do navio selecionado, e acha o navio sob o cursor.
## Desde a Fase 9: casco de tábuas, velas enfunadas, rastro de espuma enquanto navega e gaivotas
## voando em volta dos portos (entrepostos e píeres). Desde a Fase 11: clarão e fumaça dos tiros,
## fumaça do navio avariado (casco abaixo da metade) e o navio afundado descendo devagar antes de sumir.

## Raio do clique em volta do navio, em pixels da tela.
const PICK_RADIUS_PX := 40.0
const BOB_AMPLITUDE_M := 0.18
const BOB_SPEED := 1.3
const ROLL_RAD := 0.035
const HULL_HEIGHT_M := 1.6
## Modelos dos navios (Kenney Pirate Kit): onde ficam, o giro que põe a proa em +X e quanto do
## modelo (em unidades dele) fica abaixo d'água.
const MODEL_DIR := "res://assets/models/ships/%s.glb"
const MODEL_YAW := PI * 0.5
const MODEL_DRAFT := 0.6
const SELECTION_COLOR := Color(1.0, 0.85, 0.3)
const WAKE_PARTICLES := 40
## Gaivotas: quantas por porto, o raio e a altura do voo em volta dele.
const GULLS_PER_PORT := 6
const GULL_RADIUS_M := Vector2(10.0, 26.0)
const GULL_HEIGHT_M := Vector2(9.0, 18.0)
const GULL_SPEED := 0.35
## Combate (Fase 11): quanto dura o clarão do tiro e quanto leva o navio para afundar.
const FLASH_SECONDS := 0.35
## A água é transparente e grava profundidade: o que é transparente sobre ela (espuma, fumaça,
## clarão) precisa ser desenhado depois, ou some.
const ABOVE_WATER := 1
const DAMAGE_SMOKE_COLOR := Color(0.12, 0.11, 0.1, 1.0)
const SINK_SECONDS := 5.0
const FLASH_COLOR := Color(1.0, 0.85, 0.45)

var selected_ship: int = 0

var _simulation: Simulation
var _nodes: Dictionary[int, Node3D] = {}
var _post: Node3D
var _selection := MeshInstance3D.new()
var _materials: Dictionary[Color, StandardMaterial3D] = {}
var _time: float = 0.0
var _particles_ratio: float = 1.0
var _detail_range_m: float = 450.0
var _gulls := MultiMeshInstance3D.new()
## Centro de cada gaivota (o porto em volta do qual ela voa).
var _gull_centers: PackedVector3Array = PackedVector3Array()
## Portos com gaivotas (só eles refazem a revoada ao entrar ou sair: construir não varre tudo).
var _berths: Dictionary[int, bool] = {}
## Clarões dos tiros (nó → segundos que faltam) e navios afundando (nó → segundos que faltam).
var _flashes: Dictionary[Node3D, float] = {}
var _sinking: Dictionary[Node3D, float] = {}


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var ring := TorusMesh.new()
	ring.inner_radius = 9.0
	ring.outer_radius = 10.0
	ring.material = _material(SELECTION_COLOR, true)
	_selection.mesh = ring
	_selection.visible = false
	add_child(_selection)
	_gulls.name = "Gulls"
	_gulls.multimesh = MultiMesh.new()
	_gulls.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_gulls.multimesh.mesh = _gull_mesh()
	_gulls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_gulls)
	EventBus.world_replaced.connect(rebuild)
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.ship_fired.connect(_on_ship_fired)
	EventBus.ship_sunk.connect(_on_ship_sunk)
	rebuild()


## Refaz tudo (mundo trocado ao carregar).
func rebuild() -> void:
	for node: Node3D in _nodes.values():
		node.queue_free()
	_nodes.clear()
	for node: Node3D in _flashes.keys() + _sinking.keys():
		node.queue_free()
	_flashes.clear()
	_sinking.clear()
	if _post != null:
		_post.queue_free()
		_post = null
	selected_ship = 0
	_place_gulls()
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
		var wake := node.get_node_or_null(^"Wake") as GPUParticles3D
		if wake != null:
			wake.emitting = ship.state == Ship.State.SAILING
		var damage := node.get_node_or_null(^"Damage") as CPUParticles3D
		if damage != null:
			damage.emitting = ship.hp < _simulation.data.ship(ship.def_id).hull_points * 0.5
	_fly_gulls()
	_animate_combat(delta)
	var selected: Node3D = _nodes.get(selected_ship)
	_selection.visible = selected != null
	if selected != null:
		_selection.position = Vector3(selected.position.x, 0.3, selected.position.z)


## Navios afundando agora (testes).
func sinking_count() -> int:
	return _sinking.size()


func flash_count() -> int:
	return _flashes.size()


func _on_ship_fired(attacker_id: int, target_id: int) -> void:
	var attacker: Node3D = _nodes.get(attacker_id)
	var target: Node3D = _nodes.get(target_id)
	if attacker == null:
		return
	var flash := MeshInstance3D.new()
	var glow := QuadMesh.new()
	glow.size = Vector2(7.0, 7.0)
	glow.material = _flash_material()
	flash.mesh = glow
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var toward := Vector3.ZERO
	if target != null:
		toward = (target.position - attacker.position).normalized() * 8.0
	flash.position = attacker.position + toward + Vector3(0.0, HULL_HEIGHT_M + 2.5, 0.0)
	add_child(flash)
	_flashes[flash] = FLASH_SECONDS


## Clarão do tiro: bolota macia virada para a câmera, somando luz ao que está atrás.
func _flash_material() -> StandardMaterial3D:
	if not _materials.has(FLASH_COLOR):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.albedo_color = FLASH_COLOR
		material.albedo_texture = SmokeView._puff_texture()
		material.render_priority = ABOVE_WATER
		_materials[FLASH_COLOR] = material
	return _materials[FLASH_COLOR]


## O nó do navio afundado sai da lista (o _process não o apaga) e desce devagar, adernando.
func _on_ship_sunk(ship_id: int, _owner: int, _at: Vector2) -> void:
	var node: Node3D = _nodes.get(ship_id)
	if node == null:
		return
	_nodes.erase(ship_id)
	var wake := node.get_node_or_null(^"Wake") as GPUParticles3D
	if wake != null:
		wake.emitting = false
	_sinking[node] = SINK_SECONDS
	if selected_ship == ship_id:
		selected_ship = 0


func _animate_combat(delta: float) -> void:
	for flash: Node3D in _flashes.keys():
		_flashes[flash] -= delta
		flash.scale = Vector3.ONE * (1.0 + (FLASH_SECONDS - _flashes[flash]) * 3.0)
		if _flashes[flash] <= 0.0:
			_flashes.erase(flash)
			flash.queue_free()
	for node: Node3D in _sinking.keys():
		_sinking[node] -= delta
		var done := 1.0 - _sinking[node] / SINK_SECONDS
		node.position.y = -done * 8.0
		node.basis = node.basis.slerp(Basis(Vector3.FORWARD, 0.6) * node.basis, delta * 0.4)
		if _sinking[node] <= 0.0:
			_sinking.erase(node)
			node.queue_free()


func select(ship_id: int) -> void:
	selected_ship = ship_id


## Nível gráfico: quantas partículas no rastro e até onde velas, rastro e gaivotas aparecem.
func set_quality(preset: GraphicsPresetDef) -> void:
	_particles_ratio = preset.particles_ratio
	_detail_range_m = _simulation.config.smoke_visibility_range_m * preset.visibility_scale
	_gulls.visibility_range_end = _detail_range_m
	for node: Node3D in _nodes.values():
		node.queue_free()
	_nodes.clear()


func gull_count() -> int:
	return _gulls.multimesh.instance_count


func _on_building_placed(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record != null and _simulation.def_of(record).is_berth():
		_place_gulls()


func _on_building_removed(building_id: int) -> void:
	if _berths.has(building_id):
		_place_gulls()


## Gaivotas em volta de cada porto (entreposto e píer).
func _place_gulls() -> void:
	_gull_centers = PackedVector3Array()
	_berths.clear()
	var world := _simulation.world
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if not def.is_berth():
			continue
		_berths[building_id] = true
		var center := world.island(record.island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation))
		for i: int in GULLS_PER_PORT:
			_gull_centers.append(center)
	_gulls.multimesh.instance_count = _gull_centers.size()
	_fly_gulls()


## Cada gaivota faz um círculo próprio (raio, altura e sentido pelo índice) em volta do porto.
func _fly_gulls() -> void:
	var multimesh := _gulls.multimesh
	for i: int in _gull_centers.size():
		var seed_value := float(i) * 1.618
		var radius := lerpf(GULL_RADIUS_M.x, GULL_RADIUS_M.y, fposmod(seed_value, 1.0))
		var height := lerpf(GULL_HEIGHT_M.x, GULL_HEIGHT_M.y, fposmod(seed_value * 2.3, 1.0))
		var turn := 1.0 if i % 2 == 0 else -1.0
		var angle := _time * GULL_SPEED * turn * (14.0 / radius) + seed_value * TAU
		var offset := Vector3(cos(angle) * radius, height + sin(_time * 1.3 + seed_value) * 1.2, sin(angle) * radius)
		var forward := Vector3(-sin(angle), 0.0, cos(angle)) * turn
		var flap := sin(_time * 9.0 + seed_value * 5.0) * 0.5
		var basis := Basis.looking_at(forward, Vector3.UP) * Basis(Vector3.FORWARD, flap * 0.3)
		multimesh.set_instance_transform(i, Transform3D(basis, _gull_centers[i] + offset))


## Gaivota de longe: duas asas em V, brancas.
static func _gull_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wing := 0.75
	for side: float in [-1.0, 1.0]:
		tool.add_vertex(Vector3(0.0, 0.0, -0.25))
		tool.add_vertex(Vector3(side * wing, 0.18, 0.05))
		tool.add_vertex(Vector3(0.0, 0.0, 0.25))
	tool.generate_normals()
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.95, 0.93)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, material)
	return mesh


func _sail_material(color: Color) -> StandardMaterial3D:
	var material := _material(color).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.9
	return material


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


## Casco de madeira afilado na proa e na popa (com a proa em +X), dois mastros e velas enfunadas;
## o tamanho e as cores saem do ShipDef. Desde a Fase 9 o casco é uma malha própria com a textura
## de tábuas, e o navio leva o rastro na água (Wake), ligado enquanto navega.
func _build_ship(ship: Ship) -> Node3D:
	var def := _simulation.data.ship(ship.def_id)
	var root := Node3D.new()
	root.name = "Ship%d" % ship.id
	var length := def.length_m
	var beam := length * 0.28
	var model := _model(def, sail_color(ship))
	if model != null:
		root.add_child(model)
		_add_effects(root, length, beam)
		return root
	var hull := MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = hull_mesh(length, beam, HULL_HEIGHT_M)
	hull.material_override = BuildingMaterials.walls()
	BuildingMaterials.dress(hull, BuildingMaterials.Wall.WOOD, def.hull_color, -HULL_HEIGHT_M)
	root.add_child(hull)
	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(length * 0.62, 0.12, beam * 0.78)
	deck.mesh = deck_mesh
	deck.material_override = BuildingMaterials.walls()
	BuildingMaterials.dress(deck, BuildingMaterials.Wall.WOOD, def.hull_color.lightened(0.35), 0.0)
	deck.position = Vector3(-length * 0.04, HULL_HEIGHT_M * 0.85, 0.0)
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
		sail.mesh = sail_mesh(mast_height * 0.6, beam * 1.5, beam * 0.18)
		sail.material_override = _sail_material(sail_color(ship))
		sail.position = Vector3(offset + 0.3, HULL_HEIGHT_M + mast_height * 0.55, 0.0)
		sail.visibility_range_end = _detail_range_m
		root.add_child(sail)
	_add_effects(root, length, beam)
	return root


func _add_effects(root: Node3D, length: float, beam: float) -> void:
	var wake := _build_wake(length, beam)
	wake.name = "Wake"
	root.add_child(wake)
	var damage := _build_damage_smoke(length)
	damage.name = "Damage"
	root.add_child(damage)


## O modelo do navio (Kenney Pirate Kit) deitado no eixo X com a proa para +X, esticado até o
## comprimento do tipo e afundado até a linha d'água, com as velas na cor dada. Sem modelo, null.
func _model(def: ShipDef, sails: Color) -> Node3D:
	if def.model.is_empty():
		return null
	var path := MODEL_DIR % def.model
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	var model := scene.instantiate() as Node3D
	model.name = "Hull"
	var size := _model_size(model)
	var scale_factor := def.length_m / maxf(size.z, 0.001)
	model.scale = Vector3.ONE * scale_factor
	model.rotation.y = MODEL_YAW
	model.position.y = -MODEL_DRAFT * scale_factor
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/ship_model.gdshader") as Shader
	material.set_shader_parameter(&"colormap", load(MODEL_DIR.get_base_dir().path_join("Textures/colormap.png")))
	material.set_shader_parameter(&"sail_tint", sails)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		mesh.material_override = material
	return model


## Tamanho do modelo (caixa de todas as malhas, no espaço dele).
static func _model_size(model: Node3D) -> Vector3:
	var box := AABB()
	var first := true
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		var local := _transform_to(model, mesh) * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box.size


static func _transform_to(root: Node3D, node: Node3D) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		var spatial: Node3D = current
		transform = spatial.transform * transform
		current = current.get_parent()
	return transform


## Fumaça escura subindo do convés do navio avariado (liga com o casco abaixo da metade). Na CPU:
## são poucas partículas por navio, e assim aparecem também no Godot por software.
func _build_damage_smoke(length: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.amount = maxi(roundi(24 * _particles_ratio), 6)
	particles.lifetime = 3.0
	particles.emitting = false
	particles.position = Vector3(-length * 0.1, HULL_HEIGHT_M + 1.0, 0.0)
	particles.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 30, 24))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.direction = Vector3.UP
	particles.spread = 15.0
	particles.initial_velocity_min = 1.5
	particles.initial_velocity_max = 2.5
	particles.gravity = Vector3(0.6, 0.4, 0.0)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	var fade := Gradient.new()
	fade.set_color(0, Color(DAMAGE_SMOKE_COLOR, 0.0))
	fade.set_color(1, Color(DAMAGE_SMOKE_COLOR, 0.0))
	fade.add_point(0.1, DAMAGE_SMOKE_COLOR)
	fade.add_point(0.6, Color(DAMAGE_SMOKE_COLOR, DAMAGE_SMOKE_COLOR.a * 0.6))
	particles.color_ramp = fade
	var puff := QuadMesh.new()
	puff.size = Vector2(3.2, 3.2)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = SmokeView._puff_texture()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = ABOVE_WATER
	puff.material = material
	particles.mesh = puff
	return particles


## Cor das velas: a do tipo de navio, ou a da companhia rival dona dele (Fase 11).
func sail_color(ship: Ship) -> Color:
	var rival := _simulation.world.rivals_state.by_ship(ship.id)
	return rival.def.color if rival != null else _simulation.data.ship(ship.def_id).sail_color


## Casco: seções de popa a proa, cada uma um U (fundo em V suave) cuja boca segue o perfil do
## navio — larga no meio, fina e mais alta na proa, arredondada na popa.
static func hull_mesh(length: float, beam: float, height: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections := 12
	var around := 9
	var rings: Array[PackedVector3Array] = []
	for i: int in sections + 1:
		var u := float(i) / sections
		var x := lerpf(-length * 0.5, length * 0.5, u)
		var width := beam * 0.5 * pow(sin(PI * clampf(u * 0.92 + 0.06, 0.0, 1.0)), 0.6) * (1.0 - 0.75 * smoothstep(0.75, 1.0, u))
		var sheer := height * (0.85 + 0.25 * smoothstep(0.7, 1.0, u) + 0.1 * smoothstep(0.25, 0.0, u))
		var ring := PackedVector3Array()
		for j: int in around + 1:
			var a := PI * float(j) / around
			ring.append(Vector3(x, sheer - (sheer + height * 0.35) * sin(a) * (0.7 + 0.3 * sin(a)), cos(a) * width))
		rings.append(ring)
	for i: int in sections:
		for j: int in around:
			var a := rings[i][j]
			var b := rings[i + 1][j]
			var c := rings[i + 1][j + 1]
			var d := rings[i][j + 1]
			tool.add_vertex(a)
			tool.add_vertex(b)
			tool.add_vertex(c)
			tool.add_vertex(a)
			tool.add_vertex(c)
			tool.add_vertex(d)
	tool.generate_normals()
	return tool.commit()


## Vela enfunada: grade com a barriga para a frente (+X), mais funda no meio.
static func sail_mesh(height: float, width: float, belly: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 6
	var points: Array[PackedVector3Array] = []
	for i: int in steps + 1:
		var row := PackedVector3Array()
		var v := float(i) / steps
		for j: int in steps + 1:
			var w := float(j) / steps
			var bulge := sin(PI * v) * sin(PI * w) * belly
			row.append(Vector3(bulge, (v - 0.5) * height, (w - 0.5) * width * lerpf(0.8, 1.0, v)))
		points.append(row)
	for i: int in steps:
		for j: int in steps:
			tool.add_vertex(points[i][j])
			tool.add_vertex(points[i + 1][j])
			tool.add_vertex(points[i + 1][j + 1])
			tool.add_vertex(points[i][j])
			tool.add_vertex(points[i + 1][j + 1])
			tool.add_vertex(points[i][j + 1])
	tool.generate_normals()
	return tool.commit()


## Rastro: espuma deitada na água, deixada para trás (as partículas ficam no mundo).
func _build_wake(length: float, beam: float) -> GPUParticles3D:
	var wake := GPUParticles3D.new()
	wake.local_coords = false
	wake.amount = maxi(1, roundi(WAKE_PARTICLES * _particles_ratio))
	wake.lifetime = 6.0
	wake.position = Vector3(-length * 0.5, 0.15 - BOB_AMPLITUDE_M, 0.0)
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.5, 0.0, beam * 0.4)
	process.gravity = Vector3.ZERO
	process.scale_min = 1.0
	process.scale_max = 1.6
	var growth := Curve.new()
	growth.add_point(Vector2(0.0, 0.6))
	growth.add_point(Vector2(1.0, 2.4))
	var curve := CurveTexture.new()
	curve.curve = growth
	process.scale_curve = curve
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.75))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	wake.process_material = process
	var foam := QuadMesh.new()
	foam.orientation = PlaneMesh.FACE_Y
	foam.size = Vector2(beam * 0.9, beam * 0.9)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = SmokeView._puff_texture()
	material.render_priority = ABOVE_WATER
	foam.material = material
	wake.draw_pass_1 = foam
	wake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wake.visibility_range_end = _detail_range_m
	wake.visibility_aabb = AABB(Vector3(-80, -2, -80), Vector3(160, 6, 160))
	wake.emitting = false
	return wake


## Posto do comerciante: a feitoria do TraderPostModel (Fase 15; antes, plataforma e casinha em caixas).
func _build_post() -> Node3D:
	return TraderPostModel.build()

func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		if unshaded:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials[color] = material
	return _materials[color]
