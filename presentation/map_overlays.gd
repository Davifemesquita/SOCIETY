class_name MapOverlays
extends RefCounted
## Camadas de mapa do jogador (seções 7 e 10): raio dos serviços, alcance dos armazéns,
## fertilidade, poluição, rede de estradas e eletricidade (Fase 11), como imagens por célula para o DebugOverlay. Só lê o
## estado da simulação. As camadas F1/F2 de depuração continuam no DebugOverlay.

enum Layer { NONE, SERVICE, WAREHOUSE, FERTILITY, POLLUTION, ROADS, ELECTRICITY }

const ICONS: Dictionary[Layer, String] = {
	Layer.SERVICE: "overlay_service", Layer.WAREHOUSE: "overlay_warehouse", Layer.FERTILITY: "overlay_fertility",
	Layer.POLLUTION: "overlay_pollution", Layer.ROADS: "overlay_roads", Layer.ELECTRICITY: "overlay_electricity",
}
const KEYS: Dictionary[Layer, String] = {
	Layer.SERVICE: "OVERLAY_SERVICE", Layer.WAREHOUSE: "OVERLAY_WAREHOUSE", Layer.FERTILITY: "OVERLAY_FERTILITY",
	Layer.POLLUTION: "OVERLAY_POLLUTION", Layer.ROADS: "OVERLAY_ROADS", Layer.ELECTRICITY: "OVERLAY_ELECTRICITY",
}

const REACHED := Color(0.35, 0.75, 1.0, 0.5)
const COVERED := Color(0.3, 0.9, 0.4, 0.6)
const UNCOVERED := Color(1.0, 0.35, 0.25, 0.6)
const FERTILE := Color(0.45, 0.85, 0.25, 0.32)
const POLLUTED := Color(0.55, 0.25, 0.1)
const SERVED := Color(0.3, 0.9, 0.4, 0.6)
const UNSERVED := Color(1.0, 0.35, 0.25, 0.6)
const POWER_ON := Color(1.0, 0.85, 0.25, 0.3)
const POWER_OFF := Color(0.6, 0.6, 0.6, 0.25)


static func image(layer: Layer, simulation: Simulation, island_id: int) -> Image:
	var grid := simulation.world.island(island_id)
	if grid == null:
		return null
	match layer:
		Layer.SERVICE:
			return service(simulation, island_id)
		Layer.WAREHOUSE:
			return warehouse(simulation, island_id)
		Layer.FERTILITY:
			return fertility(simulation, island_id)
		Layer.POLLUTION:
			return pollution(simulation, island_id)
		Layer.ROADS:
			return roads(grid)
		Layer.ELECTRICITY:
			return electricity(simulation, island_id)
	return null


static func _blank(grid: IslandGrid) -> Image:
	return Image.create_empty(grid.size.x, grid.size.y, false, Image.FORMAT_RGBA8)


static func _fill_building(image: Image, simulation: Simulation, record: BuildingRecord, color: Color) -> void:
	var rect := Footprint.rect(record.origin, simulation.def_of(record).size, record.rotation)
	image.fill_rect(rect.intersection(Rect2i(Vector2i.ZERO, image.get_size())), color)


## Estrada ao alcance de algum serviço, casas atendidas por todos os serviços da classe (verde) ou
## faltando algum (vermelho).
static func service(simulation: Simulation, island_id: int) -> Image:
	var world := simulation.world
	var derived := simulation.derived_state()
	var grid := world.island(island_id)
	var image := _blank(grid)
	for service_id: int in derived.services_list():
		var record := world.building(service_id)
		if record.island_id != island_id:
			continue
		for index: int in derived.service_reach.get(service_id, PackedInt32Array()):
			image.set_pixelv(grid.cell_at(index), REACHED)
	for house_id: int in derived.houses:
		var house := world.building(house_id)
		if house.island_id != island_id:
			continue
		_fill_building(image, simulation, house, COVERED if _all_services(simulation, house) else UNCOVERED)
	return image


static func _all_services(simulation: Simulation, house: BuildingRecord) -> bool:
	var tier := simulation.data.tier(house.tier)
	var covered: Array = simulation.derived_state().coverage.get(house.id, [])
	for need: NeedCategoryDef in tier.basic_needs + tier.luxury_needs:
		if need.services.is_empty():
			continue
		var any := false
		for service: StringName in need.services:
			any = any or covered.has(service)
		if not any:
			return false
	return true


## Estrada ao alcance de um armazém ligado (até logistics_range_cells) e os prédios de produção
## atendidos (verde) ou não (vermelho).
static func warehouse(simulation: Simulation, island_id: int) -> Image:
	var world := simulation.world
	var derived := simulation.derived_state()
	var grid := world.island(island_id)
	var image := _blank(grid)
	var field: WarehouseField = derived.fields.get(island_id)
	if field != null:
		for index: int in field.distance.size():
			var steps := field.distance[index]
			if steps >= 0 and steps <= simulation.config.logistics_range_cells:
				image.set_pixelv(grid.cell_at(index), REACHED)
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		if entry.record.island_id == island_id:
			_fill_building(image, simulation, entry.record, SERVED if entry.warehouse_id != 0 else UNSERVED)
	return image


## Terra plana onde as fazendas da ilha podem ser construídas: a ilha toda vale para as culturas
## do perfil dela (o nome das culturas aparece na dica da camada).
static func fertility(simulation: Simulation, island_id: int) -> Image:
	var grid := simulation.world.island(island_id)
	var image := _blank(grid)
	var crops := crops_of(simulation, island_id)
	if crops.is_empty():
		return image
	var color := FERTILE
	color.a = minf(0.6, FERTILE.a * crops.size())
	for i: int in grid.occupancy.size():
		if grid.flat or grid.ground[i] == IslandGrid.Ground.LAND:
			image.set_pixelv(grid.cell_at(i), color)
	return image


static func crops_of(simulation: Simulation, island_id: int) -> Array[StringName]:
	var profile := simulation.data.profile(simulation.world.economy(island_id).profile_id)
	return profile.fertilities if profile != null else ([] as Array[StringName])


## Poluição de olarias, fundições e minas: cai com a distância até o raio de cada fonte (a mesma
## conta que tira felicidade das casas).
static func pollution(simulation: Simulation, island_id: int) -> Image:
	var world := simulation.world
	var grid := world.island(island_id)
	var strength := PackedFloat32Array()
	strength.resize(grid.occupancy.size())
	for record: BuildingRecord in world.buildings.values():
		var def := simulation.def_of(record)
		if record.island_id != island_id or def.pollution_radius_cells <= 0:
			continue
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		var reach := area.grow(def.pollution_radius_cells).intersection(Rect2i(Vector2i.ZERO, grid.size))
		for y: int in range(reach.position.y, reach.end.y):
			for x: int in range(reach.position.x, reach.end.x):
				var gap := DerivedState._rect_gap(area, Rect2i(x, y, 1, 1))
				var falloff := 1.0 - float(gap) / float(def.pollution_radius_cells + 1)
				var i := y * grid.size.x + x
				strength[i] = minf(1.0, strength[i] + def.pollution_strength * falloff)
	var image := _blank(grid)
	for i: int in strength.size():
		if strength[i] > 0.0:
			image.set_pixelv(grid.cell_at(i), Color(POLLUTED, 0.15 + 0.55 * strength[i]))
	return image


## Raio das usinas (amarelo se a usina produz, cinza se parada) e as fábricas: verde com
## eletricidade, vermelho sem.
static func electricity(simulation: Simulation, island_id: int) -> Image:
	var grid := simulation.world.island(island_id)
	var image := _blank(grid)
	var derived := simulation.derived_state()
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		if entry.record.island_id != island_id or not entry.def.is_power_plant():
			continue
		var area := Footprint.rect(entry.record.origin, entry.def.size, entry.record.rotation)
		var reach := area.grow(entry.def.power_radius_cells).intersection(Rect2i(Vector2i.ZERO, grid.size))
		var tint := POWER_ON if entry.record.state == BuildingRecord.State.PRODUCING else POWER_OFF
		for y: int in range(reach.position.y, reach.end.y):
			for x: int in range(reach.position.x, reach.end.x):
				if image.get_pixel(x, y).a < tint.a:
					image.set_pixel(x, y, tint)
	for entry: DerivedState.ProductionEntry in derived.production_entries:
		if entry.record.island_id == island_id and entry.def.is_electrifiable():
			_fill_building(image, simulation, entry.record, SERVED if entry.powered else UNSERVED)
	return image


## Trechos de estrada conectados, um tom por trecho (estrada solta aparece em outra cor).
static func roads(grid: IslandGrid) -> Image:
	var image := _blank(grid)
	var labels := RoadNetwork.components(grid)
	for i: int in labels.size():
		if labels[i] != 0:
			image.set_pixelv(grid.cell_at(i), Color.from_hsv(fmod(labels[i] * 0.618034, 1.0), 0.8, 1.0, 0.7))
	return image
