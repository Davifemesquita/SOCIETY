class_name RoadRouter
extends RefCounted
## Rotas pela estrada de uma ilha: um AStarGrid2D em que só as células de estrada são
## passáveis (seção 6). Feito de novo quando a rede muda; as rotas pedidas ficam em cache.
## A estrada de paralelepípedo (Fase 8) entra com peso menor na mesma grade. Desde a Fase 17 a carroça anda
## na diagonal pura (RoadNetwork.linked_diagonal), e só nela: cortar o canto de uma esquina em L sai caro demais.

## Custo de um passo diagonal que não é diagonal pura: o A* nunca o escolhe se houver outro caminho, e o
## caminho que sobra (sem saída) é descartado em path().
const BLOCKED_COST := 1.0e6
const SQRT2 := 1.41421356

var _grid: IslandGrid
var _astar := DiagonalGrid.new()
var _cache: Dictionary[int, PackedInt32Array] = {}


## Peso da célula de terra no A* (a de paralelepípedo pesa 1): o tempo relativo de passar por ela.
## A terra é que pesa mais, e não o paralelepípedo menos, para a heurística (1 por célula de lado, √2
## na diagonal) nunca passar do custo real: senão o A* devolve o caminho de terra mesmo com um calçado
## mais rápido ao lado.
var dirt_weight: float = 1.5


func _init(grid: IslandGrid, paved_speed_bonus: float = 0.5) -> void:
	dirt_weight = 1.0 + paved_speed_bonus
	_grid = grid
	_astar.region = Rect2i(Vector2i.ZERO, grid.size)
	_astar.grid = grid
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	# octil: a diagonal custa √2; com a terra pesando mais, a estimativa continua abaixo do custo real
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	_astar.fill_solid_region(_astar.region, true)
	# ilha só de terra: tudo pesa 1 (a heurística fica justa e a busca, curta)
	var mixed := grid.roads.has(IslandGrid.Road.PAVED)
	for i: int in grid.roads.size():
		if grid.roads[i] != IslandGrid.Road.NONE:
			_astar.set_point_solid(grid.cell_at(i), false)
			if mixed and grid.roads[i] == IslandGrid.Road.DIRT:
				_astar.set_point_weight_scale(grid.cell_at(i), dirt_weight)


## Índices das células de from até to (as duas inclusive), ou vazio se não há caminho.
func path(from: int, to: int) -> PackedInt32Array:
	var key := from * _grid.roads.size() + to
	if _cache.has(key):
		return _cache[key]
	var cells := PackedInt32Array()
	if _grid.roads[from] != IslandGrid.Road.NONE and _grid.roads[to] != IslandGrid.Road.NONE:
		var previous := Vector2i(-1, -1)
		for cell: Vector2i in _astar.get_id_path(_grid.cell_at(from), _grid.cell_at(to)):
			if previous.x >= 0 and absi(cell.x - previous.x) + absi(cell.y - previous.y) == 2 \
					and not RoadNetwork.linked_diagonal(_grid, previous, cell):
				cells.clear()
				break
			cells.append(_grid.index(cell))
			previous = cell
	_cache[key] = cells
	return cells


## Comprimento do passo de a para b do caminho, em células: 1 de lado, √2 na diagonal.
static func step_length(grid: IslandGrid, a: int, b: int) -> float:
	var width := grid.size.x
	return SQRT2 if absi(a % width - b % width) == 1 and absi(a / width - b / width) == 1 else 1.0



## A grade do A* com a diagonal só onde ela é pura: o passo pelo canto de uma esquina em L ou entre
## duas estradas que não se ligam custa BLOCKED_COST.
class DiagonalGrid:
	extends AStarGrid2D

	var grid: IslandGrid

	func _compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
		if from_id.x == to_id.x or from_id.y == to_id.y:
			return 1.0
		return SQRT2 if RoadNetwork.linked_diagonal(grid, from_id, to_id) else BLOCKED_COST
