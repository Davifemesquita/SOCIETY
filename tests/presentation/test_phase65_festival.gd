extends GdUnitTestSuite
## Festa na cidade (Fase 65): com o evento da festa numa ilha, as praças dela (mercado, chafariz, coreto; sem nenhuma, o
## entreposto) ganham mastro e cordas de bandeirolas só por cima da rua; à noite, fogos sobre os mastros; acabou a
## festa, some tudo.


func _sim() -> Simulation:
	var sim := SimFixture.simulation()
	SimFixture.road(sim, Vector2i(0, 20), Vector2i(119, 20))
	return sim


## A festa posta à mão na ilha (sem esperar o sorteio).
func _festival(sim: Simulation, island_id: int) -> WorldEvent:
	var event := WorldEvent.new()
	event.def = sim.data.event(&"festival")
	event.def_id = &"festival"
	event.island_id = island_id
	event.started_tick = sim.world.tick
	event.ends_tick = sim.world.tick + 1000
	sim.world.events_state.events.append(event)
	return event


func test_squares_prefer_the_market_and_fall_back_to_the_trading_post() -> void:
	var sim := _sim()
	assert_array(FestivalView.squares(sim, SimFixture.ISLAND)).is_empty()
	var post := SimFixture.port(sim)
	assert_array(FestivalView.squares(sim, SimFixture.ISLAND)).is_equal([post])
	var market := SimFixture.place(sim, &"market", Vector2i(40, 16), 2)
	assert_array(FestivalView.squares(sim, SimFixture.ISLAND)).is_equal([market])


func test_strings_run_only_over_the_road() -> void:
	var sim := _sim()
	var market := SimFixture.place(sim, &"market", Vector2i(40, 16), 2)
	var lines := FestivalView.strings_of(sim, market)
	assert_int(lines.size()).is_greater(0)
	var grid := sim.world.island(SimFixture.ISLAND)
	for line: PackedVector3Array in lines:
		# o alto do mastro e o do poste em cima de células de estrada, e a corda reta entre elas
		for end: Vector3 in [line[0], line[1]]:
			var cell := grid.world_to_cell(end)
			assert_int(grid.roads[grid.index(cell)]).is_not_equal(IslandGrid.Road.NONE)
		assert_float(line[0].y - line[1].y).is_equal_approx(FestivalView.MAST_M - FestivalView.POLE_M, 0.3)
		assert_float(Vector2(line[0].x - line[1].x, line[0].z - line[1].z).length()).is_greater_equal(
				FestivalView.MIN_STRING_CELLS * grid.cell_size - 0.01)


func test_the_view_decorates_only_while_the_festival_lasts() -> void:
	var sim := _sim()
	SimFixture.place(sim, &"market", Vector2i(40, 16), 2)
	var view: FestivalView = auto_free(FestivalView.new())
	add_child(view)
	view.setup(sim)
	assert_array(view.decorated_islands()).is_empty()
	var event := _festival(sim, SimFixture.ISLAND)
	EventBus.world_event_started.emit(&"festival", SimFixture.ISLAND)
	assert_array(view.decorated_islands()).is_equal([SimFixture.ISLAND])
	assert_int(view.firework_sites().size()).is_equal(1)
	# os fogos saem do alto do mastro
	view.launch(view.firework_sites()[0])
	var bursting := view.get_children().filter(func(node: Node) -> bool: return node is GPUParticles3D and (node as GPUParticles3D).emitting)
	assert_int(bursting.size()).is_equal(1)
	var burst: GPUParticles3D = bursting[0]
	assert_float(burst.position.y).is_greater(view.firework_sites()[0].y + FestivalView.FIREWORK_HEIGHT_M.x - 0.01)
	sim.world.events_state.events.erase(event)
	EventBus.world_event_ended.emit(&"festival", SimFixture.ISLAND)
	assert_array(view.decorated_islands()).is_empty()
	assert_int(view.firework_sites().size()).is_equal(0)
	remove_child(view)


func test_other_events_do_not_decorate() -> void:
	var sim := _sim()
	SimFixture.place(sim, &"market", Vector2i(40, 16), 2)
	var event := _festival(sim, SimFixture.ISLAND)
	event.def = sim.data.event(&"good_harvest")
	event.def_id = &"good_harvest"
	assert_array(FestivalView.festival_islands(sim.world)).is_empty()
