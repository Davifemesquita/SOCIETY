class_name Highlight
extends RefCounted
## Imagens de destaque por célula para o DebugOverlay: o alcance de um serviço (estrada
## alcançada e casas atendidas) e a área onde uma fazenda conta campos e pastos.

const ROAD_REACHED := Color(0.35, 0.75, 1.0, 0.55)
const HOUSE_COVERED := Color(0.4, 0.95, 0.45, 0.55)
const MODULE_AREA := Color(1.0, 0.85, 0.3, 0.3)


static func service(world: WorldState, data: GameData, island_id: int, reach: PackedInt32Array, houses: Array) -> Image:
	var grid := world.island(island_id)
	var image := Image.create_empty(grid.size.x, grid.size.y, false, Image.FORMAT_RGBA8)
	for index: int in reach:
		image.set_pixelv(grid.cell_at(index), ROAD_REACHED)
	for house_id: int in houses:
		var house := world.building(house_id)
		_fill(image, Footprint.rect(house.origin, data.building(house.def_id).size, house.rotation), HOUSE_COVERED)
	return image


static func area(grid: IslandGrid, region: Rect2i) -> Image:
	var image := Image.create_empty(grid.size.x, grid.size.y, false, Image.FORMAT_RGBA8)
	_fill(image, region.intersection(Rect2i(Vector2i.ZERO, grid.size)), MODULE_AREA)
	return image


static func _fill(image: Image, region: Rect2i, color: Color) -> void:
	image.fill_rect(Rect2i(region.position, region.size), color)
