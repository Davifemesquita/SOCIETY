class_name RoadView
extends MultiMeshInstance3D
## Estradas de terra e de paralelepípedo (cinza, Fase 8) como ladrilhos num MultiMesh (todas as ilhas), refeito quando a rede muda.
## No relevo o ladrilho inclina com o terreno (a base tem cisalhamento, a espessura fica de pé);
## sobre o rio vira ponte de tábuas, plana, na altura das margens.
## Fase 14: a rua de paralelepípedo ganha meio-fio de pedra nos lados que não dão para outra estrada, e a de
## terra, dois sulcos de roda na direção dela (no shader, pelo dado da instância). Fase 17: entre duas células
## ligadas pela diagonal pura vai uma faixa girada 45°, do centro de uma ao da outra, com os sulcos ao longo dela;
## a célula do meio da escada não leva ladrilho (as faixas se encontram no centro dela), a da ponta leva os sulcos
## na diagonal, e o meio-fio não sai nos lados que a faixa corta. A ponte ganha tábuas no
## shader, corrimão de madeira nos lados que dão para o rio e estacas descendo até o leito. Fase 19: o ladrilho
## dobra pelos quatro cantos da célula (a altura deles relativa ao centro vai na cor da instância e o shader
## desloca os vértices), sem degrau entre células na ladeira; a terra tem a borda recortada nos lados abertos
## (no shader, pelos bits em INSTANCE_CUSTOM.a) e touceiras de capim ao longo deles.

const DIRT_COLOR := Color(0.55, 0.45, 0.33)
const BRIDGE_COLOR := Color(0.36, 0.26, 0.17)
const PAVED_COLOR := Color(0.3, 0.3, 0.33)
const THICKNESS_M := 0.08
## O ladrilho fica um pouco acima do chão, para não brigar com o terreno.
const LIFT_M := 0.06
## Meio-fio: largura e altura acima do calçamento (a pedra é do shaders/curb.gdshader).
const CURB_WIDTH_M := 0.22
const CURB_HEIGHT_M := 0.1

## Ponte: altura do corrimão sobre o tabuleiro, grossura do poste e da travessa, e quanto a estaca
## entra no leito do rio.
const RAIL_HEIGHT_M := 0.9
const POST_WIDTH_M := 0.12
const RAIL_WIDTH_M := 0.07
const PILE_WIDTH_M := 0.2
const PILE_SINK_M := 0.4
const RAIL_COLOR := Color(0.42, 0.3, 0.19)
## Direção dos sulcos no dado da instância (b): nenhum, ao longo de x, ao longo de z, os dois (cruzamento).
## DIAGONAL_DOWN e DIAGONAL_UP (Fase 17): ao longo de (+x, +z) e de (+x, −z).
enum Ruts { NONE, ALONG_X, ALONG_Z, BOTH, DIAGONAL_DOWN, DIAGONAL_UP }
## Os dois sentidos da diagonal que cada célula olha (o outro par é olhado pela vizinha).
const DIAGONALS: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
## A faixa da diagonal fica um pouco acima dos ladrilhos, para não brigar com eles.
const DIAGONAL_LIFT_M := 0.01
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Bit de cada lado de SIDES (o shader lê os bits em INSTANCE_CUSTOM.b, acima dos sulcos: b = sulcos + 8 × bits).
const SIDE_BITS: Array[int] = [1, 2, 4, 8]
const OPEN_SHIFT := 8
## Touceiras de capim por lado aberto da terra, e quanto saem da borda para fora.
const VERGE_TUFTS := 3
const VERGE_OUT_M := 0.12

var _simulation: Simulation
var _cell_size: float
var _curbs := MultiMeshInstance3D.new()
var _rails := MultiMeshInstance3D.new()
var _posts := MultiMeshInstance3D.new()
var _verge := MultiMeshInstance3D.new()


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	var tile := BoxMesh.new()
	tile.size = Vector3(cell_size, THICKNESS_M, cell_size)
	# Fase 9: terra batida e paralelepípedo da Poly Haven; a ponte fica na cor da tábua
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/road.gdshader") as Shader
	material.set_shader_parameter(&"albedo_rough", load("res://assets/materials/roads_albedo_rough.png"))
	material.set_shader_parameter(&"normals", load("res://assets/materials/roads_normal.png"))
	material.set_shader_parameter(&"cell_m", cell_size)
	tile.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = tile
	var curb := BoxMesh.new()
	curb.size = Vector3(CURB_WIDTH_M, THICKNESS_M + CURB_HEIGHT_M, cell_size)
	# Fase 19: a pedra do meio-fio com a textura do paralelepípedo, cinza e clareada, e a junta dos blocos
	var stone := ShaderMaterial.new()
	stone.shader = load("res://shaders/curb.gdshader") as Shader
	stone.set_shader_parameter(&"albedo_rough", material.get_shader_parameter(&"albedo_rough"))
	stone.set_shader_parameter(&"normals", material.get_shader_parameter(&"normals"))
	curb.material = stone
	_curbs.name = "Curbs"
	_curbs.multimesh = MultiMesh.new()
	_curbs.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_curbs.multimesh.mesh = curb
	add_child(_curbs)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = RAIL_COLOR
	wood.roughness = 0.85
	var rail := BoxMesh.new()
	rail.size = Vector3(cell_size, RAIL_WIDTH_M, RAIL_WIDTH_M)
	rail.material = wood
	# poste e estaca: caixa de 1 m de altura, esticada em y pela transformação
	var post := BoxMesh.new()
	post.size = Vector3(1.0, 1.0, 1.0)
	post.material = wood
	for part: Array in [[_rails, "Rails", rail], [_posts, "Posts", post]]:
		var holder: MultiMeshInstance3D = part[0]
		holder.name = part[1]
		holder.multimesh = MultiMesh.new()
		holder.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		holder.multimesh.mesh = part[2]
		add_child(holder)
	var grass := StandardMaterial3D.new()
	grass.vertex_color_use_as_albedo = true
	grass.vertex_color_is_srgb = true
	grass.roughness = 0.9
	_verge.name = "Verge"
	_verge.multimesh = MultiMesh.new()
	_verge.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_verge.multimesh.mesh = CropView.tuft_mesh()
	_verge.material_override = grass
	add_child(_verge)
	EventBus.roads_changed.connect(func(_island_id: int) -> void: rebuild())
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func rebuild() -> void:
	var tiles: Array[Transform3D] = []
	var colors: Array[Color] = []
	var kinds: Array[Color] = []
	var curbs: Array[Transform3D] = []
	var rails: Array[Transform3D] = []
	var posts: Array[Transform3D] = []
	var tufts: Array[Transform3D] = []
	for grid: IslandGrid in _simulation.world.islands:
		for cell: Vector2i in grid.road_cells():
			var bridge := grid.ground_at(cell) == IslandGrid.Ground.RIVER
			var paved := grid.is_paved(cell)
			var tile := tile_transform(grid, cell)
			var links := diagonal_links(grid, cell)
			# no meio da escada diagonal só as faixas: o ladrilho quadrado deixava a borda serrilhada
			if not in_diagonal_run(grid, cell, links):
				var open := 0 if bridge else open_edges(grid, cell, links)
				tiles.append(tile)
				colors.append(BRIDGE_COLOR if bridge else (PAVED_COLOR if paved else DIRT_COLOR))
				kinds.append(Color(1.0 if paved else 0.0, 1.0 if bridge else 0.0, float(ruts(grid, cell) + OPEN_SHIFT * open),
						twist(grid, cell)))
				if not paved:
					_add_verge(grid, cell, open, tufts)
			if paved and not bridge:
				for side: Vector2i in SIDES:
					if not grid.has_road(cell + side) and not _cut_by(side, links):
						curbs.append(tile * curb_place(side, _cell_size))
			# a faixa da diagonal: cada par uma vez, olhando só para +x
			for link: Vector2i in links:
				if link.x > 0:
					var other := cell + link
					var both_paved := paved and grid.is_paved(other)
					var both_bridge := bridge and grid.ground_at(other) == IslandGrid.Ground.RIVER
					tiles.append(diagonal_transform(grid, cell, link))
					colors.append(BRIDGE_COLOR if both_bridge else (PAVED_COLOR if both_paved else DIRT_COLOR))
					kinds.append(Color(1.0 if both_paved else 0.0, 1.0 if both_bridge else 0.0, float(Ruts.ALONG_X), 0.0))
			if bridge:
				_add_railing(grid, cell, tile, rails, posts)
	multimesh.instance_count = tiles.size()
	for i: int in tiles.size():
		multimesh.set_instance_transform(i, tiles[i])
		multimesh.set_instance_color(i, colors[i])
		multimesh.set_instance_custom_data(i, kinds[i])
	_curbs.multimesh.instance_count = curbs.size()
	for i: int in curbs.size():
		_curbs.multimesh.set_instance_transform(i, curbs[i])
	_rails.multimesh.instance_count = rails.size()
	for i: int in rails.size():
		_rails.multimesh.set_instance_transform(i, rails[i])
	_posts.multimesh.instance_count = posts.size()
	for i: int in posts.size():
		_posts.multimesh.set_instance_transform(i, posts[i])
	_verge.multimesh.instance_count = tufts.size()
	for i: int in tufts.size():
		_verge.multimesh.set_instance_transform(i, tufts[i])


## Touceiras de capim ao longo dos lados abertos da terra, um pouco para fora da borda, no chão; o lugar, o
## tamanho e o giro vêm do hash da célula (os mesmos depois de carregar).
func _add_verge(grid: IslandGrid, cell: Vector2i, open: int, tufts: Array[Transform3D]) -> void:
	if open == 0:
		return
	var center := grid.cell_world(cell)
	var half := _cell_size * 0.5
	for index: int in SIDES.size():
		if open & SIDE_BITS[index] == 0:
			continue
		var side := SIDES[index]
		var along := Vector3(-side.y, 0.0, side.x)
		for k: int in VERGE_TUFTS:
			var noise := hash([grid.origin_m, cell, index, k])
			var t := (float(k) + 0.2 + float(noise % 600) / 1000.0) / VERGE_TUFTS * 2.0 - 1.0
			var out := half + VERGE_OUT_M * float(noise / 1000 % 1000) / 1000.0
			var spot := center + Vector3(side.x, 0.0, side.y) * out + along * t * half
			spot.y = grid.height_at(spot.x, spot.z)
			var size := 0.7 + 0.6 * float(noise / 1000000 % 1000) / 1000.0
			tufts.append(Transform3D(Basis(Vector3.UP, float(noise % 628) / 100.0).scaled(Vector3.ONE * size), spot))


func verge_count() -> int:
	return _verge.multimesh.instance_count


## Lados abertos da célula de terra (bits de SIDE_BITS): sem estrada vizinha e não cortados pela diagonal.
static func open_edges(grid: IslandGrid, cell: Vector2i, links: Array[Vector2i]) -> int:
	var bits := 0
	for index: int in SIDES.size():
		var side := SIDES[index]
		if not grid.has_road(cell + side) and not _cut_by(side, links):
			bits |= SIDE_BITS[index]
	return bits


## Torção da célula: o que o plano inclinado do ladrilho (tile_transform) não alcança nos cantos. O canto sai
## do plano em ± torção/4 (+ nos cantos −x −z e +x +z); o shader soma torção × (x/lado) × (z/lado). Zero no rio
## e na ilha plana.
static func twist(grid: IslandGrid, cell: Vector2i) -> float:
	if grid.ground_at(cell) == IslandGrid.Ground.RIVER or grid.flat:
		return 0.0
	return (grid.corner_height(cell.x, cell.y) + grid.corner_height(cell.x + 1, cell.y + 1)
			- grid.corner_height(cell.x + 1, cell.y) - grid.corner_height(cell.x, cell.y + 1))


## Corrimão da célula de ponte: em cada lado aberto para o rio, duas travessas, um poste no meio (com a
## estaca embaixo, até o leito) e os dos cantos. O canto da frente só entra onde o corrimão acaba, para
## a célula vizinha não repetir o poste.
func _add_railing(grid: IslandGrid, cell: Vector2i, tile: Transform3D, rails: Array[Transform3D],
		posts: Array[Transform3D]) -> void:
	var deck := THICKNESS_M * 0.5
	var bottom := grid.cell_height(cell) - PILE_SINK_M - tile.origin.y
	for side: Vector2i in SIDES:
		if not railed(grid, cell, side):
			continue
		var along := Vector2i(absi(side.y), absi(side.x))
		var out := Vector3(side.x, 0.0, side.y) * (_cell_size * 0.5 - POST_WIDTH_M * 0.5)
		var basis := Basis.IDENTITY if side.y != 0 else Basis(Vector3.UP, PI * 0.5)
		for height: float in [RAIL_HEIGHT_M, RAIL_HEIGHT_M * 0.5]:
			rails.append(tile * Transform3D(basis, out + Vector3(0.0, deck + height, 0.0)))
		var post_height := RAIL_HEIGHT_M + RAIL_WIDTH_M
		var post := Basis.from_scale(Vector3(POST_WIDTH_M, post_height, POST_WIDTH_M))
		var corner := Vector3(along.x, 0.0, along.y) * (_cell_size * 0.5 - POST_WIDTH_M * 0.5)
		var offsets: Array[Vector3] = [Vector3.ZERO, -corner]
		if not railed(grid, cell + along, side):
			offsets.append(corner)
		for offset: Vector3 in offsets:
			posts.append(tile * Transform3D(post, out + offset + Vector3(0.0, deck + post_height * 0.5, 0.0)))
		var pile_height := maxf(-deck - bottom, 0.0)
		var pile := Basis.from_scale(Vector3(PILE_WIDTH_M, pile_height, PILE_WIDTH_M))
		posts.append(tile * Transform3D(pile, out + Vector3(0.0, -deck - pile_height * 0.5, 0.0)))


## O lado side da célula leva corrimão: é ponte (estrada no rio) e não dá para outra estrada.
static func railed(grid: IslandGrid, cell: Vector2i, side: Vector2i) -> bool:
	return grid.has_road(cell) and grid.ground_at(cell) == IslandGrid.Ground.RIVER and not grid.has_road(cell + side)


func tile_count() -> int:
	return multimesh.instance_count


func curb_count() -> int:
	return _curbs.multimesh.instance_count


func rail_count() -> int:
	return _rails.multimesh.instance_count


## Postes do corrimão e estacas da ponte, juntos.
func post_count() -> int:
	return _posts.multimesh.instance_count


## Para onde vão os sulcos de roda da célula: ao longo da rua reta, os dois no cruzamento e na curva, na
## diagonal na célula da escada diagonal (Fase 17), nenhum na célula solta.
static func ruts(grid: IslandGrid, cell: Vector2i) -> int:
	var along_x := grid.has_road(cell + Vector2i(1, 0)) or grid.has_road(cell + Vector2i(-1, 0))
	var along_z := grid.has_road(cell + Vector2i(0, 1)) or grid.has_road(cell + Vector2i(0, -1))
	if along_x and along_z:
		return Ruts.BOTH
	if along_x:
		return Ruts.ALONG_X
	if along_z:
		return Ruts.ALONG_Z
	for link: Vector2i in diagonal_links(grid, cell):
		return Ruts.DIAGONAL_DOWN if link.x == link.y else Ruts.DIAGONAL_UP
	return Ruts.NONE


## Para que lados do canto a célula se liga pela diagonal pura (Fase 17).
static func diagonal_links(grid: IslandGrid, cell: Vector2i) -> Array[Vector2i]:
	var links: Array[Vector2i] = []
	for link: Vector2i in DIAGONALS:
		if RoadNetwork.linked_diagonal(grid, cell, cell + link):
			links.append(link)
	return links


## A célula está no meio de uma escada diagonal (Fase 17): duas ligações pelo canto em linha e nenhuma estrada
## de lado. Ela não leva ladrilho quadrado; as duas faixas se encontram no centro dela.
static func in_diagonal_run(grid: IslandGrid, cell: Vector2i, links: Array[Vector2i]) -> bool:
	if links.size() != 2 or links[0] != -links[1]:
		return false
	for side: Vector2i in SIDES:
		if grid.has_road(cell + side):
			return false
	return true


## O lado side da célula é cortado por alguma das faixas diagonais dela.
static func _cut_by(side: Vector2i, links: Array[Vector2i]) -> bool:
	for link: Vector2i in links:
		if (side.x != 0 and side.x == link.x) or (side.y != 0 and side.y == link.y):
			return true
	return false


## A faixa da diagonal de cell até cell + link (Fase 17): o ladrilho esticado √2 em x e girado para que o x
## dele siga a diagonal, no meio das duas células, na altura média delas.
static func diagonal_transform(grid: IslandGrid, cell: Vector2i, link: Vector2i) -> Transform3D:
	var a := grid.surface_world(cell)
	var b := grid.surface_world(cell + link)
	var center := (a + b) * 0.5 + Vector3(0.0, LIFT_M + THICKNESS_M * 0.5 + DIAGONAL_LIFT_M, 0.0)
	var basis := Basis(Vector3.UP, -atan2(float(link.y), float(link.x))) * Basis.from_scale(Vector3(sqrt(2.0), 1.0, 1.0))
	return Transform3D(basis, center)


## O meio-fio do lado side, no referencial do ladrilho: encostado na borda, de pé sobre o calçamento.
static func curb_place(side: Vector2i, cell_size: float) -> Transform3D:
	var basis := Basis.IDENTITY if side.x != 0 else Basis(Vector3.UP, PI * 0.5)
	var out := Vector3(side.x, 0.0, side.y) * (cell_size * 0.5 - CURB_WIDTH_M * 0.5)
	return Transform3D(basis, out + Vector3(0.0, CURB_HEIGHT_M * 0.5, 0.0))


## Ladrilho da célula: centro na altura da estrada; fora do rio, inclinado como o plano dos
## quatro cantos (cisalhamento: x e z sobem com a ladeira, y fica de pé).
static func tile_transform(grid: IslandGrid, cell: Vector2i) -> Transform3D:
	var center := grid.surface_world(cell) + Vector3(0.0, LIFT_M + THICKNESS_M * 0.5, 0.0)
	if grid.ground_at(cell) == IslandGrid.Ground.RIVER or grid.flat:
		return Transform3D(Basis.IDENTITY, center)
	var size := grid.cell_size
	var slope_x := ((grid.corner_height(cell.x + 1, cell.y) + grid.corner_height(cell.x + 1, cell.y + 1))
			- (grid.corner_height(cell.x, cell.y) + grid.corner_height(cell.x, cell.y + 1))) * 0.5 / size
	var slope_z := ((grid.corner_height(cell.x, cell.y + 1) + grid.corner_height(cell.x + 1, cell.y + 1))
			- (grid.corner_height(cell.x, cell.y) + grid.corner_height(cell.x + 1, cell.y))) * 0.5 / size
	return Transform3D(Basis(Vector3(1.0, slope_x, 0.0), Vector3.UP, Vector3(0.0, slope_z, 1.0)), center)
