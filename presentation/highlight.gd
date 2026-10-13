class_name Highlight
extends RefCounted
## Imagens de destaque por célula para o DebugOverlay: o alcance de um serviço (estrada
## alcançada e casas atendidas), a área onde uma fazenda conta campos e pastos e o terreno que
## um prédio pede (jazida, floresta, litoral, rio).

const ROAD_REACHED := Color(0.35, 0.75, 1.0, 0.55)
const HOUSE_COVERED := Color(0.4, 0.95, 0.45, 0.55)
const MODULE_AREA := Color(1.0, 0.85, 0.3, 0.3)
const DEPOSIT_CELL := Color(0.95, 0.7, 0.15, 0.6)
const TREE_CELL := Color(0.2, 0.85, 0.3, 0.18)
const SHORE_CELL := Color(0.3, 0.75, 1.0, 0.5)


static func service(world: WorldState, data: GameData, island_id: int, reach: PackedInt32Array, houses: Array) -> Image:
	var grid := world.island(island_id)
	var image := Image.create_empty(grid.size.x, grid.size.y, false, Image.FORMAT_RGBA8)
	for index: int in reach:
		image.set_pixelv(grid.cell_at(index), ROAD_REACHED)
	for house_id: int in houses:
		var house := world.building(house_id)
		_fill(image, Footprint.rect(house.origin, data.building(house.def_id).size, house.rotation), HOUSE_COVERED)
	return image


## Terreno pedido pelo prédio, ou null se ele não pede nada (ou a ilha é a plana de antes).
static func terrain(grid: IslandGrid, def: BuildingDef) -> Image:
	if grid.flat or def.terrain == BuildingDef.Terrain.NONE:
		return null
	var image := Image.create_empty(grid.size.x, grid.size.y, false, Image.FORMAT_RGBA8)
	for i: int in grid.ground.size():
		var cell := grid.cell_at(i)
		match def.terrain:
			BuildingDef.Terrain.DEPOSIT:
				if def.deposit != &"" and grid.deposit_at(cell) == def.deposit:
					image.set_pixelv(cell, DEPOSIT_CELL)
			BuildingDef.Terrain.TREES:
				if grid.trees[i] > 0:
					var color := TREE_CELL
					color.a *= grid.trees[i]
					image.set_pixelv(cell, color)
			BuildingDef.Terrain.COAST, BuildingDef.Terrain.RIVER_OR_COAST:
				var cell_area := Rect2i(cell, Vector2i.ONE)
				var near_water := grid.area_touches(cell_area, IslandGrid.Ground.SEA)
				if def.terrain == BuildingDef.Terrain.RIVER_OR_COAST:
					near_water = near_water or grid.area_touches(cell_area, IslandGrid.Ground.RIVER)
				if grid.ground[i] == IslandGrid.Ground.LAND and near_water:
					image.set_pixelv(cell, SHORE_CELL)
	return image


static func area(grid: IslandGrid, region: Rect2i) -> Image:
	var image := Image.create_empty(grid.size.x, grid.size.y, false, Image.FORMAT_RGBA8)
	_fill(image, region.intersection(Rect2i(Vector2i.ZERO, grid.size)), MODULE_AREA)
	return image


static func _fill(image: Image, region: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(region.position, region.size), color)
