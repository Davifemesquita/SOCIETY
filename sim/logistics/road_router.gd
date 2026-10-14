class_name RoadRouter
extends RefCounted
## Rotas pela estrada de uma ilha: um AStarGrid2D em que só as células de estrada são
## passáveis (seção 6). Feito de novo quando a rede muda; as rotas pedidas ficam em cache.
## A estrada de paralelepípedo (Fase 8) entra com peso menor na mesma grade.

var _grid: IslandGrid
var _astar := AStarGrid2D.new()
var _cache: Dictionary[int, PackedInt32Array] = {}


## Peso da célula de terra no A* (a de paralelepípedo pesa 1): o tempo relativo de passar por ela.
## A terra é que pesa mais, e não o paralelepípedo menos, para a heurística de Manhattan (1 por
## célula) nunca passar do custo real: senão o A* devolve o caminho de terra mesmo com um calçado
## mais rápido ao lado.
var dirt_weight: float = 1.5


func _init(grid: IslandGrid, paved_speed_bonus: float = 0.5) -> void:
	dirt_weight = 1.0 + paved_speed_bonus
	_grid = grid
	_astar.region = Rect2i(Vector2i.ZERO, grid.size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
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
		for cell: Vector2i in _astar.get_id_path(_grid.cell_at(from), _grid.cell_at(to)):
			cells.append(_grid.index(cell))
	_cache[key] = cells
	return cells
