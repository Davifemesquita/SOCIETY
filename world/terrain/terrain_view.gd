class_name TerrainView
extends Node3D
## Adaptador do terreno (seção 13): desenha o relevo das ilhas geradas. A especificação pede o
## Terrain3D, mas o 1.0.2 derruba o Godot 4.7.2 assim que recebe um relevo de verdade (condição
## de corrida no material, issue #945 do Terrain3D, corrigida só na versão noturna): até sair uma
## versão estável compatível, o terreno é próprio — uma malha por trecho de cada região, de 2 em
## 2 m (os cantos da grade, os mesmos que a simulação usa), e o shader de terreno com as texturas
## da Poly Haven. Trocar de volta mexe só aqui.
## Desde a Fase 34 cada ilha leva também as texturas de dados do TerrainBake (inclinação, curvatura, água, umidade),
## e o hex-tiling da grama e da floresta segue o nível gráfico (terrain_hex_tiling).
## Fase 38: a estrada de terra é pintada no terreno pela máscara das estradas (RoadMask), refeita quando a rede ou as
## portas mudam.

const TEXTURES: Array[String] = ["grass", "rock", "sand", "forest"]
const SHADER := preload("res://shaders/terrain.gdshader")
## Vértices de lado em cada trecho de malha (recorte por câmera trecho a trecho).
const CHUNK_VERTICES := 64
## Fase 38: a terra batida das estradas (camada 0 das texturas das estradas) pintada no terreno.
const ROAD_ALBEDO := preload("res://assets/materials/roads_albedo_rough.png")
const ROAD_NORMAL := preload("res://assets/materials/roads_normal.png")

var _world: WorldState
var _config: GameConfig
var _data: GameData
## Por ilha: a textura do tipo de chão e a imagem dela (as árvores derrubadas mudam pixels).
var _surfaces: Dictionary[int, ImageTexture] = {}
var _surface_images: Dictionary[int, Image] = {}
var _chunks: int = 0
## Por ilha: a textura de dados (Fase 34) e o material do terreno.
var _data_images: Dictionary[int, Image] = {}
var _materials: Array[ShaderMaterial] = []
var _hex_tiling: bool = true
## Fase 35: a distância até a costa com sinal de cada região e o mapa do arquipélago que a água lê.
var _coast_regions: Array[Dictionary] = []
var _coast: CoastField
## Fase 36: por ilha, o que refazer quando uma estrada nova cai num barranco com detalhe: as alturas da região, o canto
## dela, as células com algum canto mexido e os trechos de malha (por Vector2i do trecho).
var _regions: Dictionary[int, Dictionary] = {}
var _detail_cells: Dictionary[int, PackedInt32Array] = {}
var _chunk_nodes: Dictionary[int, Dictionary] = {}
## Fase 38: por ilha, a máscara das estradas (RoadMask); as que mudaram são refeitas uma vez, no quadro seguinte.
var _road_masks: Dictionary[int, RoadMask] = {}
var _dirty_masks: Dictionary[int, bool] = {}


func setup(world: WorldState, config: GameConfig, data: GameData) -> void:
	_world = world
	_config = config
	_data = data
	var textures: Dictionary[String, Texture2D] = {}
	for name: String in TEXTURES:
		textures[name + "_albedo"] = load("res://assets/terrain/%s_albedo_height.png" % name)
		textures[name + "_normal"] = load("res://assets/terrain/%s_normal_roughness.png" % name)
	_hex_tiling = Settings.preset().terrain_hex_tiling
	for index: int in world.islands.size():
		if not world.island(index).flat:
			_build_island(index, textures)
	_coast = CoastField.compose(_coast_regions, config.cell_size_m, config.coast_field_max_m)
	_coast_regions.clear()
	EventBus.trees_changed.connect(_on_trees_changed)
	EventBus.roads_changed.connect(_on_roads_changed)
	EventBus.settings_changed.connect(func() -> void: set_hex_tiling(Settings.preset().terrain_hex_tiling))
	# a porta de um prédio novo (ou demolido) gasta (ou deixa crescer) o chão em frente dela
	EventBus.building_placed.connect(func(_id: int) -> void: _mark_all_masks())
	EventBus.building_removed.connect(func(_id: int) -> void: _mark_all_masks())


func chunk_count() -> int:
	return _chunks


## Máscara das estradas da ilha (Fase 38), ou null onde a terra continua ladrilho.
func road_mask(index: int) -> RoadMask:
	return _road_masks.get(index)


## Refaz já as máscaras marcadas (o normal é no quadro seguinte; os testes chamam direto).
func flush_road_masks() -> void:
	for index: int in _dirty_masks:
		_road_masks[index].refresh()
	_dirty_masks.clear()


func _mark_mask(index: int) -> void:
	if not _road_masks.has(index):
		return
	if _dirty_masks.is_empty():
		flush_road_masks.call_deferred()
	_dirty_masks[index] = true


func _mark_all_masks() -> void:
	for index: int in _road_masks:
		_mark_mask(index)


## Textura de dados da ilha (testes).
func data_image(index: int) -> Image:
	return _data_images.get(index)


## Liga ou desliga o hex-tiling (pelo nível gráfico).
func set_hex_tiling(enabled: bool) -> void:
	_hex_tiling = enabled
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter(&"hex_tiling", enabled)


func hex_tiling() -> bool:
	return _hex_tiling


## Os materiais do terreno, um por ilha (medida de custo, testes).
func materials() -> Array[ShaderMaterial]:
	return _materials


## Distância até a costa com sinal no arquipélago inteiro (Fase 35): a WaterView lê o mesmo mapa.
func coast_field() -> CoastField:
	return _coast


## Fase 56: as alturas desenhadas da região da ilha (com o detalhe das encostas), o lado e o canto dela; vazio na ilha
## plana. As rochas das falésias e dos rochedos (RockView) sentam nelas.
func region_heights(index: int) -> Dictionary:
	if not _regions.has(index):
		return {}
	var region: Dictionary = _regions[index]
	var origin: Vector2 = region["origin"]
	var side: int = region["side"]
	var heights: PackedFloat32Array = region["heights"]
	return {"heights": _with_detail(index, heights, side, origin), "side": side, "origin": origin}


## Altura desenhada num ponto (para conferir com a simulação): a mesma interpolação da grade, mais o detalhe visual
## das encostas (Fase 36, zero onde a simulação manda).
func shown_height(x: float, z: float) -> float:
	for grid: IslandGrid in _world.islands:
		if grid.world_rect().has_point(Vector2(x, z)):
			return _world.surface_height(x, z) + TerrainDetail.offset_at(grid, _config, x, z)
	return _world.surface_height(x, z)


func _build_island(index: int, textures: Dictionary[String, Texture2D]) -> void:
	var region := ArchipelagoGenerator.region_corners(_world, index, _config, _data)
	var side: int = region["side"]
	var origin: Vector2 = region["origin"]
	var heights: PackedFloat32Array = region["heights"]
	var surface: PackedByteArray = region["surface"]
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	for i: int in surface.size():
		image.set_pixel(i % side, i / side, _surface_color(surface[i]))
	_surface_images[index] = image
	_surfaces[index] = ImageTexture.create_from_image(image)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	for key: String in textures:
		material.set_shader_parameter(StringName(key), textures[key])
	material.set_shader_parameter(&"surface_weights", _surfaces[index])
	var size := (side - 1) * _config.cell_size_m
	material.set_shader_parameter(&"region_bounds", Vector4(origin.x, origin.y, size, size))
	# a distância até a água sai uma vez só: o bake e o campo da costa (Fase 35) a dividem
	var to_water := TerrainBake.distance_to_water(heights, side)
	_data_images[index] = TerrainBake.bake(heights, side, _config.cell_size_m, _config.terrain_water_distance_m, to_water)
	material.set_shader_parameter(&"terrain_data", ImageTexture.create_from_image(_data_images[index]))
	material.set_shader_parameter(&"hex_distance_m", _config.terrain_hex_distance_m)
	material.set_shader_parameter(&"hex_tiling", _hex_tiling)
	var coast := TerrainBake.signed_coast(heights, side, _config.cell_size_m, _config.coast_field_max_m)
	material.set_shader_parameter(&"coast_distance", ImageTexture.create_from_image(
			Image.create_from_data(side, side, false, Image.FORMAT_RF, coast.to_byte_array())))
	material.set_shader_parameter(&"has_coast", true)
	var grid := _world.island(index)
	if RoadMask.paints(grid, _config):
		var mask := RoadMask.new(_world, _data, index, _config.road_mask_px_per_cell, _config.road_mask_max_m)
		_road_masks[index] = mask
		material.set_shader_parameter(&"has_roads", true)
		material.set_shader_parameter(&"road_mask", mask.texture)
		material.set_shader_parameter(&"road_bounds", mask.bounds())
		material.set_shader_parameter(&"road_mask_max_m", _config.road_mask_max_m)
		material.set_shader_parameter(&"road_albedo", ROAD_ALBEDO)
		material.set_shader_parameter(&"road_normal", ROAD_NORMAL)
	_coast_regions.append({"origin": origin, "side": side, "coast": coast})
	_materials.append(material)
	_regions[index] = {"heights": heights, "side": side, "origin": origin}
	_detail_cells[index] = _cells_with_detail(index)
	_chunk_nodes[index] = {}
	var shown := _with_detail(index, heights, side, origin)
	for cy: int in range(0, side - 1, CHUNK_VERTICES):
		for cx: int in range(0, side - 1, CHUNK_VERTICES):
			var instance := MeshInstance3D.new()
			instance.mesh = _chunk_mesh(shown, side, origin, cx, cy)
			instance.material_override = material
			add_child(instance)
			_chunk_nodes[index][Vector2i(cx, cy)] = instance
			_chunks += 1


## Células da ilha com algum canto mexido pelo detalhe das encostas (só elas podem precisar de conserto).
func _cells_with_detail(index: int) -> PackedInt32Array:
	var grid := _world.island(index)
	var offsets := TerrainDetail.offsets(grid, _config)
	var width := grid.size.x + 1
	var marked: Dictionary[int, bool] = {}
	for corner: int in offsets.size():
		if offsets[corner] == 0.0:
			continue
		var x := corner % width
		var y := corner / width
		for cell: Vector2i in [Vector2i(x - 1, y - 1), Vector2i(x, y - 1), Vector2i(x - 1, y), Vector2i(x, y)]:
			if grid.in_bounds(cell):
				marked[grid.index(cell)] = true
	return PackedInt32Array(marked.keys())


## Estrada nova (ou prédio) numa célula com detalhe: os cantos dela voltam à altura da simulação e o trecho é refeito.
func _on_roads_changed(island_id: int) -> void:
	_mark_mask(island_id)
	if not _detail_cells.has(island_id):
		return
	var grid := _world.island(island_id)
	var region: Dictionary = _regions[island_id]
	var origin: Vector2 = region["origin"]
	var first := Vector2i(roundi((grid.origin_m.x - origin.x) / _config.cell_size_m),
			roundi((grid.origin_m.y - origin.y) / _config.cell_size_m))
	var dirty: Dictionary[Vector2i, bool] = {}
	var remaining := PackedInt32Array()
	for index: int in _detail_cells[island_id]:
		if grid.roads[index] == IslandGrid.Road.NONE and grid.occupancy[index] == 0:
			remaining.append(index)
			continue
		var cell := grid.cell_at(index)
		if TerrainDetail.zero_cell(grid, cell):
			# o trecho de cada canto da célula (um canto na borda pertence a dois trechos)
			for corner: Vector2i in [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i.ONE]:
				var at := first + corner
				for chunk_x: int in [at.x / CHUNK_VERTICES * CHUNK_VERTICES, (at.x - 1) / CHUNK_VERTICES * CHUNK_VERTICES]:
					for chunk_y: int in [at.y / CHUNK_VERTICES * CHUNK_VERTICES, (at.y - 1) / CHUNK_VERTICES * CHUNK_VERTICES]:
						dirty[Vector2i(chunk_x, chunk_y)] = true
	_detail_cells[island_id] = remaining
	if dirty.is_empty():
		return
	var heights: PackedFloat32Array = region["heights"]
	var side: int = region["side"]
	var shown := _with_detail(island_id, heights, side, origin)
	for chunk: Vector2i in dirty:
		var node: MeshInstance3D = _chunk_nodes[island_id].get(chunk)
		if node != null:
			node.mesh = _chunk_mesh(shown, side, origin, chunk.x, chunk.y)


## As alturas da região com o detalhe visual das encostas (TerrainDetail) nos cantos que caem na grade da ilha.
func _with_detail(index: int, heights: PackedFloat32Array, side: int, origin: Vector2) -> PackedFloat32Array:
	var grid := _world.island(index)
	var offsets := TerrainDetail.offsets(grid, _config)
	var shown := heights.duplicate()
	var first := Vector2i(roundi((grid.origin_m.x - origin.x) / _config.cell_size_m),
			roundi((grid.origin_m.y - origin.y) / _config.cell_size_m))
	var width := grid.size.x + 1
	for gy: int in grid.size.y + 1:
		for gx: int in width:
			var offset := offsets[gy * width + gx]
			if offset != 0.0:
				shown[(first.y + gy) * side + first.x + gx] += offset
	return shown


## Malha de um trecho: vértices nos cantos (x, z de 2 em 2 m) com a normal pelas alturas vizinhas; cada quadrado pela
## diagonal que segue o relevo, e os da linha d'água (Fase 55) e da face da falésia (Fase 62) mais finos.
func _chunk_mesh(heights: PackedFloat32Array, side: int, origin: Vector2, cx: int, cy: int) -> ArrayMesh:
	var spacing := _config.cell_size_m
	var count_x := mini(CHUNK_VERTICES, side - 1 - cx) + 1
	var count_y := mini(CHUNK_VERTICES, side - 1 - cy) + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.resize(count_x * count_y)
	normals.resize(count_x * count_y)
	for y: int in count_y:
		for x: int in count_x:
			var gx := cx + x
			var gy := cy + y
			var h := heights[gy * side + gx]
			vertices[y * count_x + x] = Vector3(origin.x + gx * spacing, h, origin.y + gy * spacing)
			normals[y * count_x + x] = CoastRefine.corner_normal(heights, side, gx, gy, spacing)
	# Fase 55: o quadrado que a linha d'água atravessa vira uma subgrade mais fina (CoastRefine); Fase 62: e o da face
	# seca da falésia
	var n := _config.terrain_coast_subdivisions
	var relief := _config.terrain_cliff_refine_relief_m
	for y: int in count_y - 1:
		for x: int in count_x - 1:
			if n > 1 and CoastRefine.refines(heights, side, cx + x, cy + y, relief):
				_refined_quad(heights, side, origin, cx + x, cy + y, n, vertices, normals, indices)
				continue
			var a := y * count_x + x
			_append_quad(vertices, indices, a, a + 1, a + count_x, a + count_x + 1)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Fase 54: o quadrado (a b / c d) se divide pela diagonal de menor diferença de altura (a que segue o relevo); com a
## diagonal sempre igual, a costa e a falésia que correm na outra diagonal viravam escada.
static func _append_quad(vertices: PackedVector3Array, indices: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	if absf(vertices[a].y - vertices[d].y) < absf(vertices[b].y - vertices[c].y):
		indices.append_array(PackedInt32Array([a, b, d, a, d, c]))
	else:
		indices.append_array(PackedInt32Array([a, b, c, b, d, c]))


## Fase 55: subgrade de n × n no quadrado de canto (gx, gy); na borda com um quadrado que não se divide, a altura fica
## na reta do vizinho. Fase 62: com a aspereza da falésia, e a normal dos pontos novos pelas alturas da subgrade em
## volta (a rocha partida aparece na luz); nos cantos da grade, a normal de sempre (contínua com o resto da malha).
func _refined_quad(heights: PackedFloat32Array, side: int, origin: Vector2, gx: int, gy: int, n: int,
		vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
	var spacing := _config.cell_size_m
	var max_m := _config.terrain_coast_refine_max_m
	var relief := _config.terrain_cliff_refine_relief_m
	var rough := _config.terrain_cliff_rough_m
	var linear_left := not CoastRefine.refines(heights, side, gx - 1, gy, relief)
	var linear_right := not CoastRefine.refines(heights, side, gx + 1, gy, relief)
	var linear_up := not CoastRefine.refines(heights, side, gx, gy - 1, relief)
	var linear_down := not CoastRefine.refines(heights, side, gx, gy + 1, relief)
	var step := spacing / n
	var first := vertices.size()
	for j: int in n + 1:
		for i: int in n + 1:
			var linear := (i == 0 and linear_left) or (i == n and linear_right) or (j == 0 and linear_up) \
					or (j == n and linear_down)
			var sx := gx * n + i
			var sy := gy * n + j
			var h := CoastRefine.height(heights, side, sx, sy, n, max_m, linear, rough, relief)
			vertices.append(Vector3(origin.x + float(sx) / n * spacing, h, origin.y + float(sy) / n * spacing))
			if (i == 0 or i == n) and (j == 0 or j == n):
				normals.append(CoastRefine.corner_normal(heights, side, gx + (1 if i == n else 0), gy + (1 if j == n else 0),
						spacing))
				continue
			var left := CoastRefine.height(heights, side, maxi(sx - 1, 0), sy, n, max_m, false, rough, relief)
			var right := CoastRefine.height(heights, side, sx + 1, sy, n, max_m, false, rough, relief)
			var up := CoastRefine.height(heights, side, sx, maxi(sy - 1, 0), n, max_m, false, rough, relief)
			var down := CoastRefine.height(heights, side, sx, sy + 1, n, max_m, false, rough, relief)
			normals.append(Vector3(left - right, 2.0 * step, up - down).normalized())
	for j: int in n:
		for i: int in n:
			var a := first + j * (n + 1) + i
			_append_quad(vertices, indices, a, a + 1, a + n + 1, a + n + 2)


static func _surface_color(kind: int) -> Color:
	match kind:
		ArchipelagoGenerator.Surface.SAND:
			return Color(1.0, 0.0, 0.0)
		ArchipelagoGenerator.Surface.FOREST:
			return Color(0.0, 1.0, 0.0)
		ArchipelagoGenerator.Surface.MUD:
			return Color(0.0, 0.0, 1.0)
	return Color(0.0, 0.0, 0.0)


## Derrubar árvores tira o chão de floresta da área.
func _on_trees_changed(island_id: int, area: Rect2i) -> void:
	if not _surface_images.has(island_id):
		return
	var grid := _world.island(island_id)
	var image := _surface_images[island_id]
	var region := ArchipelagoGenerator.world_specs(_world, _config, _data)[island_id].region
	var first := Vector2i((grid.origin_m - Vector2(region) * _config.terrain_region_m) / _config.cell_size_m)
	for y: int in range(area.position.y, area.end.y + 1):
		for x: int in range(area.position.x, area.end.x + 1):
			var pixel := first + Vector2i(x, y)
			if pixel.x < image.get_width() and pixel.y < image.get_height() and image.get_pixelv(pixel).g > 0.5:
				image.set_pixelv(pixel, _surface_color(ArchipelagoGenerator.Surface.AUTO))
	_surfaces[island_id].update(image)
