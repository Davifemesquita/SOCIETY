class_name CropView
extends Node3D
## Plantações nos campos (Fase 14): o campo que tem dono ganha fileiras da planta da fazenda dele
## (BuildingDef.crop), crescendo com o ciclo da fazenda (BuildingRecord.progress): curta e verde no começo,
## alta (e dourada, no cereal) perto da colheita. Campo sem dono fica só a terra arada. Desde a Fase 19, a
## terra arada tem leiras (uma por fileira, pela planta da fazenda), escuras e úmidas logo depois de lavrada e
## secando até a colheita; o campo sem dono fica com as leiras secas. As plantas são
## geradas aqui (cor no vértice), um MultiMesh por planta; o crescimento reescreve só as instâncias do
## campo que mudou. Os pastos (de dono ou não) ganham cerca de madeira em volta (menos do lado que encosta
## em outro pasto: viram um cercado só) e touceiras de capim. Só lê o mundo.

## Campos em colcha (Fase 40): o campo deixou de ser a caixa marrom da BuildingView. A terra lavrada é um polígono que
## segue o terreno, recuado da borda do lote com um ruído semeado pela linha da divisa (os dois vizinhos ondulam igual:
## sem fresta nem invasão); as fileiras correm em x ou em z pela posição do campo na grade de 3 células (vizinhos
## alinhados nunca na mesma direção), com cabeceira nas pontas; cada campo tem o seu tom de terra e de planta; sebe
## (ou muro de pedra seca no lote em encosta) em cada divisa, uma vez por aresta, com a porteira na entrada; nada disso
## nas ilhas tropicais (proposta à espera do dono). O pasto também perdeu a caixa: cerca e capim ficam no chão.

const REFRESH_SECONDS := 0.5
## O crescimento anda em degraus (menos reescrita), e a planta nova já aparece com este tamanho.
const GROWTH_STEPS := 20
const MIN_GROWTH := 0.25
## Folga das plantas até a borda do campo (passa do recuo máximo do contorno) e quanto cada uma sai do lugar da grade.
const MARGIN_M := 0.65
const JITTER_M := 0.08
## Cereal verde no começo do ciclo (a cor da instância multiplica a do vértice).
const GREEN_TINT := Color(0.55, 1.0, 0.45)

## Leiras (Fase 19): altura, quanto da fileira cada uma ocupa, espaço no campo sem dono e a cor da terra
## lavrada (úmida) e seca.
const FURROW_HEIGHT_M := 0.13
const FURROW_FILL := 0.7
const BARE_SPACING_M := 0.75
const FRESH_SOIL := Color(0.25, 0.17, 0.1)
const DRY_SOIL := Color(0.58, 0.46, 0.32)

## Pasto: lanço de cerca (m), folga da cerca até a borda e touceiras de capim por célula.
const PASTURE := &"pasture"
const FENCE_STEP_M := 1.0
const FENCE_INSET_M := 0.12
const TUFTS_PER_CELL := 5
## Balanço ao vento (Fase 22; m por m de altura, como o das árvores) das plantas e do capim, e a
## velocidade dele (mais curta que a da árvore).
const PLANT_SWAY := 0.09
const GRASS_SWAY := 0.14
const PLANT_SWAY_SPEED := 2.1

## Fase 40: contorno (recuo mínimo e ondulação, em m, e o passo do ruído ao longo da divisa), altura da terra sobre o
## terreno, cabeceira nas pontas das fileiras, tons da terra e da planta por campo, peças de sebe e de muro por metro de
## divisa e o desnível do lote que troca a sebe pelo muro.
const FIELD_INSET_M := 0.22
const FIELD_WIGGLE_M := 0.36
const WIGGLE_STEP_M := 1.4
const BORDER_SAMPLE_M := 0.5
const SOIL_M := 0.05
const HEADLAND_M := 0.95
const FIELD_SOILS: Array[Color] = [Color(0.45, 0.34, 0.22), Color(0.38, 0.28, 0.18), Color(0.5, 0.39, 0.26),
		Color(0.42, 0.33, 0.24)]
const FIELD_SHADES: Array[Color] = [Color(1.0, 1.0, 1.0), Color(0.9, 0.95, 0.85), Color(1.08, 1.04, 0.92),
		Color(0.95, 1.05, 0.95)]
const BORDER_PIECE_M := 1.0
const WALL_RELIEF_M := 0.3
const HEDGE_COLOR := Color(0.24, 0.36, 0.16)
const WALL_COLOR := Color(0.55, 0.53, 0.48)

## Por planta: espaço entre plantas na fileira e entre fileiras (m).
const SPACING := {
	BuildingDef.Crop.GRAIN: Vector2(0.45, 0.45),
	BuildingDef.Crop.TUBER: Vector2(0.6, 0.75),
	BuildingDef.Crop.HOPS: Vector2(1.2, 1.5),
	BuildingDef.Crop.VINE: Vector2(0.9, 1.5),
	BuildingDef.Crop.CANE: Vector2(0.6, 0.8),
	BuildingDef.Crop.BUSH: Vector2(1.1, 1.2),
	BuildingDef.Crop.BROADLEAF: Vector2(0.8, 0.9),
}

var _simulation: Simulation
var _layers: Dictionary[int, MultiMeshInstance3D] = {}
var _fence := MultiMeshInstance3D.new()
var _grass := MultiMeshInstance3D.new()
var _furrows := MultiMeshInstance3D.new()
## Fase 40: a terra de todos os campos numa malha só, as sebes e os muros.
var _soil := MeshInstance3D.new()
var _hedges := MultiMeshInstance3D.new()
var _walls := MultiMeshInstance3D.new()
var _soil_cache: Dictionary[String, PackedVector3Array] = {}
var _place_cache: Dictionary[String, Array] = {}
## Por campo: [planta, primeira instância, quantidade, lugares (Array[Transform3D]), id da fazenda, primeira
## leira, quantidade de leiras].
var _fields: Dictionary[int, Array] = {}
var _growth: Dictionary[int, int] = {}
var _range_m: float = 260.0
var _refresh_left: float = 0.0
var _dirty: bool = false

static var _meshes: Dictionary[int, ArrayMesh] = {}


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	for crop: int in SPACING:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = plant_mesh(crop)
		multimesh.visible_instance_count = 0
		var layer := MultiMeshInstance3D.new()
		layer.name = "Crop%d" % crop
		layer.multimesh = multimesh
		layer.material_override = plant_material(multimesh.mesh, PLANT_SWAY)
		add_child(layer)
		_layers[crop] = layer
	_soil.name = "Soil"
	_soil.material_override = material
	add_child(_soil)
	for pair: Array in [[_fence, "Fence", fence_mesh()], [_grass, "Grass", tuft_mesh()], [_furrows, "Furrows", furrow_mesh()],
			[_hedges, "Hedges", hedge_mesh()], [_walls, "Walls", wall_mesh()]]:
		var layer: MultiMeshInstance3D = pair[0]
		var name_text: String = pair[1]
		var mesh: ArrayMesh = pair[2]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = mesh
		multimesh.visible_instance_count = 0
		layer.name = name_text
		layer.multimesh = multimesh
		# o capim balança ao vento; a cerca e as leiras, não
		layer.material_override = plant_material(mesh, GRASS_SWAY) if layer == _grass else material
		if layer in [_hedges, _walls]:
			# milhares de peças: sem sombra
			layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(layer)
	_apply_range()
	EventBus.building_placed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.building_removed.connect(func(_building_id: int) -> void: _dirty = true)
	EventBus.world_replaced.connect(func() -> void:
		_soil_cache.clear()
		_place_cache.clear()
		rebuild())
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	_apply_range()


## Plantas à vista de uma planta (BuildingDef.Crop) ou de todas (-1).
func plant_count(crop: int = -1) -> int:
	var total := 0
	for kind: int in _layers:
		if crop < 0 or kind == crop:
			total += _layers[kind].multimesh.visible_instance_count
	return total


## Lanços de cerca e touceiras de capim à vista (todos os pastos).
func fence_count() -> int:
	return _fence.multimesh.visible_instance_count


func tuft_count() -> int:
	return _grass.multimesh.visible_instance_count


## Leiras à vista (todos os campos) e a cor de uma delas.
func furrow_count() -> int:
	return _furrows.multimesh.visible_instance_count


func furrow_color(index: int) -> Color:
	return _furrows.multimesh.get_instance_color(index)


func furrow_transform(index: int) -> Transform3D:
	return _furrows.multimesh.get_instance_transform(index)


func fence_transform(index: int) -> Transform3D:
	return _fence.multimesh.get_instance_transform(index)


## Fase 40: peças de sebe e de muro à vista (todas as divisas) e a malha da terra dos campos.
func hedge_count() -> int:
	return _hedges.multimesh.visible_instance_count


func wall_count() -> int:
	return _walls.multimesh.visible_instance_count


func hedge_transform(index: int) -> Transform3D:
	return _hedges.multimesh.get_instance_transform(index)


func soil_mesh() -> ArrayMesh:
	return _soil.mesh as ArrayMesh


## Quanto o campo cresceu (0..1, em degraus); -1 se ele não tem plantas.
func growth_of(field_id: int) -> float:
	return float(_growth[field_id]) / GROWTH_STEPS if _growth.has(field_id) else -1.0


## Lugar da planta index do campo (mundo), já com o tamanho do crescimento.
func plant_transform(field_id: int, index: int) -> Transform3D:
	var field: Array = _fields[field_id]
	var crop: int = field[0]
	var first: int = field[1]
	return _layers[crop].multimesh.get_instance_transform(first + index)


func _process(delta: float) -> void:
	if _dirty:
		rebuild()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()


## Refaz a grade de plantas de todos os campos com dono.
func rebuild() -> void:
	_dirty = false
	_fields.clear()
	_growth.clear()
	var world := _simulation.world
	var derived := _simulation.derived_state()
	var lists: Dictionary[int, Array] = {}
	for crop: int in _layers:
		lists[crop] = []
	var fences: Array = []
	var tufts: Array = []
	var furrows: Array = []
	var hedges: Array = []
	var walls: Array = []
	var soil_vertices := PackedVector3Array()
	var soil_colors := PackedColorArray()
	var borders: Dictionary[Vector3i, bool] = {}
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if def.kind != BuildingDef.Kind.MODULE:
			continue
		if def.id == PASTURE:
			_pasture(record, def, fences, tufts)
			continue
		_add_soil(soil_vertices, soil_colors, record, def)
		_add_borders(record, def, borders, hedges, walls)
		var owner_id: int = derived.module_owner.get(building_id, 0)
		var farm := world.building(owner_id)
		var crop := _simulation.def_of(farm).crop if farm != null else -1
		if not _layers.has(crop):
			for place: Transform3D in _cached_furrows(record, def, BARE_SPACING_M):
				furrows.append([place, DRY_SOIL])
			continue
		var places := _cached_plants(record, def, crop)
		var spacing: Vector2 = SPACING[crop]
		var rows := _cached_furrows(record, def, spacing.y)
		var list: Array = lists[crop]
		_fields[building_id] = [crop, list.size(), places.size(), places, owner_id, furrows.size(), rows.size()]
		list.append_array(places)
		for place: Transform3D in rows:
			furrows.append([place, DRY_SOIL])
	for crop: int in lists:
		var multimesh := _layers[crop].multimesh
		var count: int = lists[crop].size()
		if multimesh.instance_count < count:
			multimesh.visible_instance_count = -1
			multimesh.instance_count = count + 64
		multimesh.visible_instance_count = count
	if soil_vertices.is_empty():
		_soil.mesh = null
	else:
		# a terra é quase plana (o lote tem no máximo meio metro de desnível): normal para cima
		var normals := PackedVector3Array()
		normals.resize(soil_vertices.size())
		normals.fill(Vector3.UP)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = soil_vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = soil_colors
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_soil.mesh = mesh
	for pair: Array in [[_fence, fences], [_grass, tufts], [_furrows, furrows], [_hedges, hedges], [_walls, walls]]:
		var layer: MultiMeshInstance3D = pair[0]
		var multimesh := layer.multimesh
		var items: Array = pair[1]
		if multimesh.instance_count < items.size():
			multimesh.visible_instance_count = -1
			multimesh.instance_count = items.size() + 64
		multimesh.visible_instance_count = items.size()
		for index: int in items.size():
			var item: Array = items[index]
			var place: Transform3D = item[0]
			var color: Color = item[1]
			multimesh.set_instance_transform(index, place)
			multimesh.set_instance_color(index, color)
	for field_id: int in _fields:
		_draw_field(field_id)


## A cerca em volta do pasto (lanços de FENCE_STEP_M, de canto a canto, por dentro da borda) e o capim.
## O lado que encosta em outro pasto fica aberto.
func _pasture(record: BuildingRecord, def: BuildingDef, fences: Array, tufts: Array) -> void:
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var cell_size := _simulation.config.cell_size_m
	# no chão (Fase 40: o pasto não tem mais a caixa verde por baixo)
	var center := grid.rect_world(area)
	var low := center - Vector3(area.size.x, 0.0, area.size.y) * cell_size * 0.5
	var wood := Color(0.48, 0.36, 0.24)
	# [célula do canto inicial, passo ao longo da borda, vizinho de fora, giro do lanço, onde começa]
	var sides := [
		[area.position, Vector2i(1, 0), Vector2i(0, -1), 0.0, Vector3(FENCE_INSET_M, 0.0, FENCE_INSET_M)],
		[Vector2i(area.position.x, area.end.y - 1), Vector2i(1, 0), Vector2i(0, 1), 0.0,
				Vector3(FENCE_INSET_M, 0.0, area.size.y * cell_size - FENCE_INSET_M)],
		[area.position, Vector2i(0, 1), Vector2i(-1, 0), -PI * 0.5, Vector3(FENCE_INSET_M, 0.0, FENCE_INSET_M)],
		[Vector2i(area.end.x - 1, area.position.y), Vector2i(0, 1), Vector2i(1, 0), -PI * 0.5,
				Vector3(area.size.x * cell_size - FENCE_INSET_M, 0.0, FENCE_INSET_M)],
	]
	for side: Array in sides:
		var corner: Vector2i = side[0]
		var along: Vector2i = side[1]
		var outward: Vector2i = side[2]
		var turn: float = side[3]
		var start: Vector3 = side[4]
		var count := area.size.x if along.x != 0 else area.size.y
		var direction := Vector3(along.x, 0.0, along.y)
		for step: int in count:
			var outside := corner + along * step + outward
			if grid.in_bounds(outside):
				var neighbor := _simulation.world.building(grid.building_at(outside))
				if neighbor != null and neighbor.def_id == PASTURE:
					continue
			for piece: int in roundi(cell_size / FENCE_STEP_M):
				# o último lanço da borda fica mais curto: não passa da folga do outro canto
				var from := step * cell_size + piece * FENCE_STEP_M
				var length := minf(FENCE_STEP_M, count * cell_size - 2.0 * FENCE_INSET_M - from)
				if length <= 0.01:
					continue
				var origin := low + start + direction * from
				origin.y = grid.height_at(origin.x, origin.z)
				fences.append([Transform3D(Basis(Vector3.UP, turn).scaled_local(Vector3(length, 1.0, 1.0)), origin), wood])
	for i: int in area.size.x * area.size.y * TUFTS_PER_CELL:
		var random := RandomNumberGenerator.new()
		random.seed = hash([record.id, &"tuft", i])
		var point := low + Vector3(random.randf_range(0.3, area.size.x * cell_size - 0.3), 0.0,
				random.randf_range(0.3, area.size.y * cell_size - 0.3))
		point.y = grid.height_at(point.x, point.z)
		var shade := random.randf_range(0.8, 1.15)
		tufts.append([Transform3D(Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3.ONE * random.randf_range(0.7, 1.3)),
				point), Color(shade, shade, shade)])


## Confere o ciclo de cada fazenda e redesenha os campos que cresceram (ou foram colhidos).
func refresh() -> void:
	for field_id: int in _fields:
		var field: Array = _fields[field_id]
		var farm_id: int = field[4]
		var farm := _simulation.world.building(farm_id)
		if farm == null:
			_dirty = true
			return
		if _step(farm) != _growth.get(field_id, -1):
			_draw_field(field_id)


func _step(farm: BuildingRecord) -> int:
	return clampi(roundi(farm.progress * GROWTH_STEPS), 0, GROWTH_STEPS)


func _draw_field(field_id: int) -> void:
	var field: Array = _fields[field_id]
	var crop: int = field[0]
	var first: int = field[1]
	var places: Array = field[3]
	var farm_id: int = field[4]
	var farm := _simulation.world.building(farm_id)
	var step := _step(farm)
	_growth[field_id] = step
	var growth := lerpf(MIN_GROWTH, 1.0, float(step) / GROWTH_STEPS)
	var size := Vector3(lerpf(0.6, 1.0, growth), growth, lerpf(0.6, 1.0, growth))
	var tint := GREEN_TINT.lerp(Color.WHITE, float(step) / GROWTH_STEPS) if crop == BuildingDef.Crop.GRAIN else Color.WHITE
	tint *= field_shade(field_id)
	var multimesh := _layers[crop].multimesh
	for index: int in places.size():
		var place: Transform3D = places[index]
		multimesh.set_instance_transform(first + index, Transform3D(place.basis.scaled_local(size), place.origin))
		multimesh.set_instance_color(first + index, tint)
	var soil := FRESH_SOIL.lerp(DRY_SOIL, float(step) / GROWTH_STEPS)
	var first_furrow: int = field[5]
	var furrow_total: int = field[6]
	for index: int in furrow_total:
		_furrows.multimesh.set_instance_color(first_furrow + index, soil)


## Lugares das plantas no campo (mundo, tamanho cheio): fileiras pelo espaço da planta, com a folga da
## borda, um pouco tortas e giradas pelo id (o mesmo depois de carregar).
func _plant_places(record: BuildingRecord, def: BuildingDef, crop: int) -> Array:
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var frame := _row_frame(record)
	var cell_size := _simulation.config.cell_size_m
	# u ao longo das fileiras (sem a cabeceira das pontas), v de uma fileira à outra
	var half := Vector2(area.size) * cell_size * 0.5 - Vector2(HEADLAND_M, MARGIN_M)
	var spacing: Vector2 = SPACING[crop]
	var columns := maxi(1, floori(half.x * 2.0 / spacing.x) + 1)
	var rows := maxi(1, floori(half.y * 2.0 / spacing.y) + 1)
	var start := Vector2(-(columns - 1) * spacing.x * 0.5, -(rows - 1) * spacing.y * 0.5)
	var result: Array = []
	for row: int in rows:
		for column: int in columns:
			var noise := hash([record.id, row, column])
			var jitter := Vector2(float(noise % 1000) / 1000.0 - 0.5, float(noise / 1000 % 1000) / 1000.0 - 0.5) * 2.0 * JITTER_M
			var turn := float(noise / 1000000 % 628) / 100.0
			# parreira e lúpulo seguem a fileira: giro só de meia volta
			if crop in [BuildingDef.Crop.VINE, BuildingDef.Crop.HOPS]:
				turn = PI * float(noise % 2)
			var offset := start + Vector2(column * spacing.x, row * spacing.y) + jitter
			var point := center + frame * Vector3(offset.x, 0.0, offset.y)
			point.y = grid.height_at(point.x, point.z) + SOIL_M
			result.append(Transform3D(frame * Basis(Vector3.UP, turn), point))
	return result


## Os lugares das plantas e das leiras seguem o terreno (Fase 40): ficam em cache pelo lote e pelo espaçamento, e refazer
## a vista a cada obra não recalcula a altura de milhares de plantas.
func _cached_plants(record: BuildingRecord, def: BuildingDef, crop: int) -> Array:
	var key := "p|%d|%s|%d|%d" % [record.id, record.origin, record.rotation, crop]
	if not _place_cache.has(key):
		_place_cache[key] = _plant_places(record, def, crop)
	return _place_cache[key]


func _cached_furrows(record: BuildingRecord, def: BuildingDef, spacing: float) -> Array:
	var key := "f|%d|%s|%d|%.2f" % [record.id, record.origin, record.rotation, spacing]
	if not _place_cache.has(key):
		_place_cache[key] = _furrow_places(record, def, spacing)
	return _place_cache[key]


## Leiras do campo (mundo): uma por fileira de `spacing` m ao longo da direção do campo, sem a cabeceira, e uma
## atravessada em cada cabeceira; inclinadas com o terreno.
func _furrow_places(record: BuildingRecord, def: BuildingDef, spacing: float) -> Array:
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var center := grid.rect_world(area)
	var frame := _row_frame(record)
	var cell_size := _simulation.config.cell_size_m
	var half := Vector2(area.size) * cell_size * 0.5 - Vector2(HEADLAND_M, MARGIN_M)
	var rows := maxi(1, floori(half.y * 2.0 / spacing) + 1)
	var start := -(rows - 1) * spacing * 0.5
	var result: Array = []
	for row: int in rows:
		result.append(_furrow(grid, center + frame * Vector3(0.0, 0.0, start + row * spacing), frame, half.x * 2.0,
				spacing * FURROW_FILL))
	# a cabeceira: o arado vira ali, e a leira corre de través
	var across := frame * Basis(Vector3.UP, PI * 0.5)
	var headland := half.x + (HEADLAND_M - MARGIN_M * 0.5) * 0.5
	for side: float in [-1.0, 1.0]:
		result.append(_furrow(grid, center + frame * Vector3(side * headland, 0.0, 0.0), across, half.y * 2.0, 0.5))
	return result


## Leira de "length" × "width" no meio "point", na direção x de "frame", acompanhando o terreno nas duas pontas.
static func _furrow(grid: IslandGrid, point: Vector3, frame: Basis, length: float, width: float) -> Transform3D:
	var along := frame.x.normalized()
	var a := point - along * length * 0.5
	var b := point + along * length * 0.5
	var low := grid.height_at(a.x, a.z)
	var high := grid.height_at(b.x, b.z)
	var pitch := atan2(high - low, length)
	var basis := frame * Basis(Vector3.BACK, pitch) * Basis.from_scale(Vector3(length, 1.0, width))
	return Transform3D(basis, Vector3(point.x, (low + high) * 0.5 + SOIL_M * 0.5, point.z))


## Direção das fileiras do campo (Fase 40): em x ou em z pela posição na grade de 3 células — dois campos vizinhos
## alinhados (a 3 células) nunca correm na mesma direção.
static func rows_along_x(record: BuildingRecord) -> bool:
	return posmod(floori(record.origin.x / 3.0) + floori(record.origin.y / 3.0), 2) == 0


static func _row_frame(record: BuildingRecord) -> Basis:
	return Basis.IDENTITY if rows_along_x(record) else Basis(Vector3.UP, PI * 0.5)


## Tom da planta do campo (multiplica a cor da instância) e da terra, pelo id.
static func field_shade(field_id: int) -> Color:
	return FIELD_SHADES[absi(hash([field_id, &"shade"])) % FIELD_SHADES.size()]


static func field_soil(field_id: int) -> Color:
	return FIELD_SOILS[absi(hash([field_id, &"soil"])) % FIELD_SOILS.size()]


## Recuo do contorno (m) num ponto da divisa: o ruído é da linha (vertical em x = line ou horizontal em z = line, pela
## chave) e da posição ao longo dela, então os dois campos de uma divisa recuam igual.
static func border_inset(vertical: bool, line: float, along: float) -> float:
	var key := hash([vertical, roundi(line * 10.0)])
	var t := along / WIGGLE_STEP_M
	var i := floori(t)
	var f := t - i
	f = f * f * (3.0 - 2.0 * f)
	var a := float(absi(hash([key, i])) % 1000) / 1000.0
	var b := float(absi(hash([key, i + 1])) % 1000) / 1000.0
	return FIELD_INSET_M + FIELD_WIGGLE_M * lerpf(a, b, f)


## O contorno do campo (mundo, xz), em volta: cantos e pontos a cada BORDER_SAMPLE_M, recuados pela divisa.
func field_outline(record: BuildingRecord, def: BuildingDef) -> PackedVector2Array:
	var grid := _simulation.world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var cell := grid.cell_size
	var x0 := grid.origin_m.x + area.position.x * cell
	var z0 := grid.origin_m.y + area.position.y * cell
	var x1 := grid.origin_m.x + area.end.x * cell
	var z1 := grid.origin_m.y + area.end.y * cell
	var points := PackedVector2Array()
	# [canto de partida, direção, normal para dentro, divisa vertical?, linha]
	var sides := [
		[Vector2(x0, z0), Vector2(1, 0), Vector2(0, 1), false, z0],
		[Vector2(x1, z0), Vector2(0, 1), Vector2(-1, 0), true, x1],
		[Vector2(x1, z1), Vector2(-1, 0), Vector2(0, -1), false, z1],
		[Vector2(x0, z1), Vector2(0, -1), Vector2(1, 0), true, x0],
	]
	for k: int in 4:
		var side: Array = sides[k]
		var corner: Vector2 = side[0]
		var step: Vector2 = side[1]
		var inward: Vector2 = side[2]
		var vertical: bool = side[3]
		var line: float = side[4]
		var previous: Array = sides[(k + 3) % 4]
		var prev_inward: Vector2 = previous[2]
		var prev_vertical: bool = previous[3]
		var prev_line: float = previous[4]
		# o canto recua das duas divisas
		var corner_along := corner.y if vertical else corner.x
		var prev_along := corner.y if prev_vertical else corner.x
		points.append(corner + inward * border_inset(vertical, line, corner_along)
				+ prev_inward * border_inset(prev_vertical, prev_line, prev_along))
		var length := absf((x1 - x0) if step.x != 0.0 else (z1 - z0))
		var t := 0.75
		while t <= length - 0.75 + 0.001:
			var p := corner + step * t
			points.append(p + inward * border_inset(vertical, line, p.y if vertical else p.x))
			t += BORDER_SAMPLE_M
	return points


## A terra lavrada do campo: o contorno em três anéis até o meio, cada vértice na altura do terreno. Os triângulos de
## cada campo ficam em cache pelo lote (o terreno debaixo de um prédio não muda): refazer a vista só junta as listas.
func _add_soil(vertices: PackedVector3Array, colors: PackedColorArray, record: BuildingRecord, def: BuildingDef) -> void:
	var key := "%d|%s|%d" % [record.id, record.origin, record.rotation]
	if not _soil_cache.has(key):
		_soil_cache[key] = _soil_triangles(record, def)
	var own: PackedVector3Array = _soil_cache[key]
	var start := vertices.size()
	vertices.append_array(own)
	colors.resize(vertices.size())
	var color := field_soil(record.id)
	for i: int in range(start, vertices.size()):
		colors[i] = color


func _soil_triangles(record: BuildingRecord, def: BuildingDef) -> PackedVector3Array:
	var grid := _simulation.world.island(record.island_id)
	var outline := field_outline(record, def)
	var middle := Vector2.ZERO
	for p: Vector2 in outline:
		middle += p
	middle /= outline.size()
	var rings: Array[float] = [1.0, 0.66, 0.33]
	var count := outline.size()
	# os vértices de cada anel, uma vez (o último anel é o meio)
	var lifted: Array[PackedVector3Array] = []
	for outer: float in rings:
		var ring := PackedVector3Array()
		ring.resize(count)
		for i: int in count:
			ring[i] = _lift(grid, middle + (outline[i] - middle) * outer)
		lifted.append(ring)
	var center := _lift(grid, middle)
	var result := PackedVector3Array()
	for i: int in count:
		var j := (i + 1) % count
		for r: int in rings.size():
			var a_out := lifted[r][i]
			var b_out := lifted[r][j]
			if r + 1 < rings.size():
				_soil_triangle(result, a_out, b_out, lifted[r + 1][j])
				_soil_triangle(result, a_out, lifted[r + 1][j], lifted[r + 1][i])
			else:
				_soil_triangle(result, a_out, b_out, center)
	return result


static func _lift(grid: IslandGrid, p: Vector2) -> Vector3:
	return Vector3(p.x, grid.height_at(p.x, p.y) + SOIL_M, p.y)


## Triângulo de frente para cima (o Godot vê a frente no sentido horário).
static func _soil_triangle(into: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	into.append(a)
	if (b - a).cross(c - a).y < 0.0:
		into.append(b)
		into.append(c)
	else:
		into.append(c)
		into.append(b)


## Sebe (ou muro, no lote em encosta) em cada divisa de célula do campo, uma vez por aresta (a chave é a célula do lado
## de menor coordenada e o eixo), menos a da porteira (a célula da entrada), a que dá para outro pasto (já tem cerca) e
## a da água; nada nas ilhas tropicais.
func _add_borders(record: BuildingRecord, def: BuildingDef, seen: Dictionary[Vector3i, bool], hedges: Array,
		walls: Array) -> void:
	var world := _simulation.world
	if world.is_tropical(record.island_id, _simulation.data):
		return
	var grid := world.island(record.island_id)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var gate := Footprint.entrance_cell(record.origin, def.size, record.rotation)
	var span := BuildingKit.corner_range(grid, area)
	var stone := not grid.corner_heights.is_empty() and span.y - span.x > WALL_RELIEF_M
	var owners := _simulation.derived_state().module_owner
	var owner_id: int = owners.get(record.id, 0)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var outside := cell + step
				if area.has_point(outside) or outside == gate:
					continue
				var low := cell if step.x + step.y > 0 else outside
				var key := Vector3i(low.x, low.y, 0 if step.x != 0 else 1)
				if seen.has(key):
					continue
				seen[key] = true
				if grid.in_bounds(outside) and grid.ground_at(outside) != IslandGrid.Ground.LAND:
					continue
				var neighbor := world.building(grid.building_at(outside))
				if neighbor != null and neighbor.def_id == PASTURE:
					continue
				# os campos da mesma fazenda são um cercado só: a sebe é a da volta toda (senão cada campo vira um
				# quadradinho emoldurado)
				if neighbor != null and owner_id != 0 and (owners.get(neighbor.id, 0) == owner_id or neighbor.id == owner_id):
					continue
				_border_pieces(grid, cell, step, stone, hedges, walls)


## As peças de BORDER_PIECE_M ao longo da divisa entre "cell" e a vizinha em "step", no chão.
func _border_pieces(grid: IslandGrid, cell: Vector2i, step: Vector2i, stone: bool, hedges: Array, walls: Array) -> void:
	var cell_size := grid.cell_size
	var middle := grid.cell_world(cell) + Vector3(step.x, 0.0, step.y) * cell_size * 0.5
	var along := Vector3(absf(step.y), 0.0, absf(step.x))
	var count := roundi(cell_size / BORDER_PIECE_M)
	for k: int in count:
		var point := middle + along * ((k + 0.5) / count - 0.5) * cell_size
		point.y = grid.height_at(point.x, point.z)
		var noise := absi(hash(Vector2i(roundi(point.x * 10.0), roundi(point.z * 10.0))))
		var scale := 0.85 + float(noise % 300) / 1000.0
		var basis := Basis(Vector3.UP, atan2(-along.z, along.x) + (float(noise / 300 % 100) / 100.0 - 0.5) * 0.3)
		var shade := 0.82 + float(noise / 30000 % 300) / 1000.0
		var item := [Transform3D(basis.scaled(Vector3(1.0, scale, 1.0)), point), Color(shade, shade, shade)]
		(walls if stone else hedges).append(item)


func _apply_range() -> void:
	# as leiras não têm alcance: o multimesh delas cobre todos os campos e o alcance conta do centro dele
	for layer: MultiMeshInstance3D in _layers.values():
		layer.visibility_range_end = _range_m
		layer.visibility_range_end_margin = _range_m * 0.1
		layer.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


## A planta de cada tipo, com a base em y = 0 e a altura cheia (cor no vértice), feita uma vez.
## Material das plantas e do capim (Fase 22): o da folhagem das árvores, com a cor do vértice, balançando
## ao vento do WeatherView até o alto da malha.
static func plant_material(mesh: Mesh, sway: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/foliage.gdshader") as Shader
	material.set_shader_parameter(&"albedo", Color.WHITE)
	material.set_shader_parameter(&"use_vertex_color", true)
	material.set_shader_parameter(&"roughness", 0.9)
	material.set_shader_parameter(&"model_height", maxf(mesh.get_aabb().end.y, 0.05))
	material.set_shader_parameter(&"sway", sway)
	material.set_shader_parameter(&"sway_speed", PLANT_SWAY_SPEED)
	return material


static func plant_mesh(crop: int) -> ArrayMesh:
	if _meshes.has(crop):
		return _meshes[crop]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match crop:
		BuildingDef.Crop.GRAIN:
			# touceira de colmos com a espiga em cima
			for i: int in 6:
				var angle := TAU * i / 6.0
				var lean := Basis(Vector3(cos(angle), 0.0, sin(angle)).cross(Vector3.UP), 0.12)
				var foot := Vector3(cos(angle), 0.0, sin(angle)) * 0.06
				_part(tool, _box(Vector3(0.025, 0.9, 0.025)), Transform3D(lean, foot + lean * Vector3(0.0, 0.45, 0.0)),
						Color(0.78, 0.66, 0.3))
				_part(tool, _box(Vector3(0.06, 0.2, 0.06)), Transform3D(lean, foot + lean * Vector3(0.0, 0.98, 0.0)),
						Color(0.9, 0.74, 0.32))
		BuildingDef.Crop.TUBER:
			for i: int in 3:
				var angle := TAU * i / 3.0
				_part(tool, _sphere(0.22), Transform3D(Basis.from_scale(Vector3(1.0, 0.65, 1.0)),
						Vector3(cos(angle), 0.0, sin(angle)) * 0.13 + Vector3(0.0, 0.14, 0.0)), Color(0.24, 0.42, 0.17))
		BuildingDef.Crop.HOPS:
			_part(tool, _cylinder(0.04, 3.2), Transform3D(Basis.IDENTITY, Vector3(0.0, 1.6, 0.0)), Color(0.42, 0.31, 0.2))
			_part(tool, _cylinder(0.2, 2.5), Transform3D(Basis.IDENTITY, Vector3(0.0, 1.65, 0.0)), Color(0.32, 0.52, 0.2))
			_part(tool, _sphere(0.26), Transform3D(Basis.IDENTITY, Vector3(0.0, 2.95, 0.0)), Color(0.42, 0.6, 0.25))
		BuildingDef.Crop.VINE:
			_part(tool, _box(Vector3(0.06, 1.3, 0.06)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.65, 0.0)), Color(0.4, 0.3, 0.2))
			_part(tool, _box(Vector3(0.25, 0.6, 0.85)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.85, 0.0)), Color(0.27, 0.44, 0.19))
			for i: int in 3:
				_part(tool, _sphere(0.08), Transform3D(Basis.IDENTITY, Vector3(0.14 * (1 - 2 * (i % 2)), 0.55, -0.25 + 0.25 * i)),
						Color(0.32, 0.12, 0.3))
		BuildingDef.Crop.CANE:
			for i: int in 5:
				var angle := TAU * i / 5.0
				var foot := Vector3(cos(angle), 0.0, sin(angle)) * 0.1
				var lean := Basis(Vector3(cos(angle), 0.0, sin(angle)).cross(Vector3.UP), 0.08)
				_part(tool, _cylinder(0.035, 2.4), Transform3D(lean, foot + lean * Vector3(0.0, 1.2, 0.0)), Color(0.48, 0.62, 0.26))
				_part(tool, _box(Vector3(0.6, 0.02, 0.08)), Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.BACK, -0.5),
						foot + Vector3(0.0, 2.1, 0.0)), Color(0.36, 0.56, 0.2))
		BuildingDef.Crop.BUSH:
			_part(tool, _sphere(0.45), Transform3D(Basis.from_scale(Vector3(1.0, 1.1, 1.0)), Vector3(0.0, 0.55, 0.0)),
					Color(0.17, 0.34, 0.14))
			for i: int in 5:
				var angle := TAU * i / 5.0
				_part(tool, _sphere(0.06), Transform3D(Basis.IDENTITY, Vector3(cos(angle) * 0.42, 0.55 + 0.15 * (i % 2),
						sin(angle) * 0.42)), Color(0.72, 0.16, 0.1))
		BuildingDef.Crop.BROADLEAF:
			_part(tool, _cylinder(0.03, 0.9), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.45, 0.0)), Color(0.4, 0.55, 0.22))
			for i: int in 6:
				var angle := TAU * i / 6.0 + i * 0.4
				var height := 0.2 + 0.12 * i
				_part(tool, _box(Vector3(0.5 - 0.04 * i, 0.02, 0.2)), Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.BACK, -0.35),
						Vector3(cos(-angle), 0.0, sin(-angle)) * 0.2 + Vector3(0.0, height, 0.0)), Color(0.34, 0.54, 0.2))
	tool.index()
	var mesh := tool.commit()
	_meshes[crop] = mesh
	return mesh


## Uma leira de 1 m em x e 1 m de largura: terra amontoada em telhado (a escala estica o comprimento e a
## largura; a cor vem da instância).
static func furrow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prism := PrismMesh.new()
	prism.size = Vector3(1.0, FURROW_HEIGHT_M, 1.0)
	_part(tool, prism, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, FURROW_HEIGHT_M * 0.5 - 0.02, 0.0)), Color.WHITE)
	tool.index()
	return tool.commit()


## Um lanço de cerca de 1 m em +x: o mourão no começo e duas travessas (a escala em x estica o lanço).
static func fence_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := Color.WHITE
	_part(tool, _box(Vector3(0.1, 0.95, 0.1)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.475, 0.0)), wood)
	for height: float in [0.42, 0.78]:
		_part(tool, _box(Vector3(1.0, 0.07, 0.04)), Transform3D(Basis.IDENTITY, Vector3(0.5, height, 0.0)), wood)
	tool.index()
	return tool.commit()


## Fase 40: um metro de sebe em x — três moitas achatadas encostadas, em dois verdes (a cor da instância escurece ou
## clareia).
static func hedge_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 3:
		var color := HEDGE_COLOR if i % 2 == 0 else HEDGE_COLOR.lightened(0.12)
		_part(tool, _sphere(0.42), Transform3D(Basis.from_scale(Vector3(0.95, 1.0 + 0.12 * (i % 2), 0.8)),
				Vector3(-0.33 + 0.33 * i, 0.42, 0.0)), color)
	tool.index()
	return tool.commit()


## Um metro de muro de pedra seca em x: três fiadas de pedras, mais estreitas em cima.
static func wall_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for course: int in 3:
		var stones := 3 - course % 2
		for k: int in stones:
			var width := 1.0 / stones
			var color := WALL_COLOR.darkened(0.08 * ((course + k) % 3))
			_part(tool, _box(Vector3(width * 0.94, 0.2, 0.5 - course * 0.08)),
					Transform3D(Basis.IDENTITY, Vector3(-0.5 + width * (k + 0.5), 0.1 + course * 0.2, 0.0)), color)
	tool.index()
	return tool.commit()


## Touceira de capim: folhas finas abertas em leque.
static func tuft_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 5:
		var angle := TAU * i / 5.0
		var lean := Basis(Vector3(cos(angle), 0.0, sin(angle)).cross(Vector3.UP), 0.35)
		_part(tool, _box(Vector3(0.05, 0.32, 0.015)), Transform3D(lean * Basis(Vector3.UP, angle), lean * Vector3(0.0, 0.16, 0.0)),
				Color(0.36, 0.52, 0.22) if i % 2 == 0 else Color(0.44, 0.58, 0.26))
	tool.index()
	return tool.commit()


static func _part(tool: SurfaceTool, mesh: PrimitiveMesh, place: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index: int in indices:
		tool.set_color(color)
		tool.set_normal((place.basis * normals[index]).normalized())
		tool.add_vertex(place * vertices[index])


static func _box(size: Vector3) -> BoxMesh:
	var box := BoxMesh.new()
	box.size = size
	return box


static func _sphere(radius: float) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	return sphere


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 6
	cylinder.rings = 1
	return cylinder
