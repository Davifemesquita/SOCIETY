class_name DuckView
extends Node3D
## Fase 196: os patos na água. Numa rede de pontos de GROUP_STEP células, com a chance GROUP_CHANCE, a célula de água (mar ou
## rio) mais perto do ponto que encosta numa terra baixa (LOW_M) e tem o fundo raso (SHALLOW_M) vira um bando nadando em roda
## na água calma da costa: o meio da roda sai da costa até a roda toda passar sobre fundo de RING_FLOOR_M e a LAND_CLEAR_M de
## qualquer terra, onde a espuma da linha d'água já não pinta a água (`candidates`, feitos uma vez por mundo), e o bando fica
## só se estiver a HARBOR_CELLS ou mais do entreposto, do píer, da cabana de pesca e do estaleiro (`flocks`). Metade dos bandos
## é a pata na frente e os patinhos em fila atrás; a outra, patos e patas juntos. Cada um vai na roda no tempo de jogo,
## balançando na água, e os grandes mergulham a cabeça de tempos em tempos com o rabo para cima (`pose`, `dabble`). Três
## malhas (pato, pata e patinho, a pata menor) em dois MultiMesh; somem à noite; nada no save; o filtro dos portos é refeito
## na obra e na demolição, e tudo ao trocar de mundo.

enum Duck { DRAKE, HEN, DUCKLING }

const GROUP_STEP := 11
const GROUP_CHANCE := 0.35
const LOW_M := 2.2
## O fundo da água dos patos: abaixo do mais raso, para não sentarem na areia, e acima do mais fundo (água calma da costa).
const SHALLOW_M := Vector2(-3.0, -0.35)
const HARBOR_CELLS := 8
const HARBORS: Array[StringName] = [&"trading_post", &"pier", &"fishery", &"shipyard"]
const RADIUS_M := Vector2(1.8, 3.4)
## O primeiro afastamento tentado entre a beira e a roda: menos que isso a roda nunca fica longe o bastante da terra.
const SHORE_GAP_M := 4.0
## A roda toda passa sobre fundo pelo menos tão fundo quanto este (longe da espuma da beira).
const RING_FLOOR_M := -1.5
## E a pelo menos isto de qualquer terra; o meio da roda sai da costa até MAX_OUT_M, de OUT_STEP_M em OUT_STEP_M.
const LAND_CLEAR_M := 5.0
const MAX_OUT_M := 14.0
const OUT_STEP_M := 1.0
const RING_SAMPLES := 10
const SWIM_M_S := 0.32
const GAP_M := 0.86
const DUCKLING_GAP_M := 0.44
const DUCKLING_SCALE := 0.48
const DUCKLINGS := Vector2i(3, 6)
const ADULTS := Vector2i(2, 5)
const DABBLE_RAD := 0.95
## Em volta de onde o pato gira ao mergulhar a cabeça (o peito) e quanto ele afunda.
const DABBLE_PIVOT := Vector3(0.0, 0.05, -0.12)
const DABBLE_SINK_M := 0.05
const DABBLE_EVERY_S := Vector2(7.0, 15.0)
const BOB_M := 0.012
## Os patos um pouco maiores que de verdade, para se verem da câmera do jogo.
const SIZE := 1.35
const WATER_Y := 0.0
## Até quanto da noite (DayClock.night_factor) eles aparecem.
const HIDE_AT := 0.5
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DRAKE_BODY := Color(0.6, 0.58, 0.54)
const DRAKE_BACK := Color(0.42, 0.38, 0.33)
const CHESTNUT := Color(0.42, 0.22, 0.13)
const GREEN := Color(0.06, 0.3, 0.16)
const WHITE := Color(0.92, 0.92, 0.9)
const BLACK := Color(0.07, 0.07, 0.07)
const BILL := Color(0.86, 0.74, 0.2)
const HEN_BODY := Color(0.5, 0.38, 0.24)
const HEN_DARK := Color(0.33, 0.24, 0.15)
const HEN_BILL := Color(0.62, 0.42, 0.18)
const SALT := 196


## Um bando: o meio da roda (na água), o raio, o sentido (1 anti-horário visto de cima, −1 o outro), onde a frente começa e
## cada pato da fila (o tipo e a semente).
class Flock:
	extends RefCounted
	var center := Vector3.ZERO
	## A célula do meio da roda (o meio dela, em células), para medir a distância dos portos.
	var cell := Vector2.ZERO
	var radius := 2.0
	var turn := 1.0
	var start := 0.0
	var kinds: Array[int] = []
	var seeds := PackedInt32Array()


var _simulation: Simulation
var _layers: Array[MultiMeshInstance3D] = []
## Os bandos e cada pato: [bando, posição na fila, camada, índice na camada] (testes).
var flocks_now: Array[Flock] = []
var _ducks: Array[Array] = []
## Os bandos que o terreno permite, por ilha, e o mundo deles.
var _candidates: Array[Array] = []
var _candidates_world: WorldState
var _time := 0.0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.6
	for pair: Array in [["Drakes", drake_mesh()], ["Hens", hen_mesh()]]:
		var layer := MultiMeshInstance3D.new()
		var label: String = pair[0]
		var mesh: ArrayMesh = pair[1]
		layer.name = label
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = mesh
		layer.multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.material_override = material
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(layer)
		_layers.append(layer)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func duck_count() -> int:
	return _ducks.size()


func _mark(_id: int) -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()
	var night := DayClock.night_factor(_simulation.config, GameClock.clock.hour())
	visible = night < HIDE_AT
	advance(delta * GameClock.clock.speed_multiplier())


func rebuild() -> void:
	_dirty = false
	flocks_now.clear()
	_ducks.clear()
	var counts: Array[int] = [0, 0]
	var world := _simulation.world
	if _candidates_world != world:
		_candidates_world = world
		_candidates.clear()
		for island_id: int in world.islands.size():
			_candidates.append(candidates(world.island(island_id), island_id))
	for island_id: int in world.islands.size():
		var found: Array[Flock] = []
		found.assign(_candidates[island_id])
		for flock: Flock in away_from_harbors(found, harbors_of(world, _simulation.data, island_id)):
			flocks_now.append(flock)
			for k: int in flock.kinds.size():
				var layer := 0 if flock.kinds[k] == Duck.DRAKE else 1
				_ducks.append([flock, k, layer, counts[layer]])
				counts[layer] += 1
	for layer: int in _layers.size():
		_layers[layer].multimesh.instance_count = counts[layer]
	advance(0.0)


## Anda o relógio dos patos seconds de jogo e põe cada um no lugar da vez.
func advance(seconds: float) -> void:
	_time += seconds
	for duck: Array in _ducks:
		var flock: Flock = duck[0]
		var k: int = duck[1]
		var layer: int = duck[2]
		var index: int = duck[3]
		_layers[layer].multimesh.set_instance_transform(index, pose(flock, k, _time))


## Os bandos da ilha, longe dos portos. Vazio na ilha plana.
static func flocks(world: WorldState, data: GameData, island_id: int) -> Array[Flock]:
	var grid := world.island(island_id)
	if grid == null or grid.flat:
		var none: Array[Flock] = []
		return none
	return away_from_harbors(candidates(grid, island_id), harbors_of(world, data, island_id))


## O meio (em células) de cada prédio de porto da ilha (HARBORS).
static func harbors_of(world: WorldState, data: GameData, island_id: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for id: int in world.buildings:
		var record := world.building(id)
		if record.island_id == island_id and record.def_id in HARBORS:
			var def := data.building(record.def_id)
			var area := Footprint.rect(record.origin, def.size, record.rotation)
			result.append(Vector2(area.position) + Vector2(area.size) * 0.5)
	return result


## Os bandos cujo meio da roda fica a HARBOR_CELLS ou mais de todo porto.
static func away_from_harbors(found: Array[Flock], harbors: Array[Vector2]) -> Array[Flock]:
	var result: Array[Flock] = []
	for flock: Flock in found:
		var near := false
		for harbor: Vector2 in harbors:
			if harbor.distance_to(flock.cell) < HARBOR_CELLS:
				near = true
				break
		if not near:
			result.append(flock)
	return result


## Os bandos que o terreno da ilha permite, sem olhar os prédios: feitos uma vez por mundo (a busca é a parte cara).
static func candidates(grid: IslandGrid, island_id: int) -> Array[Flock]:
	var result: Array[Flock] = []
	if grid == null or grid.flat:
		return result
	var reach := floori(GROUP_STEP / 2.0)
	var memo: Dictionary[int, bool] = {}
	for y: int in range(reach, grid.size.y - 1, GROUP_STEP):
		for x: int in range(reach, grid.size.x - 1, GROUP_STEP):
			var pick := FireflyView.cell_hash(island_id, x, y, SALT)
			if float(pick % 1000) / 1000.0 >= GROUP_CHANCE or not _mixed(grid, x, y, reach):
				continue
			var shore := _nearest_shallows(grid, x, y, reach)
			if shore.is_empty():
				continue
			var best: Vector2i = shore[0]
			var best_land: Vector2i = shore[1]
			var flock := _flock(grid, island_id, best, best_land, pick, memo)
			if flock != null:
				result.append(flock)
	return result


## Se o quadrado de lado 2 reach + 1 em volta da célula (x, y) tem terra e água nos nove pontos de prova (quinas, meios dos
## lados e o meio): todo terra (o meio da ilha) ou todo água (o mar aberto) não tem beira que preste e não é varrido.
static func _mixed(grid: IslandGrid, x: int, y: int, reach: int) -> bool:
	var land := 0
	for dy: int in [-reach, 0, reach]:
		for dx: int in [-reach, 0, reach]:
			if grid.ground_at(Vector2i(x + dx, y + dy)) == IslandGrid.Ground.LAND:
				land += 1
	return land > 0 and land < 9


## A água da beira mais perto da célula (x, y), a até reach células pelos lados: [célula, lado da terra], ou vazio. Anda em
## anéis de distância crescente e para no primeiro achado; a água sem terra ao lado sai pela leitura direta da grade, sem
## chamar `_shallows` (é o que pesa: quase toda célula da varredura é terra, mar aberto ou falésia).
static func _nearest_shallows(grid: IslandGrid, x: int, y: int, reach: int) -> Array:
	var width := grid.size.x
	var ground := grid.ground
	var land_kind := IslandGrid.Ground.LAND
	for d: int in 2 * reach + 1:
		for dx: int in range(-mini(d, reach), mini(d, reach) + 1):
			var rest := d - absi(dx)
			if rest > reach:
				continue
			for s: int in (1 if rest == 0 else 2):
				var cx := x + dx
				var cy := y + (rest if s == 1 else -rest)
				if cx < 1 or cy < 1 or cx >= width - 1 or cy >= grid.size.y - 1:
					continue
				var i := cy * width + cx
				if ground[i] == land_kind or (ground[i - 1] != land_kind and ground[i + 1] != land_kind \
						and ground[i - width] != land_kind and ground[i + width] != land_kind):
					continue
				var land := _shallows(grid, Vector2i(cx, cy))
				if land != Vector2i.ZERO:
					return [Vector2i(cx, cy), land]
	return []


## A água da beira: mar ou rio de fundo raso encostado (pelo lado) numa terra baixa. Devolve o lado da terra, ou zero.
static func _shallows(grid: IslandGrid, cell: Vector2i) -> Vector2i:
	if cell.x < 1 or cell.y < 1 or cell.x >= grid.size.x - 1 or cell.y >= grid.size.y - 1:
		return Vector2i.ZERO
	var index := grid.index(cell)
	if grid.ground[index] == IslandGrid.Ground.LAND:
		return Vector2i.ZERO
	# primeiro a terra do lado (só ler a grade: quase toda a água fica longe dela), depois o fundo
	var land := Vector2i.ZERO
	for side: Vector2i in SIDES:
		if grid.ground[index + side.y * grid.size.x + side.x] == IslandGrid.Ground.LAND:
			var corners := BuildingKit.corner_range(grid, Rect2i(cell + side, Vector2i.ONE))
			if corners.y <= LOW_M:
				land = side
				break
	if land == Vector2i.ZERO:
		return land
	var middle := grid.cell_world(cell)
	var floor_m := grid.height_at(middle.x, middle.z)
	if floor_m < SHALLOW_M.x or floor_m > SHALLOW_M.y:
		return Vector2i.ZERO
	return land


## O bando da água cell (land: o lado da terra): a roda sai da costa de metro em metro (até MAX_OUT_M) até ficar toda sobre a
## água funda o bastante e longe da terra; sem caber, encolhe uma vez e tenta de novo; sem caber ainda, nenhum.
static func _flock(grid: IslandGrid, island_id: int, cell: Vector2i, land: Vector2i, pick: int,
		memo: Dictionary[int, bool]) -> Flock:
	var away := -Vector3(land.x, 0.0, land.y)
	# o primeiro ponto da roda conferido é o virado para a terra (o que mais falha)
	var toward_land := atan2(float(land.y), float(land.x))
	for radius: float in [lerpf(RADIUS_M.x, RADIUS_M.y, float((pick >> 10) % 100) / 99.0), RADIUS_M.x]:
		var out := SHORE_GAP_M
		while out <= MAX_OUT_M:
			var center := grid.cell_world(cell) + away * (radius + out - grid.cell_size * 0.5)
			center.y = WATER_Y
			if ring_in_water(grid, center, radius, memo, toward_land):
				var flock := Flock.new()
				flock.center = center
				flock.cell = Vector2(grid.world_to_cell(center)) + Vector2(0.5, 0.5)
				flock.radius = radius
				flock.turn = 1.0 if (pick >> 3) % 2 == 0 else -1.0
				flock.start = float((pick >> 5) % 360) / 360.0 * TAU
				if (pick >> 13) % 2 == 0:
					flock.kinds.append(Duck.HEN)
					var young := DUCKLINGS.x + (pick >> 15) % (DUCKLINGS.y - DUCKLINGS.x + 1)
					for k: int in young:
						flock.kinds.append(Duck.DUCKLING)
				else:
					var adults := ADULTS.x + (pick >> 15) % (ADULTS.y - ADULTS.x + 1)
					for k: int in adults:
						flock.kinds.append(Duck.DRAKE if (pick >> (18 + k)) % 2 == 0 else Duck.HEN)
				for k: int in flock.kinds.size():
					flock.seeds.append(FireflyView.cell_hash(island_id, cell.x * 8 + k, cell.y, SALT + 1))
				return flock
			out += OUT_STEP_M
	return null


## Se a roda de raio radius em volta de center fica toda sobre a água funda o bastante (RING_FLOOR_M) e longe de qualquer terra
## (perto da costa a espuma da linha d'água pinta a água de branco). memo guarda a resposta de cada célula entre as tentativas.
static func ring_in_water(grid: IslandGrid, center: Vector3, radius: float, memo: Dictionary[int, bool] = {},
		first_angle: float = 0.0) -> bool:
	for k: int in RING_SAMPLES:
		var angle := first_angle + TAU * k / RING_SAMPLES
		var point := center + Vector3(cos(angle), 0.0, sin(angle)) * radius
		var cell := grid.world_to_cell(point)
		if not grid.in_bounds(cell) or grid.ground[grid.index(cell)] == IslandGrid.Ground.LAND:
			return false
		if not clear_cell(grid, cell, memo) or grid.height_at(point.x, point.z) > RING_FLOOR_M:
			return false
	return true


## Se nenhuma célula de terra fica a até LAND_CLEAR_M / cell_size células (pela maior das duas distâncias) da célula: do ponto
## na célula até a terra ficam pelo menos LAND_CLEAR_M menos meia célula.
static func clear_cell(grid: IslandGrid, cell: Vector2i, memo: Dictionary[int, bool]) -> bool:
	var index := grid.index(cell)
	if memo.has(index):
		return memo[index]
	var reach := ceili(LAND_CLEAR_M / grid.cell_size)
	var clear := true
	for y: int in range(maxi(cell.y - reach, 0), mini(cell.y + reach + 1, grid.size.y)):
		var row := y * grid.size.x
		for x: int in range(maxi(cell.x - reach, 0), mini(cell.x + reach + 1, grid.size.x)):
			if grid.ground[row + x] == IslandGrid.Ground.LAND:
				clear = false
				break
		if not clear:
			break
	memo[index] = clear
	return clear


## O que a fila andou até o pato k (m): a pata ou o primeiro na frente, os patinhos mais juntos atrás.
static func gap_of(flock: Flock, k: int) -> float:
	var total := 0.0
	for i: int in range(1, k + 1):
		total += DUCKLING_GAP_M if flock.kinds[i] == Duck.DUCKLING else GAP_M
	return total


## O lugar do pato k do bando no instante time: na roda, com a frente (−z) para onde nada, boiando, e o grande mergulhando a
## cabeça de vez em quando.
static func pose(flock: Flock, k: int, time: float) -> Transform3D:
	var angle := flock.start + flock.turn * (SWIM_M_S * time - gap_of(flock, k)) / flock.radius
	var point := flock.center + Vector3(cos(angle), 0.0, sin(angle)) * flock.radius
	var motion := Vector3(-sin(angle), 0.0, cos(angle)) * flock.turn
	var seed_value := flock.seeds[k]
	point.y = WATER_Y + BOB_M * sin(time * 2.1 + float(seed_value % 97) * 0.37)
	var place := Transform3D(Basis.looking_at(motion, Vector3.UP), point)
	if flock.kinds[k] == Duck.DUCKLING:
		return place * Transform3D(Basis.from_scale(Vector3.ONE * DUCKLING_SCALE * SIZE), Vector3.ZERO)
	# o grande gira em volta do peito, afundando um pouco com a cabeça na água
	var down := dabble(seed_value, time)
	var tip := Transform3D(Basis(Vector3.RIGHT, -down), Vector3(0.0, -DABBLE_SINK_M * down / DABBLE_RAD, 0.0))
	var pivot := Transform3D(Basis.IDENTITY, DABBLE_PIVOT * SIZE)
	return place * pivot * tip * pivot.affine_inverse() * Transform3D(Basis.from_scale(Vector3.ONE * SIZE), Vector3.ZERO)


## Quanto o pato de semente seed está de cabeça para baixo no instante time (rad): quase sempre nada, uma vez por volta
## mergulha a cabeça e volta, cada um com a sua duração.
static func dabble(seed_value: int, time: float) -> float:
	var span := lerpf(DABBLE_EVERY_S.x, DABBLE_EVERY_S.y, float(seed_value % 89) / 88.0)
	var phase := fposmod(time / span + float(seed_value % 23) / 23.0, 1.0)
	return DABBLE_RAD * smoothstep(0.7, 0.76, phase) * (1.0 - smoothstep(0.88, 0.94, phase))


## O pato (macho) com a linha d'água no zero e o bico para −z: corpo cinza, peito castanho, dorso mais escuro, o rabo preto
## com a pena virada, o pescoço e a cabeça verdes com o colar branco e o bico amarelo.
static func drake_mesh() -> ArrayMesh:
	return _duck_mesh(DRAKE_BODY, DRAKE_BACK, CHESTNUT, GREEN, GREEN, BILL, true)


## A pata (e o patinho, encolhido): toda parda, mais escura no dorso, o bico alaranjado.
static func hen_mesh() -> ArrayMesh:
	return _duck_mesh(HEN_BODY, HEN_DARK, HEN_BODY, HEN_BODY, HEN_DARK, HEN_BILL, false)


static func _duck_mesh(body: Color, back: Color, chest: Color, neck: Color, head: Color, bill: Color, drake: bool) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blob := func(scale: Vector3, at: Vector3, color: Color) -> void:
		PerchedGullView._blob(tool, Transform3D(Basis.from_scale(scale), at), color)
	blob.call(Vector3(0.13, 0.085, 0.25), Vector3(0.0, 0.045, 0.02), body)
	blob.call(Vector3(0.11, 0.05, 0.2), Vector3(0.0, 0.1, 0.05), back)
	blob.call(Vector3(0.105, 0.08, 0.1), Vector3(0.0, 0.07, -0.15), chest)
	blob.call(Vector3(0.055, 0.04, 0.08), Vector3(0.0, 0.09, 0.25), BLACK if drake else back)
	blob.call(Vector3(0.042, 0.07, 0.045), Vector3(0.0, 0.17, -0.2), neck)
	if drake:
		blob.call(Vector3(0.047, 0.014, 0.047), Vector3(0.0, 0.135, -0.195), WHITE)
		# a pena do rabo virada para cima
		blob.call(Vector3(0.012, 0.03, 0.012), Vector3(0.0, 0.15, 0.3), BLACK)
	blob.call(Vector3(0.058, 0.052, 0.072), Vector3(0.0, 0.245, -0.23), head)
	blob.call(Vector3(0.03, 0.012, 0.05), Vector3(0.0, 0.232, -0.305), bill)
	for side: float in [-1.0, 1.0]:
		blob.call(Vector3(0.008, 0.008, 0.008), Vector3(side * 0.048, 0.26, -0.255), BLACK)
	tool.generate_normals()
	return tool.commit()
