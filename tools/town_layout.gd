class_name TownLayout
extends RefCounted
## Gera uma vila de teste por comandos: ruas horizontais a cada 7 células, ligadas por uma
## rua vertical, com casas viradas para a rua dos dois lados. Usada pelo benchmark e pelos
## testes do critério "50 prédios ligados por estradas".

const BLOCK := 7


## Constrói até count prédios do tipo dado e devolve os ids, na ordem em que foram feitos.
static func build(simulation: Simulation, count: int, def_id: StringName, start: Vector2i = Vector2i(2, 2)) -> Array[int]:
	var def := simulation.catalog.find(def_id)
	var grid := simulation.world.island(Simulation.MAIN_ISLAND)
	var width := def.size.x
	var houses_per_row := (grid.size.x - start.x - 2) / width
	var rows_needed := ceili(count / (2.0 * houses_per_row))
	var street_rows: Array[int] = []
	for row: int in rows_needed:
		street_rows.append(start.y + row * BLOCK)
	var last_street := street_rows[street_rows.size() - 1] + BLOCK
	var avenue := RoadPath.l_path(Vector2i(start.x, start.y), Vector2i(start.x, last_street))
	simulation.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, avenue))
	street_rows.append(last_street)
	for street_y: int in street_rows:
		var street := RoadPath.l_path(Vector2i(start.x, street_y), Vector2i(start.x + houses_per_row * width, street_y))
		simulation.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, street))
	var ids: Array[int] = []
	for row: int in rows_needed:
		var street_y := street_rows[row]
		for side: int in 2:
			var origin_y := street_y + 1 if side == 0 else street_y + BLOCK - def.size.y
			var rotation := 0 if side == 0 else 2
			for slot: int in houses_per_row:
				if ids.size() >= count:
					return ids
				var origin := Vector2i(start.x + 1 + slot * width, origin_y)
				var result := simulation.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, def_id, origin, rotation))
				if result.ok():
					ids.append(result.placed[0])
	return ids
