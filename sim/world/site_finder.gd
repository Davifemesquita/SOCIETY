class_name SiteFinder
extends RefCounted
## Procura, a partir de uma célula, o lugar mais perto onde um prédio pode ser construído pelo
## terreno (área livre, plana, em terra, litoral, rio ou jazida) com a frente em terra, para a
## estrada chegar. Serve à câmera do jogo novo (o litoral do entreposto), aos testes e às capturas.
## Não confere custo, desbloqueio nem entreposto.


## [origem: Vector2i, rotação: int] do lugar mais perto de near, ou vazio se não houver até max_radius.
static func find(sim: Simulation, def_id: StringName, island_id: int, near: Vector2i, max_radius: int = 200) -> Array:
	var grid := sim.world.island(island_id)
	var def := sim.data.building(def_id)
	if grid == null or def == null:
		return []
	var profile := sim.data.profile(sim.world.economy(island_id).profile_id)
	var needs_water := def.terrain in [BuildingDef.Terrain.COAST, BuildingDef.Terrain.RIVER_OR_COAST] and not grid.flat
	var near_water := _near_water(grid, maxi(def.size.x, def.size.y) + 1) if needs_water else PackedByteArray()
	for radius: int in max_radius + 1:
		for origin: Vector2i in _ring(near, radius):
			# filtros baratos antes da conferência inteira: jazida debaixo da origem, água por perto
			if not grid.in_bounds(origin) or not grid.is_land(origin):
				continue
			if def.deposit != &"" and not grid.flat and grid.deposit_at(origin) != def.deposit:
				continue
			if needs_water and near_water[grid.index(origin)] == 0:
				continue
			for rotation: int in 4:
				if _fits(grid, profile, def, origin, rotation, sim.config):
					return [origin, rotation]
	return []


## 1 nas células a até reach de mar ou rio (dilatação direto nos arrays).
static func _near_water(grid: IslandGrid, reach: int) -> PackedByteArray:
	var width := grid.size.x
	var near := PackedByteArray()
	near.resize(grid.ground.size())
	for i: int in grid.ground.size():
		var x := i % width
		var y := i / width
		if grid.ground[i] != IslandGrid.Ground.LAND or x == 0 or y == 0 or x == width - 1 or y == grid.size.y - 1:
			near[i] = 1
	for ring: int in reach:
		var grown := near.duplicate()
		for i: int in near.size():
			if near[i] == 1:
				continue
			var x := i % width
			if near[i - width] == 1 or near[i + width] == 1 or (x > 0 and near[i - 1] == 1) or (x < width - 1 and near[i + 1] == 1):
				grown[i] = 1
		near = grown
	return near


static func _fits(grid: IslandGrid, profile: IslandProfileDef, def: BuildingDef, origin: Vector2i, rotation: int, config: GameConfig) -> bool:
	if not grid.in_bounds(origin) or not grid.is_land(origin):
		return false
	if PlacementRules.check_building(grid, def, origin, rotation) != PlacementRules.OK:
		return false
	if PlacementRules.check_terrain(grid, profile, def, origin, rotation, config) != PlacementRules.OK:
		return false
	for cell: Vector2i in Footprint.front_cells(origin, def.size, rotation):
		if PlacementRules.check_road_cell(grid, cell, config) != PlacementRules.OK or not grid.is_land(cell):
			return false
	return true


## Células à distância exata radius (anel quadrado), em ordem fixa.
static func _ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	if radius == 0:
		return [center]
	var cells: Array[Vector2i] = []
	for x: int in range(center.x - radius, center.x + radius + 1):
		cells.append(Vector2i(x, center.y - radius))
		cells.append(Vector2i(x, center.y + radius))
	for y: int in range(center.y - radius + 1, center.y + radius):
		cells.append(Vector2i(center.x - radius, y))
		cells.append(Vector2i(center.x + radius, y))
	return cells
