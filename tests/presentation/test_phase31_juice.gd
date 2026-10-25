extends GdUnitTestSuite
## Obra e combate (Fase 31): o prédio construído sobe achatado e assenta, o demolido sai das contas na hora e afunda
## antes de sumir, a salva lança balas em arco que caem com respingo e fazem o alvo adernar, e o zoom da roda vai
## suave até o alvo. Tudo direto com SceneFader.is_instant() (a suíte liga SOCIETY_SEM_TRANSICAO).

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))
	_sim.free_build = true


func after_test() -> void:
	SceneFader.instant = false
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "1")


## Liga as animações neste teste; false sem tela (aí tudo é direto e o teste para).
func _animate() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	OS.set_environment("SOCIETY_SEM_TRANSICAO", "0")
	SceneFader.instant = false
	return true


func _view() -> BuildingView:
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	return view


func test_in_tests_building_and_demolishing_are_direct() -> void:
	var view := _view()
	var house := SimFixture.place(_sim, &"house", Vector2i(10, 10), 0)
	assert_vector(view.building_node(house).scale).is_equal(Vector3.ONE)
	EventBus.building_removed.emit(house)
	assert_int(view.building_count()).is_equal(0)
	assert_int(view.demolishing_count()).is_equal(0)


func test_a_new_building_pops_up_and_settles() -> void:
	if not _animate():
		return
	var view := _view()
	var house := SimFixture.place(_sim, &"house", Vector2i(10, 10), 0)
	var node := view.building_node(house)
	assert_float(node.scale.y).is_less(0.5)
	await get_tree().create_timer(BuildingView.BUILD_POP_S * 0.55).timeout
	# passou do ponto em y e afinou em xz
	assert_float(node.scale.y).is_greater(1.0)
	assert_float(node.scale.x).is_less(1.0)
	await get_tree().create_timer(BuildingView.BUILD_POP_S).timeout
	assert_vector(node.scale).is_equal_approx(Vector3.ONE, Vector3(0.001, 0.001, 0.001))


func test_a_demolished_building_leaves_the_count_at_once_and_sinks() -> void:
	var view := _view()
	var house := SimFixture.place(_sim, &"house", Vector2i(10, 10), 0)
	if not _animate():
		return
	var node := view.building_node(house)
	var start_y := node.position.y
	EventBus.building_removed.emit(house)
	assert_int(view.building_count()).is_equal(0)
	assert_int(view.demolishing_count()).is_equal(1)
	assert_bool(is_instance_valid(node)).is_true()
	await get_tree().create_timer(BuildingView.DEMOLISH_S * 0.5).timeout
	assert_float(node.position.y).is_less(start_y)
	await get_tree().create_timer(BuildingView.DEMOLISH_S).timeout
	assert_bool(is_instance_valid(node)).is_false()
	assert_int(view.demolishing_count()).is_equal(0)


func test_demolishing_a_whole_street_sinks_at_most_the_cap() -> void:
	var view := _view()
	var houses: Array[int] = []
	for i: int in BuildingView.MAX_DEMOLISHING + 3:
		houses.append(SimFixture.place(_sim, &"house", Vector2i(2 + (i % 9) * 5, 2 + (i / 9) * 5), 0))
	if not _animate():
		return
	for house: int in houses:
		EventBus.building_removed.emit(house)
	assert_int(view.building_count()).is_equal(0)
	assert_int(view.demolishing_count()).is_equal(BuildingView.MAX_DEMOLISHING)


func _ship(at: Vector2) -> Ship:
	var ship := Ship.new(_sim.world.next_ship_id, _sim.data.ship(&"frigate"))
	_sim.world.next_ship_id += 1
	ship.position = at
	ship.previous_position = at
	_sim.world.ships[ship.id] = ship
	return ship


## Espera o ShipView montar os navios (o _process dele vem depois do process_frame).
func _until_drawn(view: ShipView, ship_id: int) -> void:
	for i: int in 10:
		if view.ship_node(ship_id) != null:
			return
		await await_idle_frame()


func test_a_salvo_flies_in_an_arc_splashes_and_heels_the_target() -> void:
	var view: ShipView = auto_free(ShipView.new())
	add_child(view)
	view.setup(_sim)
	var attacker := _ship(Vector2(0.0, -120.0))
	var target := _ship(Vector2(60.0, -120.0))
	await _until_drawn(view, target.id)
	# nos testes, só o clarão
	EventBus.ship_fired.emit(attacker.id, target.id)
	assert_int(view.ball_count()).is_equal(0)
	if not _animate():
		return
	EventBus.ship_fired.emit(attacker.id, target.id)
	assert_int(view.ball_count()).is_equal(ShipView.BALLS_PER_SALVO)
	assert_float(view.heel(target.id)).is_equal(0.0)
	# no meio do voo a bala está acima da água
	await get_tree().create_timer(ShipView.BALL_FLIGHT_S * 0.5).timeout
	var high := view._balls[0].node
	assert_bool(high.visible).is_true()
	assert_float(high.position.y).is_greater(ShipView.BALL_ARC_M * 0.5)
	await get_tree().create_timer(ShipView.BALL_FLIGHT_S * 0.5 + ShipView.BALL_STAGGER_S * ShipView.BALLS_PER_SALVO + 0.05).timeout
	assert_int(view.ball_count()).is_equal(0)
	assert_int(view.splash_count()).is_equal(ShipView.BALLS_PER_SALVO)
	assert_float(absf(view.heel(target.id))).is_greater(0.0)
	# o respingo some e o navio volta ao prumo
	await get_tree().create_timer(maxf(ShipView.SPLASH_S, ShipView.HEEL_DECAY_S * 5.0) + 0.1).timeout
	assert_int(view.splash_count()).is_equal(0)
	assert_float(view.heel(target.id)).is_equal(0.0)


func test_balls_in_the_air_never_pass_the_pool() -> void:
	var view: ShipView = auto_free(ShipView.new())
	add_child(view)
	view.setup(_sim)
	var attacker := _ship(Vector2(0.0, -120.0))
	var target := _ship(Vector2(60.0, -120.0))
	await _until_drawn(view, target.id)
	if not _animate():
		return
	for i: int in ShipView.MAX_BALLS:
		EventBus.ship_fired.emit(attacker.id, target.id)
	assert_int(view.ball_count()).is_equal(ShipView.MAX_BALLS)


func test_smooth_zoom_eases_to_the_target_and_steps_add_up() -> void:
	var config := GameConfig.new()
	var rig := CameraRig.new(config, Rect2(0, 0, 500, 500))
	var start := rig.distance
	rig.zoom_toward(1.0)
	rig.zoom_toward(1.0)
	var target := start * pow(1.0 - config.camera_zoom_step, 2.0)
	assert_float(rig.target_distance).is_equal_approx(target, 0.0001)
	assert_float(rig.distance).is_equal(start)
	rig.ease_zoom(config.camera_zoom_seconds)
	assert_float(rig.distance).is_between(target, start)
	for i: int in 60:
		rig.ease_zoom(1.0 / 60.0)
	assert_bool(rig.is_zooming()).is_false()
	assert_float(rig.distance).is_equal(target)
	# o zoom direto (testes, ferramentas) cancela o suave
	rig.zoom_toward(-1.0)
	rig.zoom(1.0)
	assert_bool(rig.is_zooming()).is_false()
	assert_float(rig.target_distance).is_equal(rig.distance)
