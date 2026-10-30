class_name LighthouseView
extends Node3D
## Fase 108: o farol. Em cada ilha com relevo e entreposto, na ponta de terra baixa e livre mais exposta ao mar a até
## SEARCH_CELLS do entreposto (`site`: a célula de terra com mais mar em volta), uma torre redonda caiada com faixas
## vermelhas, a galeria com o guarda-corpo, a lanterna de vidro e a cúpula (`tower_mesh`). À noite a lanterna acende (o
## vidro dos postes, global night_light) e dois fachos opostos giram em BEAM_TURN_S de jogo (para na pausa). Só apresentação:
## a célula não fica reservada; se alguém construir nela, o farol vai para a próxima ponta.

const SEARCH_CELLS := 40
## O mar em volta (quadrado de EXPOSURE_CELLS de raio) e o mínimo de células de mar para valer como ponta.
const EXPOSURE_CELLS := 4
const MIN_SEA_CELLS := 30
const MAX_HEIGHT_M := 4.0
const TOWER_M := 9.0
## O pé da lanterna (o alto do fuste, a galeria e a base dela) e o alto (onde nasce a cúpula).
const LANTERN_AT_M := 10.0
const LANTERN_TOP_M := 11.1
const BEAM_LENGTH_M := 45.0
const BEAM_RADIUS_M := 3.5
const BEAM_TURN_S := 12.0
const BEAM_ALPHA := 0.22
const WHITE := Color(0.92, 0.9, 0.85)
const RED := Color(0.62, 0.16, 0.13)
const STONE := Color(0.5, 0.48, 0.45)
const IRON := Color(0.16, 0.16, 0.17)
const LIGHT := Color(1.0, 0.86, 0.55)

var _simulation: Simulation
var _towers: Dictionary[int, Node3D] = {}
var _beams: Array[Node3D] = []
var _beam_material := StandardMaterial3D.new()
var _time: float = 0.0
var _dirty := true
var _tower: ArrayMesh
var _lantern: ArrayMesh
var _beam: ArrayMesh


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_tower = tower_mesh()
	_lantern = lantern_mesh()
	_beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_material.vertex_color_use_as_albedo = true
	_beam_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	# desenhado depois da água (transparente e do tamanho do mar, ela cobria o facho)
	_beam_material.render_priority = 25
	_beam = beam_mesh()
	_beam.surface_set_material(0, _beam_material)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.roads_changed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func tower_count() -> int:
	return _towers.size()


func tower_of(island_id: int) -> Node3D:
	return _towers.get(island_id)


func _mark(_id: int) -> void:
	_dirty = true


func rebuild() -> void:
	_dirty = false
	for node: Node3D in _towers.values():
		node.queue_free()
	_towers.clear()
	_beams.clear()
	var world := _simulation.world
	var done: Dictionary[int, bool] = {}
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		if not _simulation.def_of(record).is_trading_post or done.has(record.island_id):
			continue
		done[record.island_id] = true
		var found: Variant = site(_simulation, record)
		if found == null:
			continue
		var cell: Vector2i = found
		var grid := world.island(record.island_id)
		var spot := grid.cell_world(cell)
		var node := Node3D.new()
		node.name = "Lighthouse%d" % record.island_id
		node.position = Vector3(spot.x, grid.height_at(spot.x, spot.z), spot.z)
		var tower := MeshInstance3D.new()
		tower.mesh = _tower
		node.add_child(tower)
		var lantern := MeshInstance3D.new()
		lantern.mesh = _lantern
		lantern.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(lantern)
		var beam := MeshInstance3D.new()
		beam.mesh = _beam
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.position = Vector3(0.0, (LANTERN_AT_M + LANTERN_TOP_M) * 0.5, 0.0)
		node.add_child(beam)
		_beams.append(beam)
		add_child(node)
		_towers[record.island_id] = node


## A ponta do farol para o entreposto: a célula de terra livre (sem prédio, estrada, trilho nem árvore), baixa (até
## MAX_HEIGHT_M), a até SEARCH_CELLS dele, com mais mar em volta (pelo menos MIN_SEA_CELLS); no empate, a mais perto.
## Null na ilha plana ou sem ponta.
static func site(simulation: Simulation, record: BuildingRecord) -> Variant:
	var grid := simulation.world.island(record.island_id)
	if grid == null or grid.flat:
		return null
	var def := simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var middle := area.get_center()
	var search := area.grow(SEARCH_CELLS).intersection(Rect2i(Vector2i.ZERO, grid.size))
	var best: Variant = null
	var best_score := -INF
	for y: int in range(search.position.y, search.end.y):
		for x: int in range(search.position.x, search.end.x):
			var cell := Vector2i(x, y)
			var index := grid.index(cell)
			if grid.ground[index] != IslandGrid.Ground.LAND or grid.occupancy[index] != 0 \
					or grid.roads[index] != IslandGrid.Road.NONE or grid.rails[index] != 0 or grid.trees[index] > 0:
				continue
			var spot := grid.cell_world(cell)
			if grid.height_at(spot.x, spot.z) > MAX_HEIGHT_M:
				continue
			var sea := 0
			for dy: int in range(-EXPOSURE_CELLS, EXPOSURE_CELLS + 1):
				for dx: int in range(-EXPOSURE_CELLS, EXPOSURE_CELLS + 1):
					var other := cell + Vector2i(dx, dy)
					if not grid.in_bounds(other) or grid.ground_at(other) == IslandGrid.Ground.SEA:
						sea += 1
			if sea < MIN_SEA_CELLS:
				continue
			var score := sea * 1000.0 - Vector2(cell).distance_to(Vector2(middle))
			if score > best_score:
				best_score = score
				best = cell
	return best


## A torre: o soco de pedra, o fuste afinando em quatro lanços caiados com as faixas vermelhas, a galeria de ferro com
## os balaústres, a base da lanterna e a cúpula vermelha com o remate (a lanterna é a lantern_mesh, que acende).
static func tower_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_stack(tool, _cone(1.75, 1.6, 0.8), 0.0, STONE)
	var radii: Array[float] = [1.35, 1.25, 1.15, 1.05, 0.95]
	var step := TOWER_M / 4.0
	for i: int in 4:
		var color := RED if i % 2 == 1 else WHITE
		_stack(tool, _cone(radii[i], radii[i + 1], step), 0.6 + i * step, color)
	var top := 0.6 + TOWER_M
	_stack(tool, _cone(1.45, 1.45, 0.16), top, IRON)
	for k: int in 14:
		var angle := TAU * k / 14.0
		CropView._part(tool, CropView._box(Vector3(0.05, 0.75, 0.05)), Transform3D(Basis.IDENTITY,
				Vector3(cos(angle) * 1.38, top + 0.16 + 0.375, sin(angle) * 1.38)), IRON)
	_stack(tool, _cone(1.42, 1.42, 0.05), top + 0.9, IRON)
	_stack(tool, _cone(0.85, 0.85, 0.25), top + 0.16, WHITE)
	for k: int in 6:
		var angle := TAU * k / 6.0
		CropView._part(tool, CropView._box(Vector3(0.06, 1.1, 0.06)), Transform3D(Basis.IDENTITY,
				Vector3(cos(angle) * 0.72, top + 0.41 + 0.55, sin(angle) * 0.72)), IRON)
	_stack(tool, _cone(0.95, 0.0, 0.8), LANTERN_TOP_M, RED)
	_stack(tool, _cone(0.05, 0.05, 0.6), LANTERN_TOP_M + 0.7, IRON)
	tool.index()
	var mesh := tool.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	mesh.surface_set_material(0, material)
	return mesh


## O vidro da lanterna, no material do vidro dos postes (acende com a noite; o alfa zero no vértice é vidro, não chama).
static func lantern_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_stack(tool, _cone(0.68, 0.68, LANTERN_TOP_M - LANTERN_AT_M), LANTERN_AT_M, Color(LIGHT.r, LIGHT.g, LIGHT.b, 0.0))
	tool.index()
	var mesh := tool.commit()
	mesh.surface_set_material(0, LampView._glow_material())
	return mesh


## Os dois fachos opostos: cones deitados da lanterna até BEAM_LENGTH_M, mais fortes junto dela e sumindo na ponta.
static func beam_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 10
	for direction: float in [1.0, -1.0]:
		for k: int in sides:
			var a0 := TAU * k / sides
			var a1 := TAU * (k + 1) / sides
			var rim0 := Vector3(direction * BEAM_LENGTH_M, cos(a0) * BEAM_RADIUS_M * 0.5, sin(a0) * BEAM_RADIUS_M)
			var rim1 := Vector3(direction * BEAM_LENGTH_M, cos(a1) * BEAM_RADIUS_M * 0.5, sin(a1) * BEAM_RADIUS_M)
			for pair: Array in [[Vector3.ZERO, BEAM_ALPHA], [rim0, 0.0], [rim1, 0.0]]:
				var point: Vector3 = pair[0]
				var alpha: float = pair[1]
				tool.set_color(Color(LIGHT.r, LIGHT.g, LIGHT.b, alpha))
				tool.add_vertex(point)
	return tool.commit()


## A peça com a base em base_y (o cilindro do Godot sai centrado na altura).
static func _stack(tool: SurfaceTool, mesh: CylinderMesh, base_y: float, color: Color) -> void:
	CropView._part(tool, mesh, Transform3D(Basis.IDENTITY, Vector3(0.0, base_y + mesh.height * 0.5, 0.0)), color)


static func _cone(bottom: float, top: float, height: float) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.bottom_radius = bottom
	cone.top_radius = top
	cone.height = height
	cone.radial_segments = 16
	cone.rings = 1
	return cone


func _process(delta: float) -> void:
	if _simulation == null:
		return
	if _dirty:
		rebuild()
	_time += delta * GameClock.clock.speed_multiplier()
	var night := DayClock.night_factor(_simulation.config, GameClock.clock.hour())
	_beam_material.albedo_color = Color(1.0, 1.0, 1.0, smoothstep(0.1, 0.6, night))
	for beam: Node3D in _beams:
		beam.visible = night > 0.1
		beam.rotation.y = fposmod(_time / BEAM_TURN_S, 1.0) * TAU
