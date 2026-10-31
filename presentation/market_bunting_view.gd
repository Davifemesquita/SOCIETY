class_name MarketBuntingView
extends Node3D
## Fase 133: as bandeirolas da feira. Sobre o pátio das bancas de cada prédio de `Silhouette.STALLS` (o mercado), quatro
## postes nos cantos do pátio (`POLE_INSET_M` para dentro do lote) e duas cordas de bandeirolas em xis, de canto a canto,
## cedendo no meio (`posts`): o poste e a corda são os da festa da Fase 65 (`FestivalView._post`, `_string`), fixos o ano
## todo. Uma malha só para o arquipélago, refeita na obra, na demolição e ao trocar de mundo. Só apresentação; nada no save.

const POLE_INSET_M := 0.35
## As cordas presas um pouco abaixo do topo do poste.
const TIE_BELOW_M := 0.15

var _simulation: Simulation
var _mesh := MeshInstance3D.new()
var _markets := 0
var _dirty := true


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	_mesh.name = "MarketBunting"
	_mesh.material_override = material
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	EventBus.building_placed.connect(_mark)
	EventBus.building_removed.connect(_mark)
	EventBus.world_replaced.connect(rebuild)
	rebuild()


func market_count() -> int:
	return _markets


func _mark(_id: int) -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and _simulation != null:
		rebuild()


func rebuild() -> void:
	_dirty = false
	_markets = 0
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var world := _simulation.world
	var ids := world.building_ids()
	for building_id: int in ids:
		var tops := posts(_simulation, world.building(building_id))
		if tops.is_empty():
			continue
		_markets += 1
		for top: Vector3 in tops:
			FestivalView._post(tool, top, FestivalView.POLE_M, 0.06)
		var down := Vector3(0.0, TIE_BELOW_M, 0.0)
		FestivalView._string(tool, tops[0] - down, tops[2] - down)
		FestivalView._string(tool, tops[1] - down, tops[3] - down)
	_mesh.mesh = tool.commit() if _markets > 0 else null


## O topo dos quatro postes do pátio de um prédio de bancas, em volta (frente-esquerda, frente-direita, fundo-direita,
## fundo-esquerda), na altura do assento do prédio; vazio se o prédio não tem pátio de bancas.
static func posts(simulation: Simulation, record: BuildingRecord) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var def := simulation.def_of(record)
	if def == null or def.silhouette != BuildingDef.Silhouette.STALLS or def.size.y < 2:
		return result
	var grid := simulation.world.island(record.island_id)
	var cell := grid.cell_size
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var base := BuildingKit.seat(grid, area)
	var front := Footprint.front_direction(record.rotation)
	var forward := Vector3(front.x, 0.0, front.y)
	var across := Vector3(-forward.z, 0.0, forward.x)
	# a profundidade e a largura no referencial do prédio (def.size: x é a frente, y a fundura)
	var depth := def.size.y * cell
	var width := def.size.x * cell
	var court := (def.size.y / 2) * cell
	var front_edge := base + forward * (depth * 0.5 - POLE_INSET_M)
	var back_edge := base + forward * (depth * 0.5 - court + POLE_INSET_M)
	var half := across * (width * 0.5 - POLE_INSET_M)
	var up := Vector3(0.0, FestivalView.POLE_M, 0.0)
	for corner: Vector3 in [front_edge - half, front_edge + half, back_edge + half, back_edge - half]:
		result.append(corner + up)
	return result
