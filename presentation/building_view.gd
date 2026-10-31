class_name BuildingView
extends Node3D
## Prédios. Escuta o EventBus e só lê a simulação; nenhuma regra aqui.
## - Desde 16/10/2026 o prédio é um modelo montado com as peças do Kenney Fantasy Town Kit
##   (BuildingKit): fachadas com janelas e porta, telhado pela forma. Campo, pasto e píer, e tudo se
##   o kit faltar, continuam caixas (o que vem abaixo).
## - Casa: cor e altura da classe; refeita quando sobe de classe. Desde a Fase 8 cada casa tira,
##   pelo id, um de HOUSE_VARIANTS modelos (telhado de duas águas de frente ou de lado, ou telhado
##   plano com chaminé) e um tom da cor da classe: a rua deixa de ser fileira de caixas iguais.
## - Prédio parado: ícone do motivo flutuando em cima (sem estrada, sem entrada, saída cheia…);
##   o texto do motivo fica na dica do painel. Desde a Fase 7 é ícone, não texto. Desde a Fase 33 quem
##   aparece e com que opacidade é do StatusIconRule (longe, os iguais vizinhos viram um só).
## - Casa em protesto: ícone de protesto. Campo e pasto não têm ícone.
## - Silhueta por cadeia (Fase 13): pás do moinho, roda d'água e polia da torre de mina giram enquanto
##   o prédio produz, no tempo de jogo (param na pausa).
## - Desde a Fase 23 o modelo segue a forma: quando ela muda sem o prédio sair do lugar (o armazém que sobe
##   de nível ganha o alpendre e, no último, o tijolo), ele é refeito com andaime.
## - Obra e demolição (Fase 31): o prédio construído nasce achatado e sobe com squash & stretch, soltando poeira na
##   base; o demolido sai das contas na hora e afunda no chão com poeira antes de sumir. Direto com
##   SceneFader.is_instant() (testes); a animação é de interface e segue com o jogo pausado.

const DOOR_COLOR := Color(0.25, 0.18, 0.12)
## Tamanho do ícone na tela (Sprite3D de tamanho fixo).
const ICON_PIXEL_SIZE := 0.00028
const SELECTED_COLOR := Color(1.0, 0.85, 0.35, 0.35)
const REFRESH_SECONDS := 0.5
## A caixa desce abaixo do chão: a área pode ter até max_build_height_delta_m de desnível.
const FOUNDATION_M := 0.6
## Modelos placeholder de casa por classe, e quanto o tom da cor varia de uma casa para outra.
const HOUSE_VARIANTS := 3
const HOUSE_SHADE_STEPS := 5
const HOUSE_SHADE := 0.05
## Altura do telhado em fração da altura da casa (ele fica em cima: as janelas não mudam).
const ROOF_FRACTION := 0.35
const ROOF_DARKEN := 0.45
const SCAFFOLD_COLOR := Color(0.52, 0.4, 0.28)
## Só prédio a partir desta altura esconde o que está atrás (ocultador, Fase 9).
const OCCLUDER_MIN_HEIGHT_M := 5.0
## Obra (Fase 31): quanto dura o crescimento, de que altura (fração) ele parte e quanto passa do ponto; ao passar, o
## prédio afina em xz para manter o volume.
const BUILD_POP_S := 0.45
const BUILD_START_Y := 0.05
const BUILD_OVERSHOOT_Y := 1.12
const BUILD_OVERSHOOT_XZ := 0.94
## Demolição: quanto leva para afundar a altura do prédio e quantos afundam ao mesmo tempo (o resto some na hora).
const DEMOLISH_S := 0.9
const MAX_DEMOLISHING := 12
const DUST_COLOR := Color(0.72, 0.64, 0.52, 0.45)
## Prédios assentados (Fase 39), tudo pela variação do BuildingKit (o mesmo id, tipo e rotação dão sempre o mesmo):
## quatro paletas por tipo — a 0 é o tom de antes; as outras puxam a matiz, a saturação e o brilho da parede e trocam o
## telhado por outro do mesmo material —, a "invertida" (caixilho claro) numa casa de reboco ou tijolo a cada
## INVERTED_EVERY, e um desvio de até JITTER_M e JITTER_DEG no modelo. Proposta à espera do dono.
const PALETTES := 4
const WALL_SHIFTS: Array[Vector3] = [Vector3(0.0, 1.0, 1.0), Vector3(-0.03, 0.85, 0.93), Vector3(0.025, 1.12, 1.05),
		Vector3(0.05, 0.9, 0.97)]
const ROOF_TINTS := {
	BuildingMaterials.Roof.TILES: [Color(0.0, 0.0, 0.0, 0.0), Color(0.6, 0.28, 0.2), Color(0.45, 0.33, 0.27),
			Color(0.38, 0.4, 0.45)],
	BuildingMaterials.Roof.PLANKS: [Color(0.0, 0.0, 0.0, 0.0), Color(0.45, 0.35, 0.25), Color(0.36, 0.31, 0.25),
			Color(0.52, 0.44, 0.32)],
}
const NON_HOUSE_SHIFT := 0.35
const INVERTED_EVERY := 5
const JITTER_M := 0.01
const JITTER_DEG := 0.5
## Fase 134: os serviços de pedra com o telhado de ardósia (o shader do kit troca as telhas por ela).
const SLATE_ROOFS: Array[StringName] = [&"church", &"school", &"market", &"town_hall", &"theater", &"university",
		&"museum"]
## Fase 79: quanto o bicho inclina para a frente bebendo (rad).
const DRINK_TILT := 0.12

var _simulation: Simulation
var _cell_size: float
var _nodes: Dictionary[int, Node3D] = {}
var _labels: Dictionary[int, Sprite3D] = {}
## Texto (chave) do motivo mostrado em cada prédio: o ícone é o desenho dele.
var _label_keys: Dictionary[int, String] = {}
var _materials: Dictionary[String, StandardMaterial3D] = {}
var _door_material := StandardMaterial3D.new()
var _selection: MeshInstance3D
## Detalhes (telhado, chaminé, porta) e ocultadores: até onde aparecem, pelo nível gráfico (Fase 9).
var _detail_range_m: float = 260.0
var _occluders: bool = true
var _details: Array[GeometryInstance3D] = []
var _selected_id: int = 0
## Partes que giram (BuildingKit.Rotor), pelo prédio, e quanto giram por segundo de jogo.
var _rotors: Dictionary[int, Node3D] = {}
var _rotor_speeds: Dictionary[int, float] = {}
## Fase 73: as partes que balançam em vez de girar — [amplitude, fase] pelo prédio.
var _rotor_rocks: Dictionary[int, Array] = {}
## Fase 74: os bichos e as peças postos no zoológico e no museu (ExhibitModels), com cor por vértice — o mesmo jeito de
## material do trilho e do trem, sem pipeline nova.
var _exhibit_material := StandardMaterial3D.new()
## Fase 75: os bichos que andam no cercado, pelo prédio: [PenWalk, corpo, peça, escala] de cada um.
var _walkers: Dictionary[int, Array] = {}
## Chave da forma (BuildingKit.Spec.key) de cada prédio de modelo, para refazer quando ela muda.
var _spec_keys: Dictionary[int, String] = {}
var _refresh_left: float = 0.0
## Prédios demolidos que ainda estão afundando (já fora de _nodes).
var _demolishing: Array[Node3D] = []
## Fase 39: ilha e lote de cada prédio de modelo, para refazer a sombra de contato dos vizinhos quando um sai.
var _lots: Dictionary[int, Array] = {}
## Plintos dos prédios no barranco: [malha, lugar] por prédio, todos juntos numa malha só (um objeto e uma draw call em
## vez de um por prédio: separados, eram ~600 a mais no benchmark), refeita no quadro seguinte quando um muda.
var _plinths: Dictionary[int, Array] = {}
var _plinth_layer := MeshInstance3D.new()
var _plinths_queued: bool = false
## Fase 33: o prédio sob o cursor sempre mostra o ícone; com uma camada do mapa ligada, todos mostram.
var hovered_id: int = 0
var show_all_icons: bool = false
## Fase 47: o modo foto esconde todos os ícones de estado (eles são interface, não cidade).
var hide_icons: bool = false


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	_door_material.albedo_color = DOOR_COLOR
	_exhibit_material.vertex_color_use_as_albedo = true
	_exhibit_material.vertex_color_is_srgb = true
	_exhibit_material.roughness = 0.75
	_selection = MeshInstance3D.new()
	var selection_material := StandardMaterial3D.new()
	selection_material.albedo_color = SELECTED_COLOR
	selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_material.no_depth_test = true
	_selection.material_override = selection_material
	_selection.visible = false
	add_child(_selection)
	_plinth_layer.name = "Plinths"
	_plinth_layer.material_override = BuildingMaterials.kit()
	# sem a faixa de sujeira e musgo da base (a base varia de prédio para prédio; a malha é uma só)
	BuildingMaterials.dress_kit(_plinth_layer, BuildingMaterials.Wall.STONE, Color.WHITE, BuildingMaterials.Roof.TILES,
			Color.WHITE, -100.0)
	add_child(_plinth_layer)
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_removed.connect(_on_building_removed)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: refresh_labels())
	EventBus.building_state_changed.connect(_on_building_state_changed)
	EventBus.house_upgraded.connect(_on_house_upgraded)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for building_id: int in _nodes.keys():
		_remove(building_id)
	for node: Node3D in _demolishing:
		if is_instance_valid(node):
			node.queue_free()
	_demolishing.clear()
	for building_id: int in _simulation.world.building_ids():
		_add(building_id)
	refresh_labels()
	select(0)


func building_count() -> int:
	return _nodes.size()


## Prédios demolidos ainda afundando (testes).
func demolishing_count() -> int:
	_demolishing.assign(_demolishing.filter(func(node: Variant) -> bool: return is_instance_valid(node)))
	return _demolishing.size()


## Nó do prédio (testes).
func building_node(building_id: int) -> Node3D:
	return _nodes.get(building_id)


func label_text(building_id: int) -> String:
	return tr(_label_keys[building_id]) if _labels.has(building_id) and _labels[building_id].visible and _label_keys.has(building_id) else ""


## Nome do ícone mostrado sobre o prédio ("" = nenhum).
func label_icon(building_id: int) -> String:
	var key: String = _label_keys.get(building_id, "")
	return _icon_for(key) if _labels.has(building_id) and _labels[building_id].visible else ""


## Mantido da Fase 1: o prédio mostra algum alerta.
func has_alert(building_id: int) -> bool:
	return not label_text(building_id).is_empty()


func select(building_id: int) -> void:
	_selected_id = building_id
	var record := _simulation.world.building(building_id)
	_selection.visible = record != null
	if record == null:
		return
	var area := _area(record)
	var height := _height(record)
	var box := BoxMesh.new()
	box.size = Vector3(area.size.x * _cell_size + 0.4, height + 0.4, area.size.y * _cell_size + 0.4)
	_selection.mesh = box
	_selection.position = _grid(record).rect_world(area) + Vector3(0.0, height * 0.5, 0.0)


func _process(delta: float) -> void:
	spin_rotors(delta * GameClock.clock.speed_multiplier())
	walk_animals(delta * GameClock.clock.speed_multiplier())
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh_labels()
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		apply_icon_rule(to_local(camera.global_position))


## Mostra os ícones de estado pela regra da distância (StatusIconRule), com a câmera no referencial da vista.
func apply_icon_rule(camera_position: Vector3) -> void:
	var points: Dictionary[int, Vector3] = {}
	var keys: Dictionary[int, String] = {}
	for building_id: int in _label_keys:
		var key := _label_keys[building_id]
		if key.is_empty() or not _labels.has(building_id):
			continue
		points[building_id] = _nodes[building_id].position + _labels[building_id].position
		keys[building_id] = key
	var shown := StatusIconRule.alphas(points, keys, camera_position, _simulation.config, [hovered_id, _selected_id],
			show_all_icons)
	if hide_icons:
		shown.clear()
	for building_id: int in points:
		var label := _labels[building_id]
		label.visible = shown.has(building_id)
		label.modulate.a = shown.get(building_id, 1.0)


## Ícone de estado do prédio, se estiver aparecendo (testes).
func status_icon(building_id: int) -> Sprite3D:
	var label: Sprite3D = _labels.get(building_id)
	return label if label != null and label.visible else null


## Gira as partes dos prédios que estão produzindo por "game_seconds" segundos de jogo.
func spin_rotors(game_seconds: float) -> void:
	if game_seconds <= 0.0:
		return
	for building_id: int in _rotors:
		var record := _simulation.world.building(building_id)
		if record == null or record.state != BuildingRecord.State.PRODUCING or record.paused:
			continue
		if _rotor_rocks.has(building_id):
			# Fase 73: o balancim balança em volta do eixo (a fase anda; o ângulo é o seno dela)
			var rock: Array = _rotor_rocks[building_id]
			var phase: float = rock[1] + _rotor_speeds[building_id] * game_seconds
			rock[1] = phase
			var amplitude: float = rock[0]
			_rotors[building_id].basis = Basis(Vector3.RIGHT, sin(phase) * amplitude)
		else:
			_rotors[building_id].rotate_object_local(Vector3.RIGHT, _rotor_speeds[building_id] * game_seconds)


## Fase 75: os bichos andam no cercado por "game_seconds" segundos de jogo (parados com o jogo pausado).
func walk_animals(game_seconds: float) -> void:
	if game_seconds <= 0.0:
		return
	for building_id: int in _walkers:
		for entry: Array in _walkers[building_id]:
			var walk: PenWalk = entry[0]
			walk.advance(game_seconds)
			_place_walker(entry)


func _place_walker(entry: Array) -> void:
	var walk: PenWalk = entry[0]
	var body: Node3D = entry[1]
	var exhibit_id: StringName = entry[2]
	var fit: float = entry[3]
	var facing: float = ExhibitModels.FACING[exhibit_id]
	# o corpo olha para "heading" (desfeito o giro com que a malha foi feita); bebendo (Fase 79), inclina para a frente
	# em volta do eixo de lado do próprio bicho, com o pé no chão
	var tilt := -DRINK_TILT if walk.drinking else 0.0
	var turn := Basis(Vector3.UP, walk.heading) * Basis(Vector3.RIGHT, tilt) * Basis(Vector3.UP, -facing)
	body.transform = Transform3D(turn * Basis.from_scale(Vector3.ONE * fit), Vector3(walk.position.x, 0.0, walk.position.y))


## O passeio do bicho no cercado, ou null se ele não anda (testes).
func exhibit_walk(building_id: int, exhibit_id: StringName) -> PenWalk:
	for entry: Array in _walkers.get(building_id, []):
		if entry[2] == exhibit_id:
			return entry[0]
	return null


func rotor_count() -> int:
	return _rotors.size()


func _grid(record: BuildingRecord) -> IslandGrid:
	return _simulation.world.island(record.island_id)


func _area(record: BuildingRecord) -> Rect2i:
	return Footprint.rect(record.origin, _simulation.def_of(record).size, record.rotation)


func _height(record: BuildingRecord) -> float:
	return _simulation.data.tier(record.tier).house_height_m if record.is_house() else _simulation.def_of(record).height_m


func _color(record: BuildingRecord) -> Color:
	if not record.is_house():
		return _simulation.def_of(record).color
	var shade := (house_hash(record.id) / HOUSE_VARIANTS % HOUSE_SHADE_STEPS - HOUSE_SHADE_STEPS / 2) * HOUSE_SHADE
	var base := _simulation.data.tier(record.tier).house_color
	return base.lightened(shade) if shade >= 0.0 else base.darkened(-shade)


## Número estável sorteado pelo id da casa (o mesmo modelo depois de salvar e carregar).
static func house_hash(building_id: int) -> int:
	return absi(hash(building_id * 7919))


static func house_variant(building_id: int) -> int:
	return house_hash(building_id) % HOUSE_VARIANTS


## Fase 39: a paleta do prédio (0 a PALETTES - 1) pela variação.
static func palette_of(record: BuildingRecord) -> int:
	return BuildingKit.variation_hash(record) / 2187 % PALETTES


## O tom da parede na paleta: matiz, saturação e brilho puxados (no prédio que não é casa, só NON_HOUSE_SHIFT disso).
static func palette_wall(color: Color, palette: int, house: bool) -> Color:
	var shift := WALL_SHIFTS[palette]
	var amount := 1.0 if house else NON_HOUSE_SHIFT
	var result := Color.from_hsv(fposmod(color.h + shift.x * amount, 1.0), clampf(color.s * lerpf(1.0, shift.y, amount), 0.0, 1.0),
			clampf(color.v * lerpf(1.0, shift.z, amount), 0.0, 1.0), color.a)
	return result


## O tom do telhado na paleta: a 0 fica o de antes; as outras trocam pelo do material (só nas casas; o resto fica).
static func palette_roof(color: Color, roof_layer: int, palette: int, house: bool) -> Color:
	if not house or palette == 0 or not ROOF_TINTS.has(roof_layer):
		return color
	var tints: Array = ROOF_TINTS[roof_layer]
	var tint: Color = tints[palette]
	return tint


## A paleta "invertida": caixilho e madeiramento claros, numa casa de reboco ou tijolo a cada INVERTED_EVERY.
static func inverted(record: BuildingRecord, wall_layer: int) -> bool:
	return record.is_house() and wall_layer in [BuildingMaterials.Wall.PLASTER, BuildingMaterials.Wall.BRICK] \
			and BuildingKit.variation_hash(record) / 8748 % INVERTED_EVERY == 0


## Fase 130: o telhado de sapê — as casas da classe com o detalhe de quintal cercado (os camponeses).
static func thatched(simulation: Simulation, record: BuildingRecord) -> bool:
	if not record.is_house():
		return false
	var tier := simulation.data.tier(record.tier)
	return tier != null and tier.house_trim == TierDef.HouseTrim.YARD


## Sombra de contato (Fase 39): para cada fachada do referencial canônico (frente, +X, fundo, −X), a parte da divisa de
## fora dela ocupada por prédio de verdade (campo, píer e decoração não contam).
static func side_shade(simulation: Simulation, record: BuildingRecord) -> Vector4:
	var grid := simulation.world.island(record.island_id)
	var def := simulation.def_of(record)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var turn := Basis(Vector3.UP, -PI * 0.5 * posmod(record.rotation, 4))
	var result := Vector4.ZERO
	for face: int in 4:
		var normal := turn * BuildingKit.FACE_NORMALS[face]
		var step := Vector2i(roundi(normal.x), roundi(normal.z))
		var cells: Array[Vector2i] = []
		if step.x != 0:
			var x := area.end.x if step.x > 0 else area.position.x - 1
			for y: int in range(area.position.y, area.end.y):
				cells.append(Vector2i(x, y))
		else:
			var y := area.end.y if step.y > 0 else area.position.y - 1
			for x: int in range(area.position.x, area.end.x):
				cells.append(Vector2i(x, y))
		var touching := 0
		for cell: Vector2i in cells:
			var other := grid.building_at(cell)
			if other == 0 or other == record.id:
				continue
			var neighbor := simulation.world.building(other)
			if neighbor != null and simulation.def_of(neighbor).kind not in [BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER,
					BuildingDef.Kind.DECORATION]:
				touching += 1
		result[face] = float(touching) / maxi(cells.size(), 1)
	return result


## Plinto e degraus (Fase 39), só no lote em barranco: quando a pedra precisa descer mais que o alicerce do kit ou a
## porta fica alta sobre o chão da frente. No lugar do modelo (com o desvio e o giro dele), na malha comum.
func _add_plinth(body: MeshInstance3D, record: BuildingRecord, spec: BuildingKit.Spec, area: Rect2i) -> void:
	var grid := _grid(record)
	if grid.corner_heights.is_empty():
		return
	var seat := BuildingKit.seat(grid, area)
	var corners := BuildingKit.corner_range(grid, area)
	var depth := seat.y - corners.x + BuildingKit.PLINTH_BELOW_M
	var size := spec.size_m()
	var door := BuildingKit.door_position(spec)
	var front_z := (-size.y * 0.5 if spec.court_rows > 0 else door.z) - 0.45
	var outside := seat + Basis(Vector3.UP, -PI * 0.5 * posmod(record.rotation, 4)) * Vector3(door.x, 0.0, front_z)
	var drop := seat.y - grid.height_at(outside.x, outside.z)
	if spec.court_rows > 0 and spec.trim != TierDef.HouseTrim.YARD:
		# a varanda, as bancas e a plataforma de carga têm os degraus e as rampas delas
		drop = 0.0
	if depth <= BuildingKit.FOUNDATION_DOWN_M + 0.02 and BuildingKit.steps_for(drop) == 0:
		return
	_plinths[record.id] = [BuildingKit.plinth(spec, depth, drop), Transform3D(Basis(Vector3.UP, body.rotation.y),
			seat + body.position)]
	_queue_plinths()


## Plinto de um prédio, [malha, lugar], ou vazio (testes).
func plinth_of(building_id: int) -> Array:
	return _plinths.get(building_id, [])


func plinth_count() -> int:
	return _plinths.size()


func _queue_plinths() -> void:
	if not _plinths_queued:
		_plinths_queued = true
		rebuild_plinths.call_deferred()


## Junta os plintos numa malha só.
func rebuild_plinths() -> void:
	_plinths_queued = false
	if _plinths.is_empty():
		_plinth_layer.mesh = null
		return
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: Array in _plinths.values():
		var mesh: ArrayMesh = part[0]
		var place: Transform3D = part[1]
		tool.append_from(mesh, 0, place)
	_plinth_layer.mesh = tool.commit()


## Refaz a sombra de contato dos prédios de modelo em volta do lote (prédio novo ou demolido).
func _refresh_contacts(island_id: int, area: Rect2i, except_id: int) -> void:
	var grid := _simulation.world.island(island_id)
	var seen: Dictionary[int, bool] = {}
	var ring := area.grow(1)
	for y: int in range(ring.position.y, ring.end.y):
		for x: int in range(ring.position.x, ring.end.x):
			var other := grid.building_at(Vector2i(x, y))
			if other == 0 or other == except_id or seen.has(other) or not _lots.has(other):
				continue
			seen[other] = true
			var model := _nodes[other].get_node_or_null(^"Model") as MeshInstance3D
			if model != null:
				model.set_instance_shader_parameter(&"side_shade", side_shade(_simulation, _simulation.world.building(other)))


## Telhado da casa pelo modelo: duas águas com a cumeeira de lado a lado (0) ou de frente para
## trás (1), ou plano com chaminé (2).
func _add_roof(root: Node3D, record: BuildingRecord, body_size: Vector3, height: float) -> void:
	var variant := house_variant(record.id)
	var tier := _simulation.data.tier(record.tier)
	var roof_color := _color(record).darkened(ROOF_DARKEN)
	var top := height
	var roof := MeshInstance3D.new()
	roof.material_override = BuildingMaterials.roofs()
	BuildingMaterials.dress(roof, tier.roof_material, roof_color.lightened(0.35), root.position.y)
	_detail(roof)
	if variant == 2:
		var cap := BoxMesh.new()
		cap.size = Vector3(body_size.x + 0.3, 0.3, body_size.z + 0.3)
		roof.mesh = cap
		roof.position.y = top + 0.15
		var chimney := MeshInstance3D.new()
		var stack := BoxMesh.new()
		stack.size = Vector3(0.7, height * ROOF_FRACTION, 0.7)
		chimney.mesh = stack
		chimney.material_override = BuildingMaterials.walls()
		BuildingMaterials.dress(chimney, BuildingMaterials.Wall.BRICK, roof_color, root.position.y)
		_detail(chimney)
		chimney.position = Vector3(body_size.x * 0.25, top + height * ROOF_FRACTION * 0.5, -body_size.z * 0.2)
		root.add_child(chimney)
	else:
		var prism := PrismMesh.new()
		prism.size = Vector3(body_size.x + 0.4, height * ROOF_FRACTION, body_size.z + 0.4)
		roof.mesh = prism
		roof.position.y = top + height * ROOF_FRACTION * 0.5
		# o prisma do Godot tem a cumeeira ao longo de z; o modelo 0 a põe ao longo de x
		if variant == 0:
			prism.size = Vector3(body_size.z + 0.4, height * ROOF_FRACTION, body_size.x + 0.4)
			roof.rotation.y = PI * 0.5
	root.add_child(roof)


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	var def := _simulation.def_of(record)
	var area := _area(record)
	var height := _height(record)
	var root := Node3D.new()
	root.position = _grid(record).rect_world(area)
	var spec := BuildingKit.spec_for(_simulation, record, _cell_size)
	var body := MeshInstance3D.new()
	var soot: float = _simulation.derived_state().pollution.get(building_id, 0.0)
	var inset := 0.3 if def.kind != BuildingDef.Kind.MODULE else 0.15
	var box_size := Vector3(area.size.x * _cell_size - inset, height + FOUNDATION_M, area.size.y * _cell_size - inset)
	if spec != null:
		body.name = "Model"
		body.mesh = BuildingKit.mesh(spec)
		# Fase 39: o piso no canto mais alto do lote, com um desvio mínimo de posição e giro pela variação
		root.position = BuildingKit.seat(_grid(record), area)
		var pick := BuildingKit.variation_hash(record)
		body.position = Vector3(pick / 81 % 3 - 1, 0.0, pick / 243 % 3 - 1) * JITTER_M
		body.rotation.y = -PI * 0.5 * posmod(record.rotation, 4) + deg_to_rad(JITTER_DEG) * (pick / 729 % 3 - 1)
		body.material_override = BuildingMaterials.kit()
		var tier := _simulation.data.tier(record.tier) if record.is_house() else null
		var wall_layer := tier.wall_material if tier != null else def.wall_material
		var roof_layer: int = tier.roof_material if tier != null else (BuildingMaterials.Roof.PLANKS
				if def.wall_material == BuildingMaterials.Wall.WOOD else BuildingMaterials.Roof.TILES)
		if BuildingKit.brick(spec):
			wall_layer = BuildingMaterials.Wall.BRICK
			roof_layer = BuildingMaterials.Roof.TILES
		_spec_keys[building_id] = spec.key()
		var palette := palette_of(record)
		var color := palette_wall(_color(record), palette, record.is_house())
		var roof_color := palette_roof(color.darkened(ROOF_DARKEN).lightened(0.35), roof_layer, palette, record.is_house())
		BuildingMaterials.dress_kit(body, wall_layer, color, roof_layer, roof_color, root.position.y, soot)
		body.set_instance_shader_parameter(&"trim_paint", 1.0 if inverted(record, wall_layer) else 0.0)
		body.set_instance_shader_parameter(&"side_shade", side_shade(_simulation, record))
		# Fase 130: o telhado de sapê das casas dos camponeses
		body.set_instance_shader_parameter(&"thatch", 1.0 if thatched(_simulation, record) else 0.0)
		# Fase 134: o telhado de ardósia dos serviços de pedra
		body.set_instance_shader_parameter(&"slate", 1.0 if record.def_id in SLATE_ROOFS else 0.0)
		_lots[building_id] = [record.island_id, area]
		_add_plinth(body, record, spec, area)
		if def.is_exhibit_hall():
			_dress_exhibits(building_id, body, spec)
		var rotor := BuildingKit.rotor(spec)
		if rotor != null:
			var pivot := Node3D.new()
			pivot.name = "Rotor"
			pivot.transform = rotor.pivot
			var blades := MeshInstance3D.new()
			blades.mesh = rotor.mesh
			blades.material_override = BuildingMaterials.kit()
			BuildingMaterials.dress_kit(blades, wall_layer, color, roof_layer, roof_color, root.position.y, soot)
			_detail(blades)
			pivot.add_child(blades)
			body.add_child(pivot)
			_rotors[building_id] = pivot
			_rotor_speeds[building_id] = rotor.speed
			if rotor.rock > 0.0:
				_rotor_rocks[building_id] = [rotor.rock, 0.0]
		if _occluders and height >= OCCLUDER_MIN_HEIGHT_M:
			root.add_child(_occluder(box_size, Vector3(0.0, (height - FOUNDATION_M) * 0.5, 0.0)))
		root.add_child(body)
	else:
		var box := BoxMesh.new()
		box.size = box_size
		body.mesh = box
		body.position.y = (height - FOUNDATION_M) * 0.5
		if def.kind == BuildingDef.Kind.MODULE:
			body.material_override = _material_for(_color(record))
		else:
			body.material_override = BuildingMaterials.walls()
			var layer := _simulation.data.tier(record.tier).wall_material if record.is_house() else def.wall_material
			BuildingMaterials.dress(body, layer, _color(record), root.position.y, soot)
			if _occluders and height >= OCCLUDER_MIN_HEIGHT_M:
				root.add_child(_occluder(box.size, body.position))
		# o píer é o trapiche da HarborView (Fase 15), a decoração é da DecorationView (Fase 16) e o campo e o pasto são
		# da CropView (Fase 40: a terra lavrada com contorno, o capim do terreno): aqui fica só a etiqueta
		if def.kind not in [BuildingDef.Kind.PIER, BuildingDef.Kind.DECORATION, BuildingDef.Kind.MODULE]:
			root.add_child(body)
		else:
			body.free()
		if record.is_house():
			_add_roof(root, record, box.size, height)
	if def.kind != BuildingDef.Kind.MODULE:
		if spec == null and def.kind not in [BuildingDef.Kind.PIER, BuildingDef.Kind.DECORATION]:
			var door := _door(record, def, area)
			_detail(door)
			root.add_child(door)
		var label := Sprite3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size = true
		label.pixel_size = ICON_PIXEL_SIZE
		label.no_depth_test = true
		label.shaded = false
		label.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		label.render_priority = 10
		# alterna a altura entre vizinhos para as etiquetas não encostarem umas nas outras
		label.position.y = height + 2.0 + (building_id % 2) * 2.5
		label.visible = false
		root.add_child(label)
		_labels[building_id] = label
	add_child(root)
	_nodes[building_id] = root


## Nível gráfico: até onde os detalhes aparecem e se os prédios ocultam o que está atrás.
func set_quality(preset: GraphicsPresetDef) -> void:
	_detail_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	var occluders := preset.visibility_scale >= 0.75
	# Variant: na 4.8 um parâmetro tipado recusa o objeto já liberado (justo o que o filtro tira)
	_details.assign(_details.filter(func(node: Variant) -> bool: return is_instance_valid(node)))
	for node: GeometryInstance3D in _details:
		node.visibility_range_end = _detail_range_m
	if occluders != _occluders:
		_occluders = occluders
		rebuild()


func _detail(node: GeometryInstance3D) -> void:
	node.visibility_range_end = _detail_range_m
	node.visibility_range_end_margin = _detail_range_m * 0.1
	node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_details.append(node)


## Casa que acabou de subir de classe (Fase 9): andaime de madeira em volta e uma nuvem de poeira,
## que somem sozinhos depois de upgrade_scaffold_seconds.
func _scaffold(building_id: int) -> void:
	var root: Node3D = _nodes.get(building_id)
	if root == null:
		return
	var record := _simulation.world.building(building_id)
	var area := _area(record)
	var height := _height(record)
	var size := Vector3(area.size.x * _cell_size + 0.6, height + 1.0, area.size.y * _cell_size + 0.6)
	var frame := Node3D.new()
	frame.name = "Scaffold"
	var wood := _material_for(SCAFFOLD_COLOR)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		frame.add_child(_beam(Vector3(0.18, size.y, 0.18), Vector3(corner.x * size.x * 0.5, size.y * 0.5, corner.y * size.z * 0.5), wood))
	for level: float in [0.35, 0.7]:
		for side: int in 2:
			var along_x := side == 0
			var length := size.x if along_x else size.z
			for sign_value: float in [-1.0, 1.0]:
				var center := Vector3(0.0, size.y * level, sign_value * size.z * 0.5) if along_x \
						else Vector3(sign_value * size.x * 0.5, size.y * level, 0.0)
				frame.add_child(_beam(Vector3(length, 0.12, 0.12) if along_x else Vector3(0.12, 0.12, length), center, wood))
	var dust := _dust(size, 24, 2.5)
	frame.add_child(dust)
	root.add_child(frame)
	get_tree().create_timer(_simulation.config.upgrade_scaffold_seconds).timeout.connect(frame.queue_free)


## Fase 32 (WarmUp): o andaime e a poeira num prédio já desenhado, para o primeiro desenho deles cair atrás da cortina.
func show_scaffold(building_id: int) -> void:
	_scaffold(building_id)


## Nuvem de poeira de uma vez só, numa caixa do tamanho de "size" assentada no chão do prédio.
static func _dust(size: Vector3, amount: int, lifetime: float) -> GPUParticles3D:
	var dust := GPUParticles3D.new()
	dust.name = "Dust"
	dust.one_shot = true
	dust.amount = amount
	dust.lifetime = lifetime
	dust.explosiveness = 0.8
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = size * 0.5
	process.direction = Vector3.UP
	process.spread = 60.0
	process.initial_velocity_min = 0.5
	process.initial_velocity_max = 1.5
	process.gravity = Vector3(0.0, -0.3, 0.0)
	dust.process_material = process
	var puff := QuadMesh.new()
	puff.size = Vector2(2.0, 2.0)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_color = DUST_COLOR
	material.albedo_texture = SmokeView._puff_texture()
	puff.material = material
	dust.draw_pass_1 = puff
	dust.emitting = true
	return dust


## Obra (Fase 31): o prédio recém-construído nasce achatado, passa do ponto e assenta, com poeira na base.
func _pop(building_id: int) -> void:
	var root: Node3D = _nodes.get(building_id)
	if root == null or SceneFader.still():
		return
	var record := _simulation.world.building(building_id)
	var area := _area(record)
	var footprint := Vector3(area.size.x * _cell_size, 1.0, area.size.y * _cell_size)
	root.scale = Vector3(1.0, BUILD_START_Y, 1.0)
	var tween := root.create_tween()
	tween.tween_property(root, ^"scale", Vector3(BUILD_OVERSHOOT_XZ, BUILD_OVERSHOOT_Y, BUILD_OVERSHOOT_XZ),
			BUILD_POP_S * 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(root, ^"scale", Vector3.ONE, BUILD_POP_S * 0.4).set_ease(Tween.EASE_IN_OUT) \
			.set_trans(Tween.TRANS_SINE)
	var dust := _dust(footprint, 10, 1.4)
	add_child(dust)
	dust.global_position = root.global_position
	get_tree().create_timer(1.6).timeout.connect(dust.queue_free)


## Demolição (Fase 31): o nó, já fora das contas, afunda a altura dele com poeira e some. Sem o ocultador e sem o
## ícone. Com o teto cheio (ou nos testes), some na hora.
func _sink(root: Node3D, height: float, footprint: Vector3) -> void:
	_demolishing.assign(_demolishing.filter(func(node: Variant) -> bool: return is_instance_valid(node)))
	if SceneFader.still() or _demolishing.size() >= MAX_DEMOLISHING:
		root.queue_free()
		return
	for child: Node in root.get_children():
		if child is OccluderInstance3D or child is Sprite3D:
			child.queue_free()
	_demolishing.append(root)
	var dust := _dust(Vector3(footprint.x, height * 0.5, footprint.z), 28, 2.0)
	add_child(dust)
	dust.global_position = root.global_position + Vector3.UP * height * 0.25
	var tween := root.create_tween()
	tween.tween_property(root, ^"position:y", root.position.y - height - FOUNDATION_M, DEMOLISH_S) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(root, ^"scale", Vector3(1.04, 1.0, 1.04), DEMOLISH_S)
	tween.tween_callback(root.queue_free)
	tween.tween_callback(func() -> void: _demolishing.erase(root))
	get_tree().create_timer(2.4).timeout.connect(dust.queue_free)


static func _beam(size: Vector3, center: Vector3, material: Material) -> MeshInstance3D:
	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	beam.mesh = box
	beam.material_override = material
	beam.position = center
	return beam


static func _occluder(size: Vector3, center: Vector3) -> OccluderInstance3D:
	var occluder := OccluderInstance3D.new()
	var shape := BoxOccluder3D.new()
	# um pouco menor que a caixa: o ocultador nunca pode passar da parede
	shape.size = size * 0.92
	occluder.occluder = shape
	occluder.position = center
	return occluder


## Porta: bloco escuro encostado no meio da face de entrada.
func _door(record: BuildingRecord, def: BuildingDef, area: Rect2i) -> MeshInstance3D:
	var door := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.4, 2.4, 1.4)
	door.mesh = mesh
	door.material_override = _door_material
	var grid := _grid(record)
	var entrance := grid.cell_world(Footprint.entrance_cell(record.origin, def.size, record.rotation))
	var front := Footprint.front_direction(record.rotation)
	var center := grid.rect_world(area)
	door.position = Vector3(entrance.x - center.x, 1.2, entrance.z - center.z) - Vector3(front.x, 0.0, front.y) * (_cell_size * 0.5 + 0.3)
	return door


func _material_for(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		_materials[key] = material
	return _materials[key]


func _remove(building_id: int, sink: bool = false) -> void:
	if _nodes.has(building_id):
		if sink:
			var root := _nodes[building_id]
			var aabb := Vector3(4.0, 4.0, 4.0)
			var body := root.get_node_or_null(^"Model") as MeshInstance3D
			if body == null:
				for child: Node in root.get_children():
					if child is MeshInstance3D:
						body = child
						break
			if body != null and body.mesh != null:
				aabb = body.mesh.get_aabb().size
			_sink(root, aabb.y, aabb)
		else:
			_nodes[building_id].queue_free()
		_nodes.erase(building_id)
		_labels.erase(building_id)
		_label_keys.erase(building_id)
		_rotors.erase(building_id)
		_rotor_speeds.erase(building_id)
		_rotor_rocks.erase(building_id)
		_walkers.erase(building_id)
		_spec_keys.erase(building_id)
		_lots.erase(building_id)
		if _plinths.erase(building_id):
			_queue_plinths()


func refresh_labels() -> void:
	for building_id: int in _labels:
		_refresh_label(building_id)


## Produção mostra o estado quando parada; casa e serviço mostram só a falta de estrada.
## Texto curto do motivo (dica e testes); o ícone sai de _icon_for.
static func label_key(state: BuildingRecord.State) -> String:
	match state:
		BuildingRecord.State.NO_INPUT:
			return "LABEL_NO_INPUT"
		BuildingRecord.State.NO_WORKERS:
			return "LABEL_NO_WORKERS"
		BuildingRecord.State.OUTPUT_FULL:
			return "LABEL_OUTPUT_FULL"
		BuildingRecord.State.NO_ROAD:
			return "LABEL_NO_ROAD"
		BuildingRecord.State.NO_MODULES:
			return "LABEL_NO_MODULES"
		BuildingRecord.State.PAUSED:
			return "LABEL_PAUSED"
		BuildingRecord.State.NO_WAREHOUSE:
			return "LABEL_NO_WAREHOUSE"
		BuildingRecord.State.NO_TREES:
			return "LABEL_NO_TREES"
	return ""


func _refresh_label(building_id: int) -> void:
	if not _labels.has(building_id):
		return
	var label := _labels[building_id]
	var record := _simulation.world.building(building_id)
	var key := ""
	if record.is_house() and record.happiness < _simulation.config.protest_happiness_threshold and record.residents > 0.0:
		key = "LABEL_PROTEST"
	elif not _simulation.has_road_access(building_id):
		key = "LABEL_NO_ROAD"
	elif _simulation.def_of(record).is_warehouse() and not _simulation.derived_state().warehouse_connected.get(building_id, false):
		key = "LABEL_DISCONNECTED"
	elif _simulation.def_of(record).is_production():
		var state := SelectionPanel.shown_state(record)
		if state not in [BuildingRecord.State.PRODUCING, BuildingRecord.State.IDLE]:
			key = label_key(state)
	if key != _label_keys.get(building_id, ""):
		_label_keys[building_id] = key
		if not key.is_empty():
			var icon := Icons.get_icon(_icon_for(key)) as AtlasTexture
			# Sprite3D desenha o atlas inteiro de uma AtlasTexture: usa a região
			label.texture = icon.atlas
			label.region_enabled = true
			label.region_rect = icon.region
	# quem aparece é do apply_icon_rule (no quadro seguinte); aqui só some o que perdeu o motivo
	if key.is_empty():
		label.visible = false


## Ícone do motivo: LABEL_NO_ROAD → state_no_road.
static func _icon_for(key: String) -> String:
	return "state_" + key.trim_prefix("LABEL_").to_lower() if not key.is_empty() else ""


func _on_building_placed(building_id: int) -> void:
	_add(building_id)
	_refresh_label(building_id)
	_pop(building_id)
	var record := _simulation.world.building(building_id)
	_refresh_contacts(record.island_id, _area(record), building_id)


func _on_building_removed(building_id: int) -> void:
	var lot: Array = _lots.get(building_id, [])
	_remove(building_id, true)
	if not lot.is_empty():
		var island_id: int = lot[0]
		var area: Rect2i = lot[1]
		_refresh_contacts(island_id, area, building_id)
	if building_id == _selected_id:
		select(0)


func _on_building_state_changed(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record != null and _spec_keys.has(building_id) and not record.is_house():
		var spec := BuildingKit.spec_for(_simulation, record, _cell_size)
		if spec != null and spec.key() != _spec_keys[building_id]:
			_remove(building_id)
			_add(building_id)
			_scaffold(building_id)
			if building_id == _selected_id:
				select(building_id)
		elif spec != null and _simulation.def_of(record).is_exhibit_hall():
			# Fase 74: peça posta no prédio (a forma não muda): só os bichos e as peças são refeitos
			var body := _nodes[building_id].get_node_or_null(^"Model") as Node3D
			if body != null:
				_dress_exhibits(building_id, body, spec)
	_refresh_label(building_id)


## Fase 74: os bichos nos cercados do zoológico e as peças nos pedestais do museu, na ordem do catálogo, como filhos do
## modelo (seguem o giro dele); refeitos quando uma peça entra. Cada vaga é um nó no meio dela com o corpo ("Body")
## dentro; no cercado, o corpo do bicho que anda é posto pelo PenWalk (Fase 75), que segue o mesmo quando outra peça entra.
func _dress_exhibits(building_id: int, body: Node3D, spec: BuildingKit.Spec) -> void:
	var old := body.get_node_or_null(^"Exhibits")
	if old != null:
		body.remove_child(old)
		old.queue_free()
	var old_walks: Dictionary[StringName, PenWalk] = {}
	for entry: Array in _walkers.get(building_id, []):
		old_walks[entry[2]] = entry[0]
	_walkers.erase(building_id)
	var spots := BuildingKit.exhibit_spots(spec)
	var shown := _simulation.world.exhibits_state.in_building(building_id, _simulation.data)
	if spots.is_empty() or shown.is_empty():
		return
	var group := Node3D.new()
	group.name = "Exhibits"
	var walkers: Array[Array] = []
	for k: int in mini(spots.size(), shown.size()):
		var exhibit_id := shown[k].id
		var item := Node3D.new()
		item.name = String(exhibit_id)
		item.position = spots[k]
		var shape := MeshInstance3D.new()
		shape.name = "Body"
		shape.mesh = ExhibitModels.mesh(exhibit_id)
		shape.material_override = _exhibit_material
		shape.visibility_range_end = _detail_range_m
		item.add_child(shape)
		group.add_child(item)
		var half := BuildingKit.pen_half(spec)
		if spec.silhouette == BuildingDef.Silhouette.MENAGERIE:
			# Fase 77: o chão do bicho e o bebedouro no cercado ocupado
			var pen := MeshInstance3D.new()
			pen.name = "Pen"
			pen.mesh = ExhibitModels.pen_dressing(exhibit_id, half)
			pen.material_override = _exhibit_material
			pen.visibility_range_end = _detail_range_m
			item.add_child(pen)
		if spec.silhouette == BuildingDef.Silhouette.MENAGERIE and ExhibitModels.roams(exhibit_id):
			# o bicho grande demais para virar no cercado fica menor (PenWalk.fit_scale)
			var footprint := ExhibitModels.footprint(exhibit_id)
			var fit := PenWalk.fit_scale(half, footprint)
			shape.scale = Vector3.ONE * fit
			var walk: PenWalk = old_walks.get(exhibit_id)
			if walk == null:
				walk = PenWalk.new(half, Rect2(footprint.position * fit, footprint.size * fit),
						hash([building_id, k, exhibit_id]), ExhibitModels.FACING[exhibit_id], ExhibitModels.trough_rect(half))
			var entry: Array = [walk, shape, exhibit_id, fit]
			_place_walker(entry)
			walkers.append(entry)
	body.add_child(group)
	if not walkers.is_empty():
		_walkers[building_id] = walkers


## Os bichos e as peças à mostra no prédio (testes).
func exhibit_nodes(building_id: int) -> Array[Node3D]:
	var found: Array[Node3D] = []
	var root: Node3D = _nodes.get(building_id)
	if root == null:
		return found
	var group := root.get_node_or_null(^"Model/Exhibits")
	if group != null:
		for child: Node in group.get_children():
			found.append(child as Node3D)
	return found


func _on_house_upgraded(building_id: int) -> void:
	_remove(building_id)
	_add(building_id)
	_scaffold(building_id)
	_refresh_label(building_id)
	if building_id == _selected_id:
		select(building_id)
