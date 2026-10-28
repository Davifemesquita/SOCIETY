class_name IslandGrid
extends RefCounted
## Mapa espacial de uma ilha: ocupação por prédio e estradas, em arrays compactos.
## Célula (x, y) fica no índice y * width + x. Ocupação 0 = livre; senão, o id do prédio.
## Desde a Fase 5 a ilha tem lugar no mundo (origin_m), altura em cada canto de célula, chão
## (terra, mar, rio), árvores e jazidas, tudo saído da semente (ArchipelagoGenerator). A ilha
## plana de antes (flat) segue valendo para testes e saves antigos: sem relevo e sem água por
## dentro; o litoral é a borda.

## PAVED (Fase 8): paralelepípedo, mais rápido para as carroças e mais barato no A*.
enum Road { NONE = 0, DIRT = 1, PAVED = 2 }
enum Ground { LAND = 0, SEA = 1, RIVER = 2 }

var size: Vector2i
var occupancy: PackedInt32Array
var roads: PackedByteArray
## Ferrovia (Fase 70): 1 nas células com trilho. Trilho não leva carroça nem gente e não divide célula com prédio
## nem estrada; só liga o poço de petróleo à usina.
var rails: PackedByteArray
## Campos de petróleo (Fase 70): as células onde o poço pode ser construído, tiradas da semente depois da assinatura
## do terreno (ArchipelagoGenerator; não mudam a assinatura). Vazio na ilha plana e nas tropicais.
var oil_spots := PackedInt32Array()
## Canto (0, 0) da ilha no mundo, em metros (x, z).
var origin_m := Vector2.ZERO
var cell_size: float = 2.0
## Ilha plana de antes da Fase 5: árvores, jazidas e rios valem como presentes.
var flat: bool = true
## Altura de cada canto de célula, (w + 1) × (h + 1); vazio na ilha plana (altura 0).
var corner_heights := PackedFloat32Array()
## Chão de cada célula (Ground); vazio na ilha plana (tudo terra).
var ground := PackedByteArray()
## Árvores em cada célula (0 a max_trees_per_cell).
var trees := PackedByteArray()
## Jazida de cada célula: 0 nenhuma; senão o índice + 1 em deposit_goods.
var deposits := PackedByteArray()
var deposit_goods: Array[StringName] = []
## Células onde a construção derrubou as árvores (1). Vão para o save: a semente refaz o resto.
var cleared_trees := PackedByteArray()
## Assinatura do terreno recém-gerado (ArchipelagoGenerator.fingerprint); 0 na ilha plana.
var fingerprint: int = 0
## Altura de cada célula e da estrada nela, calculadas uma vez (o relevo não muda depois de gerado):
## rotas de pedestre e carroças pedem isto célula a célula.
var _cell_heights := PackedFloat32Array()
var _road_heights := PackedFloat32Array()


func _init(grid_size: Vector2i) -> void:
	size = grid_size
	occupancy.resize(size.x * size.y)
	roads.resize(size.x * size.y)
	rails.resize(size.x * size.y)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func contains_rect(area: Rect2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).encloses(area)


func index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


func cell_at(cell_index: int) -> Vector2i:
	return Vector2i(cell_index % size.x, cell_index / size.x)


func building_at(cell: Vector2i) -> int:
	return occupancy[index(cell)] if in_bounds(cell) else 0


func has_road(cell: Vector2i) -> bool:
	return in_bounds(cell) and roads[index(cell)] != Road.NONE


func is_paved(cell: Vector2i) -> bool:
	return in_bounds(cell) and roads[index(cell)] == Road.PAVED


func fill_building(area: Rect2i, building_id: int) -> void:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			occupancy[y * size.x + x] = building_id


func set_road(cell: Vector2i, road: Road) -> void:
	roads[index(cell)] = road


func has_rail(cell: Vector2i) -> bool:
	return in_bounds(cell) and rails[index(cell)] != 0


func set_rail(cell: Vector2i, on: bool) -> void:
	rails[index(cell)] = 1 if on else 0


func rail_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i: int in rails.size():
		if rails[i] != 0:
			cells.append(cell_at(i))
	return cells


## O retângulo cobre um campo de petróleo (Fase 70).
func area_on_oil(area: Rect2i) -> bool:
	for spot: int in oil_spots:
		if area.has_point(cell_at(spot)):
			return true
	return false


func road_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i: int in roads.size():
		if roads[i] != Road.NONE:
			cells.append(cell_at(i))
	return cells


# --- terreno ---

## Prepara os arrays do terreno gerado (a ilha deixa de ser plana).
func init_terrain() -> void:
	flat = false
	corner_heights.resize((size.x + 1) * (size.y + 1))
	ground.resize(size.x * size.y)
	trees.resize(size.x * size.y)
	deposits.resize(size.x * size.y)
	cleared_trees.resize(size.x * size.y)


func corner_index(x: int, y: int) -> int:
	return y * (size.x + 1) + x


func corner_height(x: int, y: int) -> float:
	if corner_heights.is_empty():
		return 0.0
	return corner_heights[clampi(y, 0, size.y) * (size.x + 1) + clampi(x, 0, size.x)]


## Altura média dos quatro cantos da célula.
func cell_height(cell: Vector2i) -> float:
	if corner_heights.is_empty():
		return 0.0
	if in_bounds(cell):
		if _cell_heights.is_empty():
			_cache_heights()
		return _cell_heights[cell.y * size.x + cell.x]
	return _corner_average(cell)


func _corner_average(cell: Vector2i) -> float:
	return (corner_height(cell.x, cell.y) + corner_height(cell.x + 1, cell.y)
			+ corner_height(cell.x, cell.y + 1) + corner_height(cell.x + 1, cell.y + 1)) * 0.25


## Calcula de uma vez a altura de todas as células e a da estrada (no rio, a das margens).
func _cache_heights() -> void:
	_cell_heights.resize(size.x * size.y)
	_road_heights.resize(size.x * size.y)
	for y: int in size.y:
		for x: int in size.x:
			var a := corner_heights[y * (size.x + 1) + x]
			var b := corner_heights[y * (size.x + 1) + x + 1]
			var c := corner_heights[(y + 1) * (size.x + 1) + x]
			var d := corner_heights[(y + 1) * (size.x + 1) + x + 1]
			var i := y * size.x + x
			_cell_heights[i] = (a + b + c + d) * 0.25
			var river := not ground.is_empty() and ground[i] == Ground.RIVER
			_road_heights[i] = maxf(maxf(a, b), maxf(c, d)) if river else _cell_heights[i]


## Esquece as alturas guardadas (o gerador e os testes mexem nos cantos antes de usar).
func invalidate_heights() -> void:
	_cell_heights = PackedFloat32Array()
	_road_heights = PackedFloat32Array()


## Diferença entre o canto mais alto e o mais baixo da área (0 = plana).
func area_relief(area: Rect2i) -> float:
	if corner_heights.is_empty():
		return 0.0
	var low := INF
	var high := -INF
	for y: int in range(area.position.y, area.end.y + 1):
		for x: int in range(area.position.x, area.end.x + 1):
			var h := corner_height(x, y)
			low = minf(low, h)
			high = maxf(high, h)
	return high - low


## Altura média dos cantos da área (onde o prédio assenta).
func area_height(area: Rect2i) -> float:
	if corner_heights.is_empty():
		return 0.0
	var total := 0.0
	for y: int in range(area.position.y, area.end.y + 1):
		for x: int in range(area.position.x, area.end.x + 1):
			total += corner_height(x, y)
	return total / ((area.size.x + 1) * (area.size.y + 1))


## Chão da célula (Ground); fora da grade é mar.
func ground_at(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return Ground.SEA
	if ground.is_empty():
		return Ground.LAND
	return ground[index(cell)]


func is_land(cell: Vector2i) -> bool:
	return ground_at(cell) == Ground.LAND


## Toda a área é terra.
func area_is_land(area: Rect2i) -> bool:
	if ground.is_empty():
		return contains_rect(area)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if ground_at(Vector2i(x, y)) != Ground.LAND:
				return false
	return true


## Alguma célula encostada na área (pelos lados) tem o chão dado. Fora da grade conta como mar.
func area_touches(area: Rect2i, kind: int) -> bool:
	for x: int in range(area.position.x, area.end.x):
		if ground_at(Vector2i(x, area.position.y - 1)) == kind or ground_at(Vector2i(x, area.end.y)) == kind:
			return true
	for y: int in range(area.position.y, area.end.y):
		if ground_at(Vector2i(area.position.x - 1, y)) == kind or ground_at(Vector2i(area.end.x, y)) == kind:
			return true
	return false


func trees_at(cell: Vector2i) -> int:
	return trees[index(cell)] if in_bounds(cell) and not trees.is_empty() else 0


## Árvores dentro da área (cortada nas bordas da ilha).
func trees_in(area: Rect2i) -> int:
	if trees.is_empty():
		return 0
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, size))
	var total := 0
	for y: int in range(clipped.position.y, clipped.end.y):
		for x: int in range(clipped.position.x, clipped.end.x):
			total += trees[y * size.x + x]
	return total


## Derruba as árvores das células (construção) e guarda quais foram, para o save.
func clear_trees(cells: Array[Vector2i]) -> bool:
	var changed := false
	if trees.is_empty():
		return false
	for cell: Vector2i in cells:
		var i := index(cell)
		if trees[i] > 0:
			trees[i] = 0
			cleared_trees[i] = 1
			changed = true
	return changed


func deposit_at(cell: Vector2i) -> StringName:
	if not in_bounds(cell) or deposits.is_empty() or deposits[index(cell)] == 0:
		return &""
	return deposit_goods[deposits[index(cell)] - 1]


## A área inteira está sobre jazida do bem dado.
func area_on_deposit(area: Rect2i, good: StringName) -> bool:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if deposit_at(Vector2i(x, y)) != good:
				return false
	return true


# --- mundo ---

## Retângulo da ilha no mundo (metros, plano XZ).
func world_rect() -> Rect2:
	return Rect2(origin_m, Vector2(size) * cell_size)


## Centro da célula no mundo, na altura dela.
func cell_world(cell: Vector2i) -> Vector3:
	return Vector3(origin_m.x + (cell.x + 0.5) * cell_size, cell_height(cell), origin_m.y + (cell.y + 0.5) * cell_size)


## Altura por onde a estrada passa: a do terreno; no rio, a das margens (ponte).
func road_height(cell: Vector2i) -> float:
	if corner_heights.is_empty():
		return 0.0
	if not in_bounds(cell):
		return _corner_average(cell)
	if _road_heights.is_empty():
		_cache_heights()
	return _road_heights[cell.y * size.x + cell.x]


## Centro da célula no mundo, na altura da estrada (sobre a ponte, no rio).
func surface_world(cell: Vector2i) -> Vector3:
	var point := cell_world(cell)
	point.y = road_height(cell)
	return point


## Centro da área no mundo, na altura média dela.
func rect_world(area: Rect2i) -> Vector3:
	return Vector3(origin_m.x + (area.position.x + area.size.x * 0.5) * cell_size, area_height(area),
			origin_m.y + (area.position.y + area.size.y * 0.5) * cell_size)


## Célula sob o ponto do mundo (pode cair fora da grade).
func world_to_cell(point: Vector3) -> Vector2i:
	return Vector2i(floori((point.x - origin_m.x) / cell_size), floori((point.z - origin_m.y) / cell_size))


## Altura do terreno num ponto do mundo (bilinear entre os cantos); fora da grade, a da borda.
func height_at(x_m: float, z_m: float) -> float:
	if corner_heights.is_empty():
		return 0.0
	var gx := clampf((x_m - origin_m.x) / cell_size, 0.0, size.x)
	var gz := clampf((z_m - origin_m.y) / cell_size, 0.0, size.y)
	var x0 := mini(floori(gx), size.x - 1)
	var z0 := mini(floori(gz), size.y - 1)
	var fx := gx - x0
	var fz := gz - z0
	var top := lerpf(corner_height(x0, z0), corner_height(x0 + 1, z0), fx)
	var bottom := lerpf(corner_height(x0, z0 + 1), corner_height(x0 + 1, z0 + 1), fx)
	return lerpf(top, bottom, fz)
