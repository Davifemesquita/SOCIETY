class_name DemoVillage
extends RefCounted
## Vila de demonstração no litoral norte, usada pelas capturas: entreposto, 3 armazéns, pesca,
## lã, mercado, taverna, escola, madeira e a cadeia do pão, com as estradas ligando tudo.
## Constrói sem custo e devolve os ids que as capturas usam.


static func build(sim: Simulation) -> Dictionary:
	var was_free := sim.free_build
	sim.free_build = true
	var ids := {}
	ids["port"] = _place(sim, &"trading_post", Vector2i(150, 0), 2)
	_road(sim, Vector2i(150, 6), Vector2i(150, 12))
	_road(sim, Vector2i(40, 3), Vector2i(140, 3))
	_road(sim, Vector2i(60, 3), Vector2i(60, 40))
	_road(sim, Vector2i(60, 12), Vector2i(155, 12))
	_road(sim, Vector2i(60, 26), Vector2i(150, 26))
	_road(sim, Vector2i(60, 40), Vector2i(150, 40))
	ids["coast_warehouse"] = _place(sim, &"warehouse", Vector2i(90, 4), 0)
	ids["warehouse"] = _place(sim, &"warehouse", Vector2i(84, 22), 2)
	_place(sim, &"warehouse", Vector2i(130, 22), 2)
	ids["fishery"] = _place(sim, &"fishery", Vector2i(70, 0), 2)
	_place(sim, &"fishery", Vector2i(80, 0), 2)
	ids["market"] = _place(sim, &"market", Vector2i(100, 13), 0)
	var houses: Array[int] = []
	for x: int in range(62, 146, 3):
		var house := _place(sim, &"house", Vector2i(x, 9), 2)
		if house != 0:
			houses.append(house)
	for x: int in range(62, 98, 3):
		var house := _place(sim, &"house", Vector2i(x, 13), 0)
		if house != 0:
			houses.append(house)
	ids["houses"] = houses
	_place(sim, &"tavern", Vector2i(130, 13), 0)
	ids["lumberjack"] = _place(sim, &"lumberjack", Vector2i(62, 23), 2)
	_place(sim, &"lumberjack", Vector2i(66, 23), 2)
	ids["sawmill"] = _place(sim, &"sawmill", Vector2i(70, 22), 2)
	_place(sim, &"weavery", Vector2i(75, 22), 2)
	_place(sim, &"mill", Vector2i(90, 22), 2)
	ids["bakery"] = _place(sim, &"bakery", Vector2i(110, 22), 2)
	_place(sim, &"bakery", Vector2i(116, 22), 2)
	_place(sim, &"school", Vector2i(140, 13), 0)
	# fazendas por último: os campos e pastos ocupam o que sobra em volta
	ids["sheep"] = _farm(sim, &"sheep_farm", Vector2i(80, 27))
	ids["wheat"] = [_farm(sim, &"wheat_farm", Vector2i(100, 27)), _farm(sim, &"wheat_farm", Vector2i(124, 27))]
	sim.free_build = was_free
	sim.world.economy(0).stock[&"planks"] = 50.0
	return ids


static func _place(sim: Simulation, def_id: StringName, origin: Vector2i, rotation: int = 0) -> int:
	var result := sim.execute(PlaceBuildingCommand.new(0, def_id, origin, rotation))
	return result.placed[0] if result.ok() else 0


static func _road(sim: Simulation, from: Vector2i, to: Vector2i) -> void:
	sim.execute(BuildRoadCommand.new(0, RoadPath.l_path(from, to)))


static func _farm(sim: Simulation, def_id: StringName, origin: Vector2i) -> int:
	var farm := _place(sim, def_id, origin)
	var def := sim.data.building(def_id)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if placed < def.modules_required and _place(sim, def.module_id, Vector2i(x, y)) != 0:
				placed += 1
	return farm
