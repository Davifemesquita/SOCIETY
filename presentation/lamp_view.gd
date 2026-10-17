class_name LampView
extends Node3D
## Postes e fogueiras (seção 9, Fase 13): de noite, "janelas, postes e fogueiras acesos".
## - Poste: o lampião do Kenney Fantasy Town Kit nas ruas de paralelepípedo, uma célula calçada a cada
##   LAMP_EVERY (pelo desenho da grade), na beira da calçada, do lado que não é rua.
## - Fogueira: anel de pedras, lenha e chama atrás de uma casa de camponeses a cada BONFIRE_EVERY (pelo
##   id), na célula de trás se estiver livre.
## O vidro e a chama acendem pelo uniforme global night_light (shaders/night_glow.gdshader); a luz de
## verdade (OmniLight3D) só nos mais perto de onde a câmera olha, de noite. Só lê o mundo.

const LAMP_PATH := "res://assets/models/props/lantern.glb"
const LAMP_TEXTURE := "res://assets/models/props/Textures/colormap.png"
const LAMP_HEIGHT_M := 3.2
## O vidro do lampião, em fração da altura do poste: entre a base e o chapéu da armação do kit, e a meia
## largura (m) que enche a armação.
const GLASS_HEIGHT := 0.9
const GLASS_SPAN := 0.11
const GLASS_HALF_M := 0.17
const LAMP_EVERY := 4
## Do meio da célula da rua até o poste, para o lado da calçada.
const LAMP_OFFSET_M := 0.8
const BONFIRE_EVERY := 3
const LAMP_COLOR := Color(1.0, 0.82, 0.5)
const FIRE_COLOR := Color(1.0, 0.5, 0.15)
const STONE_COLOR := Color(0.42, 0.4, 0.38)
const WOOD_COLOR := Color(0.32, 0.22, 0.14)
## Luzes de verdade: quantas, até onde a câmera conta como perto e o alcance de cada uma.
const LIGHTS := 10
const LIGHT_CAMERA_DISTANCE_M := 90.0
const LIGHT_RANGE_M := 11.0
const LIGHT_SECONDS := 0.5
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _simulation: Simulation
var _cell_size: float
var _posts := MultiMeshInstance3D.new()
var _glass := MultiMeshInstance3D.new()
var _pits := MultiMeshInstance3D.new()
var _flames := MultiMeshInstance3D.new()
## Onde ficam o vidro de cada poste e a chama de cada fogueira (mundo), para as luzes.
var _lamp_points: Array[Vector3] = []
var _fire_points: Array[Vector3] = []
var _lights: Array[OmniLight3D] = []
var _light_left: float = 0.0
var _range_m: float = 260.0
var _dirty: bool = false


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	_posts.name = "Posts"
	_glass.name = "Glass"
	_pits.name = "Pits"
	_flames.name = "Flames"
	_posts.multimesh = _multimesh(post_mesh(), false)
	_glass.multimesh = _multimesh(glass_mesh(), true)
	_pits.multimesh = _multimesh(pit_mesh(), false)
	_flames.multimesh = _multimesh(flame_mesh(), true)
	for layer: MultiMeshInstance3D in [_posts, _glass, _pits, _flames]:
		add_child(layer)
	for i: int in LIGHTS:
		var light := OmniLight3D.new()
		light.omni_range = LIGHT_RANGE_M
		light.light_energy = 0.0
		light.shadow_enabled = false
		light.visible = false
		add_child(light)
		_lights.append(light)
	_apply_range()
	EventBus.roads_changed.connect(func(_island_id: int) -> void: _dirty = true)
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.house_upgraded.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	_apply_range()


func lamp_count() -> int:
	return _lamp_points.size()


func bonfire_count() -> int:
	return _fire_points.size()


func lamp_points() -> Array[Vector3]:
	return _lamp_points


func fire_points() -> Array[Vector3]:
	return _fire_points


func lit_lights() -> int:
	return _lights.filter(func(light: OmniLight3D) -> bool: return light.visible).size()


## Refaz postes e fogueiras de todas as ilhas.
func rebuild() -> void:
	_dirty = false
	_lamp_points.clear()
	_fire_points.clear()
	var posts: Array[Transform3D] = []
	var pits: Array[Transform3D] = []
	var world := _simulation.world
	for island_id: int in world.islands.size():
		var grid := world.island(island_id)
		for cell: Vector2i in grid.road_cells():
			if not grid.is_paved(cell) or posmod(cell.x + cell.y * 3, LAMP_EVERY) != 0:
				continue
			# na escada diagonal (Fase 17) todo lado da célula é cortado pela faixa: o poste ficaria na rua
			if not RoadView.diagonal_links(grid, cell).is_empty():
				continue
			var side := _sidewalk_side(grid, cell)
			if side == Vector2i.ZERO:
				continue
			var base := grid.surface_world(cell) + Vector3(side.x, 0.0, side.y) * LAMP_OFFSET_M
			posts.append(Transform3D(Basis.IDENTITY, base))
			_lamp_points.append(base + Vector3(0.0, LAMP_HEIGHT_M * GLASS_HEIGHT, 0.0))
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		if not record.is_house() or record.tier != &"peasants" or building_id % BONFIRE_EVERY != 0:
			continue
		var spot: Variant = bonfire_spot(_simulation, record)
		if spot is Vector3:
			var point: Vector3 = spot
			pits.append(Transform3D(Basis(Vector3.UP, float(building_id)), point))
			_fire_points.append(point + Vector3(0.0, 0.5, 0.0))
	_fill(_posts.multimesh, posts, Color.WHITE)
	_fill(_glass.multimesh, posts, Color(LAMP_COLOR, 0.0))
	_fill(_pits.multimesh, pits, Color.WHITE)
	_fill(_flames.multimesh, pits, Color(FIRE_COLOR, 1.0))


## Lado da célula da rua que dá para fora dela (calçada); ZERO se a célula está cercada de rua.
static func _sidewalk_side(grid: IslandGrid, cell: Vector2i) -> Vector2i:
	for side: Vector2i in SIDES:
		var next := cell + side
		if grid.in_bounds(next) and not grid.has_road(next):
			return side
	return Vector2i.ZERO


## Onde vai a fogueira da casa (mundo): no meio da célula logo atrás dela, se essa célula está livre
## (sem prédio nem rua); null se não há lugar.
static func bonfire_spot(simulation: Simulation, record: BuildingRecord) -> Variant:
	var grid := simulation.world.island(record.island_id)
	var def := simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var back := -Footprint.front_direction(record.rotation)
	var entrance := Footprint.entrance_cell(record.origin, def.size, record.rotation)
	# a célula de entrada fica fora, na frente: a de trás está a profundidade + 1 depois dela
	var depth := area.size.y if posmod(record.rotation, 2) == 0 else area.size.x
	var behind := entrance + back * (depth + 1)
	if not grid.in_bounds(behind) or area.has_point(behind) or grid.building_at(behind) != 0 or grid.has_road(behind):
		return null
	return grid.surface_world(behind)


func _process(delta: float) -> void:
	if _dirty:
		rebuild()
	_light_left -= delta
	if _light_left <= 0.0:
		_light_left = LIGHT_SECONDS
		var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
		if camera != null:
			place_lights(camera.global_position, -camera.global_basis.z, DayClock.night_factor(
					_simulation.config, GameClock.clock.hour()))


## Acende as luzes de verdade nos postes e fogueiras mais perto de onde a câmera olha, de noite e com
## a câmera perto; senão, apaga todas.
func place_lights(camera_position: Vector3, camera_forward: Vector3, night: float) -> void:
	var focus := camera_position
	if camera_forward.y < -0.01:
		focus = camera_position + camera_forward * (-camera_position.y / camera_forward.y)
	var close := camera_position.distance_to(focus) <= LIGHT_CAMERA_DISTANCE_M
	var candidates: Array = []
	if night > 0.05 and close:
		for point: Vector3 in _lamp_points:
			candidates.append([point.distance_squared_to(focus), point, false])
		for point: Vector3 in _fire_points:
			candidates.append([point.distance_squared_to(focus), point, true])
		candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i: int in _lights.size():
		var light := _lights[i]
		light.visible = i < candidates.size()
		if not light.visible:
			continue
		var chosen: Array = candidates[i]
		var fire: bool = chosen[2]
		light.position = chosen[1]
		light.light_color = FIRE_COLOR if fire else LAMP_COLOR
		light.light_energy = (1.6 if fire else 4.0) * night


func _fill(multimesh: MultiMesh, places: Array[Transform3D], color: Color) -> void:
	if multimesh.instance_count < places.size():
		multimesh.instance_count = places.size() + 32
	multimesh.visible_instance_count = places.size()
	for i: int in places.size():
		multimesh.set_instance_transform(i, places[i])
		if multimesh.use_colors:
			multimesh.set_instance_color(i, color)


func _multimesh(mesh: Mesh, colored: bool) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = colored
	multimesh.mesh = mesh
	return multimesh


func _apply_range() -> void:
	for layer: MultiMeshInstance3D in [_posts, _glass, _pits, _flames]:
		layer.visibility_range_end = _range_m
		layer.visibility_range_end_margin = _range_m * 0.1
		layer.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


static func _glow_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/night_glow.gdshader") as Shader
	return material


## O poste do kit numa malha só, com LAMP_HEIGHT_M de altura e a base em y = 0; sem o modelo, uma
## haste fina.
static func post_mesh() -> Mesh:
	if not ResourceLoader.exists(LAMP_PATH):
		var rod := CylinderMesh.new()
		rod.top_radius = 0.06
		rod.bottom_radius = 0.08
		rod.height = LAMP_HEIGHT_M
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.append_from(rod, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, LAMP_HEIGHT_M * 0.5, 0.0)))
		return tool.commit()
	var root := (load(LAMP_PATH) as PackedScene).instantiate() as Node3D
	var parts: Array[MeshInstance3D] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		parts.append(node as MeshInstance3D)
	var box := AABB()
	for i: int in parts.size():
		var local := CargoKit._transform_to(root, parts[i]) * parts[i].get_aabb()
		box = local if i == 0 else box.merge(local)
	var scale := LAMP_HEIGHT_M / maxf(box.size.y, 0.001)
	var bottom := Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var place := Transform3D(Basis.from_scale(Vector3.ONE * scale), -bottom * scale)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: MeshInstance3D in parts:
		for surface: int in part.mesh.get_surface_count():
			tool.append_from(part.mesh, surface, place * CargoKit._transform_to(root, part))
	root.free()
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(LAMP_TEXTURE) as Texture2D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.8
	mesh.surface_set_material(0, material)
	return mesh


## O vidro aceso do lampião: uma caixa que enche a armação aberta do modelo.
static func glass_mesh() -> Mesh:
	var box := BoxMesh.new()
	box.size = Vector3(GLASS_HALF_M * 2.0, LAMP_HEIGHT_M * GLASS_SPAN, GLASS_HALF_M * 2.0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.append_from(box, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, LAMP_HEIGHT_M * GLASS_HEIGHT, 0.0)))
	var mesh := tool.commit()
	mesh.surface_set_material(0, _glow_material())
	return mesh


## Anel de pedras e duas achas cruzadas, parados (a chama é outra malha).
static func pit_mesh() -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stone := BoxMesh.new()
	stone.size = Vector3(0.28, 0.2, 0.22)
	var stones := 8
	for i: int in stones:
		var angle := TAU * i / stones
		tool.append_from(stone, 0, Transform3D(Basis(Vector3.UP, angle), Vector3(cos(angle), 0.1, sin(angle)) * Vector3(0.6, 1.0, 0.6)))
	var wood := CylinderMesh.new()
	wood.top_radius = 0.06
	wood.bottom_radius = 0.06
	wood.height = 0.9
	wood.radial_segments = 6
	wood.rings = 1
	for angle: float in [0.4, -0.4 + PI * 0.5]:
		tool.append_from(wood, 0, Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, 0.1, 0.0)))
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = STONE_COLOR.lerp(WOOD_COLOR, 0.3)
	material.roughness = 1.0
	mesh.surface_set_material(0, material)
	return mesh


## A chama: dois cones cruzados (o shader a faz tremular e some de dia).
static func flame_mesh() -> Mesh:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.32
	cone.height = 0.9
	cone.radial_segments = 6
	cone.rings = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.append_from(cone, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.45, 0.0)))
	tool.append_from(cone, 0, Transform3D(Basis(Vector3.UP, PI / 6.0).scaled(Vector3(0.7, 0.75, 0.7)), Vector3(0.12, 0.35, 0.05)))
	var mesh := tool.commit()
	mesh.surface_set_material(0, _glow_material())
	return mesh
