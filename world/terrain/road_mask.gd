class_name RoadMask
extends RefCounted
## Máscara das estradas de uma ilha com relevo (Fase 38): a estrada de terra deixa de ser ladrilho e é pintada no
## terreno pela distância até a linha do meio dela. Uma imagem RGBA8 do tamanho da grade, a per_cell pixels por célula:
## r: distância (0 a max_m) até o grafo de segmentos da terra — do centro da célula ao das vizinhas com estrada e ao da
##    diagonal pura (um segmento a 45°, sem escada); na esquina em L, um segmento entre os meios dos dois lados arredonda o
##    canto de dentro; célula solta é um ponto; o trecho entre dois paralelepípedos não entra;
## g: calçamento (1 dentro da célula de paralelepípedo);
## b: desgaste em frente das portas;
## a: poças na terra, no meio da rua.
## Função pura do estado da simulação (nada vai para o save). refresh() refaz só o retângulo das células que mudaram.

## Chance de poça por célula de terra (pelo hash), o raio dela e o raio do chão batido em frente da porta.
const PUDDLE_CHANCE := 0.12
const PUDDLE_RADIUS_M := Vector2(0.3, 0.55)
const DOOR_WEAR_RADIUS_M := 1.5
## Trilhas dos bichos no pasto (Fase 40), no canal b: da porteira ao meio e do meio a um canto (pelo id), desta meia
## largura, e o canto recuado da cerca.
const TRAIL_RADIUS_M := 0.45
const TRAIL_CORNER_M := 0.9
## Quantas células em volta de uma mudança o desenho pode mudar (segmento até a vizinha, mais a distância máxima).
const MARGIN_CELLS := 3
## Os lados e as diagonais que cada célula desenha (os outros são da vizinha).
const OWN_SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
const OWN_DIAGONALS: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1)]
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const CORNERS: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var image: Image
var texture: ImageTexture
var _world: WorldState
var _data: GameData
var _island_id: int
var _grid: IslandGrid
var _per_cell: int
## Distância máxima em pixels.
var _max_px: float
var _width: int
var _height: int
var _bytes := PackedByteArray()
## O que estava desenhado: as estradas e a porta de cada prédio (m da grade).
var _roads := PackedByteArray()
var _doors: Dictionary[int, Vector2] = {}
var _trails: Dictionary[int, PackedVector2Array] = {}


func _init(world: WorldState, data: GameData, island_id: int, per_cell: int, max_m: float) -> void:
	_world = world
	_data = data
	_island_id = island_id
	_grid = world.island(island_id)
	_per_cell = per_cell
	_max_px = max_m / _grid.cell_size * per_cell
	_width = _grid.size.x * per_cell
	_height = _grid.size.y * per_cell
	var empty := Image.create_empty(_width, _height, false, Image.FORMAT_RGBA8)
	empty.fill(Color(1.0, 0.0, 0.0, 0.0))
	_bytes = empty.get_data()
	_roads = _grid.roads.duplicate()
	_doors = doors(world, data, island_id)
	_trails = trails(world, data, island_id)
	_draw(Rect2i(Vector2i.ZERO, _grid.size), false)
	image = Image.create_from_data(_width, _height, false, Image.FORMAT_RGBA8, _bytes)
	texture = ImageTexture.create_from_image(image)


## A estrada de terra da ilha é pintada no terreno (só a ilha com relevo tem terreno).
static func paints(grid: IslandGrid, config: GameConfig) -> bool:
	return config.road_paint and not grid.flat


## Canto da grade no mundo (x, z) e o tamanho dela, em metros: o shader do terreno acha o pixel por aqui.
func bounds() -> Vector4:
	return Vector4(_grid.origin_m.x, _grid.origin_m.y, _grid.size.x * _grid.cell_size, _grid.size.y * _grid.cell_size)


func pixels_per_cell() -> int:
	return _per_cell


## Refaz o que mudou desde o último desenho (estradas e portas) e manda a imagem para a GPU. Devolve o retângulo de
## células redesenhado (vazio se nada mudou).
func refresh() -> Rect2i:
	var area := Rect2i()
	var roads := _grid.roads
	if roads != _roads:
		var width := _grid.size.x
		for y: int in _grid.size.y:
			var row := y * width
			# a linha inteira comparada em C++; só a que mudou é percorrida
			if roads.slice(row, row + width) == _roads.slice(row, row + width):
				continue
			for x: int in width:
				if roads[row + x] != _roads[row + x]:
					area = _merge(area, Rect2i(x, y, 1, 1))
		_roads = roads.duplicate()
	var now := doors(_world, _data, _island_id)
	for id: int in now:
		if not _doors.has(id) or _doors[id] != now[id]:
			area = _merge(area, _door_cell(now[id]))
	for id: int in _doors:
		if not now.has(id):
			area = _merge(area, _door_cell(_doors[id]))
	_doors = now
	var paths := trails(_world, _data, _island_id)
	for id: int in paths:
		if not _trails.has(id) or _trails[id] != paths[id]:
			area = _merge(area, _trail_cells(paths[id]))
	for id: int in _trails:
		if not paths.has(id):
			area = _merge(area, _trail_cells(_trails[id]))
	_trails = paths
	if area.size == Vector2i.ZERO:
		return area
	area = area.grow(MARGIN_CELLS).intersection(Rect2i(Vector2i.ZERO, _grid.size))
	_draw(area, true)
	image.set_data(_width, _height, false, Image.FORMAT_RGBA8, _bytes)
	texture.update(image)
	return area


## A porta de cada prédio da ilha (m da grade, na divisa entre a célula da entrada e o prédio); a decoração não tem.
static func doors(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, Vector2]:
	var result: Dictionary[int, Vector2] = {}
	var cell_size := world.island(island_id).cell_size
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id:
			continue
		var def := data.building(record.def_id)
		if def == null or def.kind == BuildingDef.Kind.DECORATION:
			continue
		var entrance := Footprint.entrance_cell(record.origin, def.size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		result[id] = (Vector2(entrance) + Vector2(0.5, 0.5) - Vector2(front) * 0.5) * cell_size
	return result


## A trilha de cada pasto da ilha (m da grade): porteira, meio e um canto.
static func trails(world: WorldState, data: GameData, island_id: int) -> Dictionary[int, PackedVector2Array]:
	var result: Dictionary[int, PackedVector2Array] = {}
	var cell_size := world.island(island_id).cell_size
	for id: int in world.buildings:
		var record := world.buildings[id]
		if record.island_id != island_id or record.def_id != &"pasture":
			continue
		var def := data.building(record.def_id)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var entrance := Footprint.entrance_cell(record.origin, def.size, record.rotation)
		var front := Footprint.front_direction(record.rotation)
		var gate := (Vector2(entrance) + Vector2(0.5, 0.5) - Vector2(front) * 0.5) * cell_size
		var low := Vector2(area.position) * cell_size + Vector2.ONE * TRAIL_CORNER_M
		var high := Vector2(area.end) * cell_size - Vector2.ONE * TRAIL_CORNER_M
		var pick := absi(hash([id, &"trail"])) % 4
		var corner := Vector2(high.x if pick % 2 == 1 else low.x, high.y if pick >= 2 else low.y)
		result[id] = PackedVector2Array([gate, (Vector2(area.position) + Vector2(area.size) * 0.5) * cell_size, corner])
	return result


func _trail_cells(points: PackedVector2Array) -> Rect2i:
	var area := Rect2i()
	for point: Vector2 in points:
		area = _merge(area, _door_cell(point))
	return area


func _door_cell(door: Vector2) -> Rect2i:
	return Rect2i(Vector2i((door / _grid.cell_size).floor()), Vector2i.ONE)


static func _merge(area: Rect2i, cell: Rect2i) -> Rect2i:
	return cell if area.size == Vector2i.ZERO else area.merge(cell)


## Desenha as células de area (limpa antes se clear): cada fonte que pode alcançar a área (até MARGIN_CELLS fora dela)
## escreve só dentro dela.
func _draw(area: Rect2i, clear: bool) -> void:
	var clip := Rect2i(area.position * _per_cell, area.size * _per_cell)
	if clear:
		for y: int in range(clip.position.y, clip.end.y):
			var base := (y * _width + clip.position.x) * 4
			for x: int in clip.size.x:
				var i := base + x * 4
				_bytes[i] = 255
				_bytes[i + 1] = 0
				_bytes[i + 2] = 0
				_bytes[i + 3] = 0
	var sources := area.grow(MARGIN_CELLS).intersection(Rect2i(Vector2i.ZERO, _grid.size))
	var roads := _grid.roads
	var width := _grid.size.x
	for y: int in range(sources.position.y, sources.end.y):
		for x: int in range(sources.position.x, sources.end.x):
			var road := roads[y * width + x]
			if road != IslandGrid.Road.NONE:
				_draw_cell(Vector2i(x, y), road == IslandGrid.Road.DIRT, clip)
	for id: int in _doors:
		var door := _doors[id] / _grid.cell_size * _per_cell
		if Rect2(clip).grow(DOOR_WEAR_RADIUS_M / _grid.cell_size * _per_cell).has_point(door):
			_stamp_disc(door, DOOR_WEAR_RADIUS_M / _grid.cell_size * _per_cell, 2, clip, true)
	var trail_px := TRAIL_RADIUS_M / _grid.cell_size * _per_cell
	for id: int in _trails:
		var points := _trails[id]
		for k: int in points.size() - 1:
			_stamp_wear(points[k] / _grid.cell_size * _per_cell, points[k + 1] / _grid.cell_size * _per_cell, trail_px, clip)


func _draw_cell(cell: Vector2i, dirt: bool, clip: Rect2i) -> void:
	var center := _center(cell)
	if not dirt:
		# o calçamento: a célula inteira no canal g
		var own := Rect2i(cell * _per_cell, Vector2i.ONE * _per_cell).intersection(clip)
		for y: int in range(own.position.y, own.end.y):
			for x: int in range(own.position.x, own.end.x):
				_bytes[(y * _width + x) * 4 + 1] = 255
	for side: Vector2i in OWN_SIDES:
		var other := cell + side
		if _grid.has_road(other) and (dirt or not _grid.is_paved(other)):
			_stamp_segment(center, _center(other), clip)
	for link: Vector2i in OWN_DIAGONALS:
		var other := cell + link
		if RoadNetwork.linked_diagonal(_grid, cell, other) and (dirt or not _grid.is_paved(other)):
			_stamp_segment(center, _center(other), clip)
	if not dirt:
		return
	var alone := true
	for side: Vector2i in SIDES:
		if _grid.has_road(cell + side):
			alone = false
	for link: Vector2i in CORNERS:
		if RoadNetwork.linked_diagonal(_grid, cell, cell + link):
			alone = false
		var a := Vector2i(link.x, 0)
		var b := Vector2i(0, link.y)
		if not (_grid.has_road(cell + a) and _grid.has_road(cell + b)):
			continue
		var half := float(_per_cell) * 0.5
		if _grid.has_road(cell + link):
			# quadra de estrada 2 × 2: a diagonal tapa o buraco do meio
			_stamp_segment(center, _center(cell + link), clip)
		else:
			# esquina em L: o canto de dentro arredondado
			_stamp_segment(center + Vector2(a) * half, center + Vector2(b) * half, clip)
	if alone:
		_stamp_segment(center, center, clip)
	if _grid.ground_at(cell) != IslandGrid.Ground.RIVER:
		_add_puddle(cell, center, clip)


## Poça pelo hash da célula, na linha do meio da rua, deslocada ao longo dela.
func _add_puddle(cell: Vector2i, center: Vector2, clip: Rect2i) -> void:
	var noise := hash([_grid.origin_m, cell, 53])
	if float(noise % 1000) >= PUDDLE_CHANCE * 1000.0:
		return
	var along := (float(noise / 1000 % 1000) / 1000.0 - 0.5) * 0.5 * _per_cell
	var spot := center
	if _grid.has_road(cell + Vector2i(1, 0)) or _grid.has_road(cell + Vector2i(-1, 0)):
		spot.x += along
	elif _grid.has_road(cell + Vector2i(0, 1)) or _grid.has_road(cell + Vector2i(0, -1)):
		spot.y += along
	var radius := lerpf(PUDDLE_RADIUS_M.x, PUDDLE_RADIUS_M.y, float(noise / 1000000 % 1000) / 1000.0)
	_stamp_disc(spot, radius / _grid.cell_size * _per_cell, 3, clip, false)


## Centro da célula em pixels.
func _center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * _per_cell


## Distância até o segmento a–b (pixels) no canal r, ficando com a menor; só dentro de clip.
func _stamp_segment(a: Vector2, b: Vector2, clip: Rect2i) -> void:
	var low := Vector2i(floori(minf(a.x, b.x) - _max_px), floori(minf(a.y, b.y) - _max_px))
	var high := Vector2i(ceili(maxf(a.x, b.x) + _max_px), ceili(maxf(a.y, b.y) + _max_px))
	var box := Rect2i(low, high - low).intersection(clip)
	var along := b - a
	var length_squared := along.length_squared()
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			var p := Vector2(x + 0.5, y + 0.5) - a
			var t := 0.0 if length_squared == 0.0 else clampf(p.dot(along) / length_squared, 0.0, 1.0)
			var d := (p - along * t).length()
			if d >= _max_px:
				continue
			var value := int(d / _max_px * 255.0)
			var i := (y * _width + x) * 4
			if value < _bytes[i]:
				_bytes[i] = value


## Disco no canal channel, ficando com o maior: liso (a porta, com o miolo cheio) ou em cone (a poça).
func _stamp_disc(center: Vector2, radius: float, channel: int, clip: Rect2i, smooth: bool) -> void:
	var box := Rect2i(Vector2i(floori(center.x - radius), floori(center.y - radius)),
			Vector2i(ceili(radius * 2.0) + 1, ceili(radius * 2.0) + 1)).intersection(clip)
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			var t := Vector2(x + 0.5, y + 0.5).distance_to(center) / radius
			if t >= 1.0:
				continue
			var strength := 1.0 - smoothstep(0.35, 1.0, t) if smooth else 1.0 - t
			var value := int(strength * 255.0)
			var i := (y * _width + x) * 4 + channel
			if value > _bytes[i]:
				_bytes[i] = value


## Trilha no canal b, ficando com o maior: liso perto da linha a–b e somindo até "radius" (pixels); só dentro de clip.
func _stamp_wear(a: Vector2, b: Vector2, radius: float, clip: Rect2i) -> void:
	var low := Vector2i(floori(minf(a.x, b.x) - radius), floori(minf(a.y, b.y) - radius))
	var high := Vector2i(ceili(maxf(a.x, b.x) + radius), ceili(maxf(a.y, b.y) + radius))
	var box := Rect2i(low, high - low).intersection(clip)
	var along := b - a
	var length_squared := along.length_squared()
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			var p := Vector2(x + 0.5, y + 0.5) - a
			var t := 0.0 if length_squared == 0.0 else clampf(p.dot(along) / length_squared, 0.0, 1.0)
			var d := (p - along * t).length() / radius
			if d >= 1.0:
				continue
			var value := int((1.0 - smoothstep(0.3, 1.0, d)) * 0.85 * 255.0)
			var i := (y * _width + x) * 4 + 2
			if value > _bytes[i]:
				_bytes[i] = value


## Distância (m) até a linha do meio da terra no ponto (m da grade), lida da imagem (testes).
func distance_at(point: Vector2) -> float:
	var pixel := Vector2i((point / _grid.cell_size * _per_cell).floor())
	return float(_bytes[(pixel.y * _width + pixel.x) * 4]) / 255.0 * (_max_px / _per_cell * _grid.cell_size)


## Valor (0 a 1) do canal no ponto (m da grade), lido da imagem (testes).
func channel_at(point: Vector2, channel: int) -> float:
	var pixel := Vector2i((point / _grid.cell_size * _per_cell).floor())
	return float(_bytes[(pixel.y * _width + pixel.x) * 4 + channel]) / 255.0
