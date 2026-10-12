class_name TownLayout
extends RefCounted
## Gera uma vila de teste por comandos: ruas horizontais ligadas por uma rua vertical, com
## prédios virados para a rua dos dois lados. O quarteirão tem a profundidade de dois prédios
## mais a rua. Usada pelo benchmark, pela captura e pelos testes.


## Constrói até count prédios do tipo dado (sem custo) e devolve os ids, na ordem.
static func build(simulation: Simulation, count: int, def_id: StringName, start: Vector2i = Vector2i(2, 2)) -> Array[int]:
	var was_free := simulation.free_build
	simulation.free_build = true
	var ids := _build(simulation, count, def_id, start)
	simulation.free_build = was_free
	return ids


static func _build(simulation: Simulation, count: int, def_id: StringName, start: Vector2i) -> Array[int]:
	var def := simulation.data.building(def_id)
	var grid := simulation.world.island(Simulation.MAIN_ISLAND)
	var width := def.size.x
	var block := def.size.y * 2 + 1
	var per_row := (grid.size.x - start.x - 2) / width
	var rows_needed := ceili(count / (2.0 * per_row))
	var street_rows: Array[int] = []
	for row: int in rows_needed + 1:
		street_rows.append(start.y + row * block)
	var avenue := RoadPath.l_path(Vector2i(start.x, start.y), Vector2i(start.x, street_rows[street_rows.size() - 1]))
	simulation.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, avenue))
	for street_y: int in street_rows:
		var street := RoadPath.l_path(Vector2i(start.x, street_y), Vector2i(start.x + per_row * width, street_y))
		simulation.execute(BuildRoadCommand.new(Simulation.MAIN_ISLAND, street))
	var ids: Array[int] = []
	for row: int in rows_needed:
		var street_y := street_rows[row]
		for side: int in 2:
			var origin_y := street_y + 1 if side == 0 else street_y + block - def.size.y
			var rotation := 0 if side == 0 else 2
			for slot: int in per_row:
				if ids.size() >= count:
					return ids
				var origin := Vector2i(start.x + 1 + slot * width, origin_y)
				var result := simulation.execute(PlaceBuildingCommand.new(Simulation.MAIN_ISLAND, def_id, origin, rotation))
				if result.ok():
					ids.append(result.placed[0])
	return ids
