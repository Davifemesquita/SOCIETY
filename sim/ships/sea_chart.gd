class_name SeaChart
extends RefCounted
## Carta náutica do arquipélago (seção 6): uma grade de sea_chart_cell_m sobre as ilhas e o mar
## em volta, em que a célula é navegável se o fundo dela inteira fica abaixo de ship_min_depth_m.
## Rios (braços de mar rasos) e a ilha plana de antes ficam fora. O caminho do navio sai de um
## AStarGrid2D com diagonais e é encurtado por linha de visada. Feita uma vez por mundo: o
## terreno não muda depois de gerado. Fora do save.
## O caminho novo entre portos distantes passa de 20 ms: request() o calcula no WorkerThreadPool
## (seção 12) e route() devolve o resultado, esperando a tarefa só se ela ainda não acabou. O A*
## só é usado pelas tarefas, uma de cada vez (mutex); o cache é protegido por outro.

var origin_m: Vector2
var cell_m: float
var size: Vector2i
## 1 = navegável, por célula (y * largura + x).
var navigable := PackedByteArray()

var _astar := AStarGrid2D.new()
var _cache: Dictionary[int, PackedVector2Array] = {}
## Tarefa do WorkerThreadPool de cada caminho pedido e ainda não recolhido.
var _pending: Dictionary[int, int] = {}
var _cache_lock := Mutex.new()
var _astar_lock := Mutex.new()


func _init(world: WorldState, config: GameConfig) -> void:
	cell_m = config.sea_chart_cell_m
	var bounds := Rect2()
	for grid: IslandGrid in world.islands:
		bounds = grid.world_rect() if bounds.size == Vector2.ZERO else bounds.merge(grid.world_rect())
	bounds = bounds.grow(config.sea_margin_m)
	origin_m = (bounds.position / cell_m).floor() * cell_m
	size = Vector2i(((bounds.end - origin_m) / cell_m).ceil())
	navigable.resize(size.x * size.y)
	navigable.fill(1)
	for grid: IslandGrid in world.islands:
		_chart_island(grid, config.ship_min_depth_m)
	_astar.region = Rect2i(Vector2i.ZERO, size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_astar.update()
	for i: int in navigable.size():
		if navigable[i] == 0:
			_astar.set_point_solid(Vector2i(i % size.x, i / size.x), true)


## Marca como fechadas as células da carta com algum canto da ilha acima da profundidade mínima.
## A ilha plana é toda terra.
func _chart_island(grid: IslandGrid, min_depth: float) -> void:
	var rect := grid.world_rect()
	var first := cell_of(rect.position)
	var last := cell_of(rect.end - Vector2(0.001, 0.001))
	for cy: int in range(maxi(first.y, 0), mini(last.y, size.y - 1) + 1):
		for cx: int in range(maxi(first.x, 0), mini(last.x, size.x - 1) + 1):
			if grid.corner_heights.is_empty() or _highest_corner(grid, Vector2i(cx, cy)) >= min_depth:
				navigable[cy * size.x + cx] = 0


func _highest_corner(grid: IslandGrid, chart_cell: Vector2i) -> float:
	var low := origin_m + Vector2(chart_cell) * cell_m
	var x0 := clampi(floori((low.x - grid.origin_m.x) / grid.cell_size), 0, grid.size.x)
	var z0 := clampi(floori((low.y - grid.origin_m.y) / grid.cell_size), 0, grid.size.y)
	var x1 := clampi(ceili((low.x + cell_m - grid.origin_m.x) / grid.cell_size), 0, grid.size.x)
	var z1 := clampi(ceili((low.y + cell_m - grid.origin_m.y) / grid.cell_size), 0, grid.size.y)
	var highest := -INF
	var width := grid.size.x + 1
	for z: int in range(z0, z1 + 1):
		for x: int in range(x0, x1 + 1):
			highest = maxf(highest, grid.corner_heights[z * width + x])
	return highest


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(((point - origin_m) / cell_m).floor())


func center_of(cell: Vector2i) -> Vector2:
	return origin_m + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_m


func is_navigable(cell: Vector2i) -> bool:
	return in_bounds(cell) and navigable[cell.y * size.x + cell.x] == 1


## Célula navegável mais perto do ponto (anéis quadrados em volta), ou (-1, -1) se não houver até
## max_m.
func nearest_navigable(point: Vector2, max_m: float = INF) -> Vector2i:
	var center := cell_of(point)
	var max_ring := maxi(size.x, size.y) if is_inf(max_m) else mini(ceili(max_m / cell_m), maxi(size.x, size.y))
	var best := Vector2i(-1, -1)
	var best_gap := INF
	for ring: int in max_ring + 1:
		# um anel mais longe só pode ter algo mais perto se o melhor ainda estiver além dele
		if best.x >= 0 and (ring - 1) * cell_m > best_gap:
			break
		for cell: Vector2i in _ring(center, ring):
			if is_navigable(cell):
				var gap := center_of(cell).distance_to(point)
				if gap < best_gap and gap <= max_m:
					best = cell
					best_gap = gap
	return best


## Começa a calcular, em outra thread, o caminho de from até to (se ainda não está pronto nem
## pedido).
func request(from: Vector2, to: Vector2) -> void:
	var ends := _ends(from, to)
	if ends.is_empty():
		return
	var start: Vector2i = ends[0]
	var goal: Vector2i = ends[1]
	var key := _key(start, goal)
	_cache_lock.lock()
	_reap()
	var known := _cache.has(key) or _pending.has(key)
	if not known:
		_pending[key] = WorkerThreadPool.add_task(_compute.bind(key, start, goal), false, "caminho no mar")
	_cache_lock.unlock()


## Pontos do caminho de from até to (sem o ponto de partida; o último é o centro da célula de
## destino), ou vazio se não há caminho por mar. Pede e espera o cálculo se preciso.
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var ends := _ends(from, to)
	if ends.is_empty():
		return PackedVector2Array()
	request(from, to)
	var key := _key(ends[0], ends[1])
	_cache_lock.lock()
	var task: int = _pending.get(key, -1)
	_cache_lock.unlock()
	if task >= 0:
		WorkerThreadPool.wait_for_task_completion(task)
		_cache_lock.lock()
		_pending.erase(key)
		_cache_lock.unlock()
	_cache_lock.lock()
	var points: PackedVector2Array = _cache[key]
	_cache_lock.unlock()
	return points


## Espera as tarefas em andamento (antes de a carta sair de uso).
func finish() -> void:
	_cache_lock.lock()
	var tasks := _pending.values()
	_pending.clear()
	_cache_lock.unlock()
	for task: int in tasks:
		WorkerThreadPool.wait_for_task_completion(task)


## Recolhe as tarefas já acabadas que ninguém esperou (toda tarefa do WorkerThreadPool precisa
## de wait_for_task_completion). Chamado com o _cache_lock travado.
func _reap() -> void:
	for key: int in _pending.keys():
		var task: int = _pending[key]
		if WorkerThreadPool.is_task_completed(task):
			WorkerThreadPool.wait_for_task_completion(task)
			_pending.erase(key)


## Células de partida e de chegada (a navegável mais perto, se o ponto cai em terra), ou vazio.
func _ends(from: Vector2, to: Vector2) -> Array[Vector2i]:
	var start := cell_of(from) if is_navigable(cell_of(from)) else nearest_navigable(from)
	var goal := cell_of(to) if is_navigable(cell_of(to)) else nearest_navigable(to)
	if start.x < 0 or goal.x < 0:
		return []
	return [start, goal]


## Roda numa thread do WorkerThreadPool: só lê a carta e usa o A* com o mutex dele.
func _compute(key: int, start: Vector2i, goal: Vector2i) -> void:
	var points := PackedVector2Array([center_of(goal)])
	if start != goal:
		_astar_lock.lock()
		var cells := _astar.get_id_path(start, goal)
		_astar_lock.unlock()
		points = _shorten(cells)
	_cache_lock.lock()
	_cache[key] = points
	_cache_lock.unlock()


func _key(start: Vector2i, goal: Vector2i) -> int:
	return (start.y * size.x + start.x) * navigable.size() + goal.y * size.x + goal.x


## Tira os pontos intermediários que a linha reta dispensa (o navio corta direto no mar aberto).
func _shorten(cells: Array[Vector2i]) -> PackedVector2Array:
	var points := PackedVector2Array()
	if cells.is_empty():
		return points
	var anchor := 0
	while anchor < cells.size() - 1:
		var reach := anchor + 1
		for candidate: int in range(cells.size() - 1, anchor + 1, -1):
			if clear_line(cells[anchor], cells[candidate]):
				reach = candidate
				break
		points.append(center_of(cells[reach]))
		anchor = reach
	return points


## A reta entre os centros de duas células passa só por células navegáveis (amostras a cada
## quarto de célula).
func clear_line(a: Vector2i, b: Vector2i) -> bool:
	var from := Vector2(a) + Vector2(0.5, 0.5)
	var to := Vector2(b) + Vector2(0.5, 0.5)
	var steps := maxi(1, ceili(from.distance_to(to) * 4.0))
	for step: int in steps + 1:
		var cell := Vector2i(from.lerp(to, float(step) / steps).floor())
		if not is_navigable(cell):
			return false
	return true


static func _ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	if radius == 0:
		return [center]
	var cells: Array[Vector2i] = []
	for x: int in range(center.x - radius, center.x + radius + 1):
		cells.append(Vector2i(x, center.y - radius))
		cells.append(Vector2i(x, center.y + radius))
	for y: int in range(center.y - radius + 1, center.y + radius):
		cells.append(Vector2i(center.x - radius, y))
		cells.append(Vector2i(center.x + radius, y))
	return cells
