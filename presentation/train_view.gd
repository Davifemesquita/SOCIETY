class_name TrainView
extends Node3D
## Trem na tela (Fase 71): em cada ligação por trilho (DerivedState.rail_feeds), uma locomotiva com um vagão-tanque vai
## e volta pelo caminho mais curto do trilho (RailNetwork.route) entre o poço e a usina: espera carregando no poço, anda
## até a usina, espera descarregando e volta de ré, com a locomotiva sempre virada para a usina. Gerados no código (sem
## asset), com o mesmo material do trilho (nenhuma pipeline nova). O relógio de cada trem anda no tempo de jogo (para na
## pausa) e para quando o poço ou a usina estão parados. Só apresentação: o petróleo continua indo na hora pela
## simulação (RailSystem); nada aqui lê ou muda o que a simulação decide.

## Comprimentos (m) da locomotiva, do vagão e do vão entre os dois; velocidade (m/s de jogo) e a espera em cada ponta (s).
const LOCO_M := 5.2
const WAGON_M := 4.4
const GAP_M := 0.5
const SPEED_M_S := 5.0
const DWELL_S := 4.0
## Altura do topo da barra acima do chão do trilho (RailView: dormente + barra) e raio da roda.
const RAIL_TOP_M := 0.2
const WHEEL_R := 0.35
const BODY_COLOR := Color(0.16, 0.3, 0.22)
const BOILER_COLOR := Color(0.1, 0.1, 0.11)
const FRAME_COLOR := Color(0.45, 0.12, 0.1)
const TANK_COLOR := Color(0.12, 0.12, 0.13)
const ROOF_COLOR := Color(0.2, 0.2, 0.22)
const VISIBLE_UNTIL_M := 700.0


class Train:
	var sender_id: int
	var receiver_id: int
	var cells: Array[Vector2i] = []
	var points: PackedVector3Array = PackedVector3Array()
	## distância acumulada até cada ponto
	var along: PackedFloat32Array = PackedFloat32Array()
	var clock: float = 0.0
	var loco: MeshInstance3D
	var wagon: MeshInstance3D

	func length() -> float:
		return along[along.size() - 1] if not along.is_empty() else 0.0


var _simulation: Simulation
var _config: GameConfig
var _material := StandardMaterial3D.new()
var _loco_mesh: Mesh
var _wagon_mesh: Mesh
var _trains: Array[Train] = []
var _stale := true


func setup(simulation: Simulation, config: GameConfig) -> void:
	_simulation = simulation
	_config = config
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 0.75
	_loco_mesh = loco_mesh()
	_wagon_mesh = wagon_mesh()
	var mark := func(_id: int) -> void: _stale = true
	EventBus.rails_changed.connect(mark)
	EventBus.building_placed.connect(mark)
	EventBus.building_removed.connect(mark)
	EventBus.world_replaced.connect(func() -> void: _stale = true)
	refresh()


## Refaz os trens a partir das ligações de agora (chamado no quadro seguinte a qualquer mudança; testes chamam à mão).
func refresh() -> void:
	_stale = false
	var old: Dictionary[Vector2i, float] = {}
	for train: Train in _trains:
		old[Vector2i(train.sender_id, train.receiver_id)] = train.clock
		train.loco.queue_free()
		train.wagon.queue_free()
	_trains.clear()
	var world := _simulation.world
	var feeds := _simulation.derived_state().rail_feeds
	for receiver_id: int in feeds:
		var receiver := world.building(receiver_id)
		if receiver == null:
			continue
		var grid := world.island(receiver.island_id)
		var receiver_def := _simulation.data.building(receiver.def_id)
		var senders: Array = feeds[receiver_id]
		for sender: DerivedState.ProductionEntry in senders:
			var cells := RailNetwork.route(grid, sender.record, sender.def, receiver, receiver_def)
			if cells.is_empty():
				continue
			var train := Train.new()
			train.sender_id = sender.record.id
			train.receiver_id = receiver_id
			train.cells = cells
			_trace(train, grid)
			# o trem que já existia segue de onde estava; o novo começa esperando no poço
			var resume: float = old.get(Vector2i(train.sender_id, receiver_id), 0.0)
			train.clock = resume
			train.loco = _body("Loco", _loco_mesh)
			train.wagon = _body("Wagon", _wagon_mesh)
			_trains.append(train)
	_place()


func train_count() -> int:
	return _trains.size()


func train_cells(index: int) -> Array[Vector2i]:
	return _trains[index].cells


func loco_transform(index: int) -> Transform3D:
	return _trains[index].loco.transform


func wagon_transform(index: int) -> Transform3D:
	return _trains[index].wagon.transform


## Anda o relógio à mão (testes e capturas com o jogo pausado).
func advance(seconds: float) -> void:
	_tick(seconds)


func _process(delta: float) -> void:
	if _stale:
		refresh()
	_tick(delta * GameClock.clock.speed_multiplier())


func _tick(seconds: float) -> void:
	for train: Train in _trains:
		if _running(train):
			train.clock += seconds
	_place()


## O trem para quando o poço ou a usina estão parados (pausados pelo jogador ou sumidos).
func _running(train: Train) -> bool:
	for id: int in [train.sender_id, train.receiver_id]:
		var record := _simulation.world.building(id)
		if record == null or record.paused:
			return false
	return true


## Onde a frente da locomotiva está (m pelo caminho, a partir do poço) no relógio dado: espera no poço com o trem
## inteiro no trilho, vai até a usina, espera e volta de ré. Caminho mais curto que o trem: fica parado.
static func head_at(length: float, clock: float) -> float:
	var train_m := LOCO_M + GAP_M + WAGON_M
	var travel := length - train_m
	if travel <= 0.0:
		return minf(train_m, length)
	var run_s := travel / SPEED_M_S
	var t := fposmod(clock, 2.0 * (run_s + DWELL_S))
	if t < DWELL_S:
		return train_m
	t -= DWELL_S
	if t < run_s:
		return train_m + t * SPEED_M_S
	t -= run_s
	if t < DWELL_S:
		return length
	t -= DWELL_S
	return length - t * SPEED_M_S


func _place() -> void:
	for train: Train in _trains:
		var head := head_at(train.length(), train.clock)
		train.loco.transform = _pose(train, head, head - LOCO_M)
		var back := head - LOCO_M - GAP_M
		train.wagon.transform = _pose(train, back, back - WAGON_M)


## O corpo entre a frente e a traseira (m pelo caminho): no meio dos dois, com a frente (-Z) para a frente.
func _pose(train: Train, front_m: float, back_m: float) -> Transform3D:
	var front := _point(train, front_m)
	var back := _point(train, back_m)
	var forward := front - back
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	return Transform3D(Basis.looking_at(forward.normalized(), Vector3.UP), (front + back) * 0.5)


func _point(train: Train, at_m: float) -> Vector3:
	var count := train.points.size()
	if count == 1:
		return train.points[0]
	var at := clampf(at_m, 0.0, train.length())
	for k: int in range(1, count):
		if at <= train.along[k] or k == count - 1:
			var span := train.along[k] - train.along[k - 1]
			var weight := (at - train.along[k - 1]) / span if span > 0.0 else 0.0
			return train.points[k - 1].lerp(train.points[k], weight)
	return train.points[count - 1]


## Os pontos do caminho no chão: o lado do lote do poço, o meio de cada célula e o lado do lote da usina (a primeira e a
## última célula encostam nos lotes, então o caminho vai de borda a borda).
func _trace(train: Train, grid: IslandGrid) -> void:
	var flat: Array[Vector3] = []
	for cell: Vector2i in train.cells:
		flat.append(grid.cell_world(cell))
	if flat.size() >= 2:
		flat.push_front(flat[0] + (flat[0] - flat[1]) * 0.5)
		flat.append(flat[flat.size() - 1] + (flat[flat.size() - 1] - flat[flat.size() - 2]) * 0.5)
	var total := 0.0
	for k: int in flat.size():
		var point := RailView.ground_point(grid, _config, flat[k])
		if k > 0:
			total += point.distance_to(train.points[k - 1])
		train.points.append(point)
		train.along.append(total)


func _body(label: String, mesh: Mesh) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = _material
	node.visibility_range_end = VISIBLE_UNTIL_M
	add_child(node)
	return node


## A locomotiva a vapor (frente em -Z, origem no chão do trilho no meio do corpo): estrado com três pares de rodas, a
## caldeira deitada com a chaminé, a cabine atrás com o teto.
static func loco_mesh() -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LOCO_M * 0.5
	var deck := RAIL_TOP_M + WHEEL_R * 1.4
	_wheels(tool, half, 3)
	_box(tool, Vector3(0.0, deck, 0.0), Vector3(0.75, 0.15, half), FRAME_COLOR)
	_cylinder(tool, Vector3(0.0, deck + 0.75, -half), Vector3(0.0, deck + 0.75, 0.6), 0.6, BOILER_COLOR)
	_cylinder(tool, Vector3(0.0, deck + 1.2, -half + 0.8), Vector3(0.0, deck + 2.1, -half + 0.8), 0.2, BOILER_COLOR)
	_box(tool, Vector3(0.0, deck + 0.95, half - 0.9), Vector3(0.8, 0.8, 0.9), BODY_COLOR)
	_box(tool, Vector3(0.0, deck + 1.82, half - 0.9), Vector3(0.9, 0.07, 1.05), ROOF_COLOR)
	tool.generate_normals()
	return tool.commit()


## O vagão-tanque: estrado com dois pares de rodas e o tanque deitado.
static func wagon_mesh() -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WAGON_M * 0.5
	var deck := RAIL_TOP_M + WHEEL_R * 1.4
	_wheels(tool, half, 2)
	_box(tool, Vector3(0.0, deck, 0.0), Vector3(0.75, 0.12, half), FRAME_COLOR)
	_cylinder(tool, Vector3(0.0, deck + 0.85, -half + 0.2), Vector3(0.0, deck + 0.85, half - 0.2), 0.72, TANK_COLOR)
	_box(tool, Vector3(0.0, deck + 1.62, 0.0), Vector3(0.2, 0.1, 0.2), TANK_COLOR)
	tool.generate_normals()
	return tool.commit()


## Pares de rodas espalhados pelo comprimento (meia medida half), em cima da barra (bitola do RailView).
static func _wheels(tool: SurfaceTool, half: float, pairs: int) -> void:
	for k: int in pairs:
		var z := lerpf(-half * 0.7, half * 0.7, float(k) / maxi(1, pairs - 1))
		for side: float in [-1.0, 1.0]:
			var x := side * RailView.GAUGE_M * 0.5
			var center := Vector3(x, RAIL_TOP_M + WHEEL_R, z)
			_cylinder(tool, center - Vector3(0.06, 0.0, 0.0), center + Vector3(0.06, 0.0, 0.0), WHEEL_R, BOILER_COLOR)


## Caixa centrada em center com meias medidas half (sem rotação).
static func _box(tool: SurfaceTool, center: Vector3, half: Vector3, color: Color) -> void:
	var c: Array[Vector3] = []
	for k: int in 8:
		c.append(center + Vector3(half.x * (1 if k & 1 else -1), half.y * (1 if k & 2 else -1), half.z * (1 if k & 4 else -1)))
	# faces com os cantos em volta, de fora (sentido horário visto de fora, como o Godot espera)
	for face: Array in [[2, 3, 7, 6], [0, 4, 5, 1], [1, 5, 7, 3], [0, 2, 6, 4], [4, 6, 7, 5], [0, 1, 3, 2]]:
		_quad(tool, c[face[0]], c[face[1]], c[face[2]], c[face[3]], color)


## Cilindro de a até b com raio radius, com as tampas.
static func _cylinder(tool: SurfaceTool, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var axis := (b - a).normalized()
	var helper := Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var u := axis.cross(helper).normalized() * radius
	var v := axis.cross(u).normalized() * radius
	var sides := 10
	for i: int in sides:
		var p := u * cos(TAU * i / sides) + v * sin(TAU * i / sides)
		var q := u * cos(TAU * (i + 1) / sides) + v * sin(TAU * (i + 1) / sides)
		_quad(tool, a + p, b + p, b + q, a + q, color)
		_tri(tool, a, a + p, a + q, color)
		_tri(tool, b, b + q, b + p, color)


static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	_tri(tool, a, b, c, color)
	_tri(tool, a, c, d, color)


static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for point: Vector3 in [a, b, c]:
		tool.set_color(color)
		tool.add_vertex(point)
