extends GdUnitTestSuite
## Medida e nitidez (Fase 32): a caixa fixa do arquipélago cobre todas as ilhas (as tropicais também), os MultiMeshes
## que mudam a cada quadro a usam, e o rascunho da primeira vez monta um de cada prédio sem tocar na partida e some
## sozinho.


func test_world_bounds_cover_every_island_of_any_seed() -> void:
	var config := GameConfig.get_default()
	var bounds := WorldBounds.of(config)
	var world := ArchipelagoGenerator.new_world(1840, config, GameData.get_default())
	for index: int in world.islands.size():
		var rect := world.island(index).world_rect()
		var low := Vector3(rect.position.x, 0.0, rect.position.y)
		var high := Vector3(rect.end.x, 0.0, rect.end.y)
		assert_bool(bounds.has_point(low) and bounds.has_point(high)) \
				.override_failure_message("ilha %d fora da caixa" % index).is_true()
	# as regiões tropicais (x = 3) ficam dentro: até a Fase 31 a caixa dos pedestres parava em x = 2
	var tropical := Vector3((config.tropical_regions[0].x + 0.5) * config.terrain_region_m, 0.0, 0.0)
	assert_bool(bounds.has_point(tropical)).is_true()


func test_hot_multimeshes_have_a_fixed_box() -> void:
	var sim := SimFixture.simulation(Vector2i(40, 40))
	var bounds := WorldBounds.of(sim.config)
	var carts: CartView = auto_free(CartView.new())
	carts.setup(sim, sim.config.cell_size_m)
	add_child(carts)
	var stockpiles: StockpileView = auto_free(StockpileView.new())
	add_child(stockpiles)
	stockpiles.setup(sim, sim.config.cell_size_m)
	var ships: ShipView = auto_free(ShipView.new())
	add_child(ships)
	ships.setup(sim)
	var checked := 0
	for view: Node in [carts, stockpiles, ships]:
		for child: Node in view.get_children():
			var layer := child as MultiMeshInstance3D
			if layer == null or layer.multimesh == null:
				continue
			if view == ships and layer.name != &"Gulls":
				continue
			assert_bool(layer.multimesh.custom_aabb.is_equal_approx(bounds)) \
					.override_failure_message("%s/%s sem a caixa fixa" % [view.get_class(), layer.name]).is_true()
			checked += 1
	assert_int(checked).is_greater(4)
	remove_child(carts)
	remove_child(stockpiles)
	remove_child(ships)


func test_scratch_world_has_one_of_each_building_and_a_house_per_tier() -> void:
	var data := GameData.get_default()
	var started := Time.get_ticks_msec()
	var sim := WarmUp.scratch(GameConfig.get_default(), data)
	var defs: Dictionary[StringName, bool] = {}
	var tiers: Dictionary[StringName, bool] = {}
	for building_id: int in sim.world.building_ids():
		var record := sim.world.building(building_id)
		defs[record.def_id] = true
		if record.is_house():
			tiers[record.tier] = true
	for def: BuildingDef in data.buildings:
		assert_bool(defs.has(def.id)).override_failure_message("falta %s no rascunho" % def.id).is_true()
	assert_int(tiers.size()).is_equal(data.tiers.size())
	var island := sim.world.island(Simulation.MAIN_ISLAND)
	assert_bool(island.roads.has(IslandGrid.Road.PAVED)).is_true()
	print("rascunho da primeira vez: %d prédios em %d ms" % [sim.world.buildings.size(), Time.get_ticks_msec() - started])


func test_warm_up_draws_the_scratch_world_without_listening_to_the_match_and_leaves() -> void:
	var camera: Camera3D = auto_free(Camera3D.new())
	add_child(camera)
	var warm := WarmUp.new()
	add_child(warm)
	var started := Time.get_ticks_msec()
	warm.start(GameConfig.get_default(), GameData.get_default(), camera)
	print("primeira vez montada em %d ms" % (Time.get_ticks_msec() - started))
	assert_bool(warm.is_in_group(WarmUp.HOLD_GROUP)).is_true()
	var buildings: BuildingView = null
	for view: Node3D in warm.views:
		# nenhuma vista de rascunho ouve o EventBus: um prédio da partida não pode chegar nela
		assert_int(WarmUp.bus_connections(view)).override_failure_message("%s ainda ouve o EventBus" % view.name).is_equal(0)
		if view is BuildingView:
			buildings = view
	assert_int(buildings.building_count()).is_equal(warm.simulation.world.buildings.size())
	# encolhido na frente da câmera, onde ela olha
	assert_float(warm.scale.x).is_equal_approx(WarmUp.SHRINK, 0.0001)
	var center := warm.global_position + Vector3(warm.simulation.world.island(0).size.x, 0.0, warm.simulation.world.island(0).size.y) \
			* warm.simulation.config.cell_size_m * WarmUp.SHRINK * 0.5
	assert_bool(camera.is_position_in_frustum(center)).is_true()
	await warm.finished
	await get_tree().process_frame
	assert_bool(is_instance_valid(warm)).is_false()
	remove_child(camera)


func test_the_suite_runs_without_the_warm_up() -> void:
	# o tools/godot.sh testes desliga: cada partida dos testes pagaria o rascunho inteiro
	assert_str(OS.get_environment("SOCIETY_SEM_WARMUP")).is_equal("1")
	assert_bool(WarmUp.enabled()).is_false()
