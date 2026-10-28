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
## Fase 76: a fumaça da chaminé (a mesma da fumaça das fábricas, SmokeView, tipo SMOKE): partículas no nível mais alto,
## quanto sai andando e parado na ponta (amount_ratio), quanto dura cada baforada e até onde aparece.
const PUFFS := 24
const PUFFS_MOVING := 1.0
const PUFFS_WAITING := 0.4
const PUFF_LIFETIME_S := 3.5
const SMOKE_UNTIL_M := 450.0


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
	## Fase 76: a fumaça da chaminé (filha da locomotiva; null no nível sem partículas)
	var smoke: GPUParticles3D

	func length() -> float:
		return along[along.size() - 1] if not along.is_empty() else 0.0


var _simulation: Simulation
var _config: GameConfig
var _material := StandardMaterial3D.new()
var _loco_mesh: Mesh
var _wagon_mesh: Mesh
var _trains: Array[Train] = []
var _stale := true
## Fase 76: a fumaça (o material de processo é de todos os trens e deita no vento), a fração de partículas e o alcance
## pelo nível gráfico.
var _smoke_process: ParticleProcessMaterial
var _smoke_draw: QuadMesh
var _particles_ratio: float = 1.0
var _smoke_range_m: float = SMOKE_UNTIL_M
## De onde vem o vento; sem ele, a fumaça sobe reta.
var weather: WeatherView


func setup(simulation: Simulation, config: GameConfig) -> void:
	_simulation = simulation
	_config = config
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 0.75
	_loco_mesh = loco_mesh()
	_wagon_mesh = wagon_mesh()
	_smoke_process = SmokeView._process_material(BuildingDef.Smoke.SMOKE)
	_smoke_draw = SmokeView._draw_mesh(BuildingDef.Smoke.SMOKE)
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
			train.smoke = _chimney_smoke(train.loco)
			_trains.append(train)
	_place()


## Pelo nível gráfico (GraphicsQuality): quantas partículas e até onde a fumaça aparece; refaz os trens.
func set_quality(preset: GraphicsPresetDef) -> void:
	_particles_ratio = preset.particles_ratio
	_smoke_range_m = SMOKE_UNTIL_M * preset.visibility_scale
	refresh()


## A fumaça em cima da chaminé, solta no mundo (local_coords desligado): a baforada fica para trás quando o trem anda.
func _chimney_smoke(loco: Node3D) -> GPUParticles3D:
	var amount := roundi(PUFFS * _particles_ratio)
	if amount <= 0:
		return null
	var plume := GPUParticles3D.new()
	plume.name = "Smoke"
	plume.amount = amount
	plume.lifetime = PUFF_LIFETIME_S
	plume.local_coords = false
	plume.process_material = _smoke_process
	plume.draw_pass_1 = _smoke_draw
	plume.position = chimney_top()
	plume.visibility_aabb = AABB(Vector3(-15, -3, -15), Vector3(30, 30, 30))
	plume.visibility_range_end = _smoke_range_m
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plume.emitting = false
	loco.add_child(plume)
	return plume


## A boca da chaminé no referencial da locomotiva (a chaminé do loco_mesh).
static func chimney_top() -> Vector3:
	var deck := RAIL_TOP_M + WHEEL_R * 1.4
	return Vector3(0.0, deck + 2.2, -LOCO_M * 0.5 + 0.8)


## Se o trem anda no relógio dado (fora das esperas nas pontas e com caminho maior que ele).
static func moving_at(length: float, clock: float) -> bool:
	return not is_equal_approx(head_at(length, clock), head_at(length, clock + 0.05))


## A fumaça do trem (testes): null sem partículas.
func smoke_of(index: int) -> GPUParticles3D:
	return _trains[index].smoke


## Para onde a fumaça dos trens deita (testes).
func smoke_push() -> Vector3:
	return _smoke_process.gravity


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
		var running := _running(train)
		if running:
			train.clock += seconds
		if train.smoke != null:
			# Fase 76: baforada forte andando, fraca esperando na ponta, nada com o trem parado ou o jogo pausado
			train.smoke.emitting = running and seconds > 0.0
			train.smoke.amount_ratio = PUFFS_MOVING if moving_at(train.length(), train.clock) else PUFFS_WAITING
	if weather != null:
		_smoke_process.gravity = SmokeView.drift(weather.sample.wind_direction, weather.sample.wind)
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
	VertexShapes.box(tool, Vector3(0.0, deck, 0.0), Vector3(0.75, 0.15, half), FRAME_COLOR)
	VertexShapes.cylinder(tool, Vector3(0.0, deck + 0.75, -half), Vector3(0.0, deck + 0.75, 0.6), 0.6, BOILER_COLOR)
	VertexShapes.cylinder(tool, Vector3(0.0, deck + 1.2, -half + 0.8), Vector3(0.0, deck + 2.1, -half + 0.8), 0.2, BOILER_COLOR)
	VertexShapes.box(tool, Vector3(0.0, deck + 0.95, half - 0.9), Vector3(0.8, 0.8, 0.9), BODY_COLOR)
	VertexShapes.box(tool, Vector3(0.0, deck + 1.82, half - 0.9), Vector3(0.9, 0.07, 1.05), ROOF_COLOR)
	tool.generate_normals()
	return tool.commit()


## O vagão-tanque: estrado com dois pares de rodas e o tanque deitado.
static func wagon_mesh() -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := WAGON_M * 0.5
	var deck := RAIL_TOP_M + WHEEL_R * 1.4
	_wheels(tool, half, 2)
	VertexShapes.box(tool, Vector3(0.0, deck, 0.0), Vector3(0.75, 0.12, half), FRAME_COLOR)
	VertexShapes.cylinder(tool, Vector3(0.0, deck + 0.85, -half + 0.2), Vector3(0.0, deck + 0.85, half - 0.2), 0.72, TANK_COLOR)
	VertexShapes.box(tool, Vector3(0.0, deck + 1.62, 0.0), Vector3(0.2, 0.1, 0.2), TANK_COLOR)
	tool.generate_normals()
	return tool.commit()


## Pares de rodas espalhados pelo comprimento (meia medida half), em cima da barra (bitola do RailView).
static func _wheels(tool: SurfaceTool, half: float, pairs: int) -> void:
	for k: int in pairs:
		var z := lerpf(-half * 0.7, half * 0.7, float(k) / maxi(1, pairs - 1))
		for side: float in [-1.0, 1.0]:
			var x := side * RailView.GAUGE_M * 0.5
			var center := Vector3(x, RAIL_TOP_M + WHEEL_R, z)
			VertexShapes.cylinder(tool, center - Vector3(0.06, 0.0, 0.0), center + Vector3(0.06, 0.0, 0.0), WHEEL_R, BOILER_COLOR)
