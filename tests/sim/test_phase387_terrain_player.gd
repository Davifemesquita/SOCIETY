extends GdUnitTestSuite
## Fase 387: o jogador-robô no arquipélago do jogo novo (TerrainAutoPlayer), com eventos, rivais e riscos ligados.


func test_the_robot_grows_past_the_workers_lock_on_seed_1840() -> void:
	var player := TerrainAutoPlayer.on_archipelago(1840)
	player.play(1800.0)
	var world := player.simulation.world
	# antes da Fase 387 o robô parava em ~40 operários: o sabão (básico dos operários) só libera com 80 operários e
	# nenhuma casa nova saía; e os lenhadores no meio da vila ficavam sem árvore
	assert_int(world.population(&"workers")).override_failure_message("operários aos 30 min").is_greater_equal(80)
	assert_dict(player.broken).is_empty()
	var lumberjacks := 0
	for record: BuildingRecord in world.buildings.values():
		if record.def_id == &"lumberjack":
			lumberjacks += 1
	assert_int(lumberjacks).is_greater(0)
	var planks: float = world.economy(0).stock.get(&"planks", 0.0)
	assert_float(planks).is_greater(0.0)


func test_road_link_reaches_lots_behind_a_terrace() -> void:
	var player := TerrainAutoPlayer.on_archipelago(1840)
	player.play(600.0)
	var grid := player.simulation.world.island(0)
	var link := player._road_link([player.hub] as Array[Vector2i], Rect2i())
	assert_array(link).has_size(1)
	# um lote que fica a mais de 70 células pela estrada (o LINK_MAX antigo) ainda acha caminho
	player._ensure_field()
	var far := 0
	for depth: int in player._field_depth:
		if depth > 70:
			far += 1
	assert_int(far).is_greater(0)
	assert_bool(grid.has_road(player.hub)).is_true()
