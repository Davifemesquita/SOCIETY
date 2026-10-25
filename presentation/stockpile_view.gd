class_name StockpileView
extends Node3D
## Pilhas de estoque (seção 9, Fase 13): diante de cada prédio de produção, uma peça (saco, barril,
## caixote, tora ou monte, CargoKit) por tonelada pronta esperando a carroça, em duas colunas que
## sobem em camadas. A pilha cresce com a produção e diminui quando a carroça leva. Um MultiMesh por
## tipo de peça; só lê o estado, nenhuma regra aqui.

const REFRESH_SECONDS := 0.5
## Duas peças lado a lado por camada.
const COLUMNS := 2
## Folga entre a parede e a pilha.
const GAP_M := 0.1
## Quanto cada peça gira, no máximo, para a pilha não ficar alinhada demais.
const JITTER_RAD := 0.35

var _simulation: Simulation
var _cell_size: float
## Por prédio: onde fica a pilha (mundo, base da primeira peça) e o tipo de peça.
var _anchors: Dictionary[int, Transform3D] = {}
var _piles: Dictionary[int, int] = {}
var _goods: Dictionary[int, GoodDef] = {}
var _layers: Dictionary[int, MultiMeshInstance3D] = {}
## Toneladas mostradas por prédio na última conferência (só refaz os MultiMesh quando muda).
var _shown: Dictionary[int, int] = {}
var _range_m: float = 260.0
var _refresh_left: float = 0.0


func setup(simulation: Simulation, cell_size: float) -> void:
	_simulation = simulation
	_cell_size = cell_size
	for pile: int in GoodDef.Pile.values():
		var mesh := CargoKit.mesh(pile)
		if mesh == null:
			continue
		var layer := MultiMeshInstance3D.new()
		layer.name = "Pile%d" % pile
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = CargoKit.tinted(pile)
		multimesh.mesh = mesh
		# Fase 32: caixa fixa (as pilhas mudam a toda hora; o alcance de visibilidade é por camada, não por pilha)
		multimesh.custom_aabb = WorldBounds.of(simulation.config)
		layer.multimesh = multimesh
		add_child(layer)
		_layers[pile] = layer
	_apply_range()
	EventBus.building_placed.connect(_add)
	EventBus.building_removed.connect(_remove)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func set_quality(preset: GraphicsPresetDef) -> void:
	_range_m = _simulation.config.building_detail_range_m * preset.visibility_scale
	_apply_range()


func rebuild() -> void:
	_anchors.clear()
	_piles.clear()
	_goods.clear()
	for building_id: int in _simulation.world.building_ids():
		_add(building_id)
	refresh()


## Quantas peças aparecem agora (todas as pilhas).
func item_count() -> int:
	var total := 0
	for layer: MultiMeshInstance3D in _layers.values():
		total += layer.multimesh.visible_instance_count
	return total


## Peças do prédio na última conferência.
func items_of(building_id: int) -> int:
	return _shown.get(building_id, 0)


func anchor_of(building_id: int) -> Transform3D:
	return _anchors.get(building_id, Transform3D.IDENTITY)


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()


## Confere o estoque de saída de cada prédio e refaz as pilhas se alguma mudou.
func refresh() -> void:
	var changed := _shown.size() != _anchors.size()
	var counts: Dictionary[int, int] = {}
	var most := _simulation.config.building_buffer_t
	for building_id: int in _anchors:
		var record := _simulation.world.building(building_id)
		var tons := clampi(floori(record.output_buffer + 0.000001), 0, most) if record != null else 0
		counts[building_id] = tons
		if _shown.get(building_id, -1) != tons:
			changed = true
	_shown = counts
	if changed:
		_draw()


func _draw() -> void:
	var lists: Dictionary[int, Array] = {}
	for pile: int in _layers:
		lists[pile] = []
	for building_id: int in _shown:
		var pile := _piles[building_id]
		if not _layers.has(pile):
			continue
		for index: int in _shown[building_id]:
			var turn := (float(absi(hash(building_id * 31 + index)) % 1000) / 1000.0 - 0.5) * 2.0 * JITTER_RAD
			var offset := CargoKit.slot(index, COLUMNS, 1) + Vector3(CargoKit.ITEM_M * 0.5, 0.0, 0.0)
			lists[pile].append([_anchors[building_id] * Transform3D(Basis(Vector3.UP, turn), offset), building_id])
	for pile: int in lists:
		var multimesh := _layers[pile].multimesh
		var items: Array = lists[pile]
		if multimesh.instance_count < items.size():
			multimesh.visible_instance_count = -1
			multimesh.instance_count = items.size() + 32
		multimesh.visible_instance_count = items.size()
		for index: int in items.size():
			var item: Array = items[index]
			var place: Transform3D = item[0]
			var owner_id: int = item[1]
			multimesh.set_instance_transform(index, place)
			if multimesh.use_colors:
				multimesh.set_instance_color(index, CargoKit.color_of(_goods[owner_id]))


func _add(building_id: int) -> void:
	var record := _simulation.world.building(building_id)
	if record == null:
		return
	var def := _simulation.def_of(record)
	if not def.is_production() or def.output == &"":
		return
	var good := _simulation.data.good(def.output)
	if good == null or good.pile == GoodDef.Pile.NONE:
		return
	var spec := BuildingKit.spec_for(_simulation, record, _cell_size)
	if spec == null:
		return
	var grid := _simulation.world.island(record.island_id)
	var center := grid.rect_world(Footprint.rect(record.origin, def.size, record.rotation))
	_anchors[building_id] = Transform3D(Basis(Vector3.UP, -PI * 0.5 * posmod(record.rotation, 4)), center) * anchor(spec)
	_piles[building_id] = good.pile
	_goods[building_id] = good
	_shown.erase(building_id)


## Onde começa a pilha no referencial canônico do prédio (frente em −Z): encostada na frente, no canto
## mais longe da porta, crescendo em +x.
static func anchor(spec: BuildingKit.Spec) -> Transform3D:
	var size := spec.size_m()
	var width := COLUMNS * CargoKit.ITEM_M
	var left := spec.door_index >= spec.cells.x / 2
	var x := -size.x * 0.5 if left else size.x * 0.5 - width
	var z := -size.y * 0.5 - GAP_M - CargoKit.ITEM_M * 0.5
	return Transform3D(Basis.IDENTITY, Vector3(x, 0.0, z))


func _remove(building_id: int) -> void:
	_anchors.erase(building_id)
	_piles.erase(building_id)
	_goods.erase(building_id)
	_shown.erase(building_id)
	_draw()


func _apply_range() -> void:
	for layer: MultiMeshInstance3D in _layers.values():
		layer.visibility_range_end = _range_m
		layer.visibility_range_end_margin = _range_m * 0.1
		layer.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
