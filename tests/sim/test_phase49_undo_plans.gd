extends GdUnitTestSuite
## Desfazer e planta (Fase 49): construir e desfazer devolve um estado idêntico (com árvores e custo), a demolição
## desfeita traz os prédios com os moradores, depois de ticks o reembolso é integral, a janela vence, refazer constrói de
## novo, o lugar mudado recusa sem mexer em nada, o histórico não vai para o save; plantas sem custo que vão para o save,
## são construídas pelos comandos de sempre e apagadas por área; substituir em área; o save sobe para a versão 16 com a
## migração que cria a lista vazia.

const SaveSystemScript := preload("res://core/save_system.gd")
const TEST_DIR := "user://test_saves_phase49"

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40), 500)
	# relevo plano com árvores (a construção derruba, o desfazer replanta)
	var grid := _sim.world.island(0)
	grid.init_terrain()
	for i: int in grid.corner_heights.size():
		grid.corner_heights[i] = 1.2
	grid.invalidate_heights()
	for y: int in range(20, 30):
		for x: int in range(10, 30):
			grid.trees[grid.index(Vector2i(x, y))] = 2


func after_test() -> void:
	if DirAccess.dir_exists_absolute(TEST_DIR):
		for file_name: String in DirAccess.get_files_at(TEST_DIR):
			DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
		DirAccess.remove_absolute(TEST_DIR)


func _state() -> String:
	return var_to_str(_sim.world.to_dict())


func _paying() -> void:
	_sim.free_build = false
	_sim.world.money = 20000.0
	SimFixture.give(_sim, &"planks", 200.0)
	SimFixture.give(_sim, &"bricks", 200.0)


func test_build_and_undo_leaves_an_identical_state() -> void:
	_paying()
	var before := _state()
	var built := _sim.execute_undoable(PlaceBuildingCommand.new(0, &"house", Vector2i(12, 22), 0))
	assert_bool(built.ok()).override_failure_message(str(built.reason)).is_true()
	assert_float(_sim.world.money).is_less(20000.0)
	assert_int(_sim.world.island(0).trees[_sim.world.island(0).index(Vector2i(13, 23))]).is_equal(0)
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_str(_state()).is_equal(before)
	# a estrada também (calça por cima das árvores)
	var path := RoadPath.l_path(Vector2i(10, 26), Vector2i(28, 26))
	assert_bool(_sim.execute_undoable(BuildRoadCommand.new(0, path)).ok()).is_true()
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_str(_state()).is_equal(before)


func test_an_undone_demolition_brings_the_buildings_and_their_people_back() -> void:
	var houses: Array[int] = []
	for i: int in 3:
		houses.append(SimFixture.house(_sim, 2 + i * 3, 8, &"workers", 17.0))
	SimFixture.road(_sim, Vector2i(0, 8), Vector2i(20, 8))
	_paying()
	var before := _state()
	var demolished := _sim.execute_undoable(DemolishCommand.new(0, Rect2i(0, 5, 20, 4)))
	assert_int(demolished.removed.size()).is_equal(3)
	assert_object(_sim.world.building(houses[1])).is_null()
	var undone := _sim.undo_last()
	assert_bool(undone.ok()).is_true()
	assert_array(undone.placed).contains_exactly_in_any_order(houses)
	assert_float(_sim.world.building(houses[1]).residents).is_equal(17.0)
	assert_str(_sim.world.building(houses[1]).tier).is_equal("workers")
	assert_bool(_sim.world.island(0).has_road(Vector2i(5, 8))).is_true()
	assert_str(_state()).is_equal(before)


func test_after_some_ticks_the_refund_is_the_full_cost() -> void:
	_paying()
	var def := _sim.data.building(&"house")
	assert_bool(_sim.execute_undoable(PlaceBuildingCommand.new(0, &"house", Vector2i(40, 10), 0)).ok()).is_true()
	SimFixture.run(_sim, 3.0)
	var money := _sim.world.money
	var wood := SimFixture.stock(_sim, &"planks")
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_float(_sim.world.money).is_equal_approx(money + def.cost_money, 0.0001)
	var wood_cost: int = def.cost_materials.get(&"planks", 0)
	assert_float(SimFixture.stock(_sim, &"planks")).is_equal_approx(wood + wood_cost, 0.0001)
	assert_object(_sim.world.building(_sim.world.island(0).building_at(Vector2i(41, 11)))).is_null()


func test_the_window_expires() -> void:
	_sim.config.undo_window_s = 1.0
	assert_bool(_sim.execute_undoable(PlaceBuildingCommand.new(0, &"house", Vector2i(40, 10), 0)).ok()).is_true()
	SimFixture.run(_sim, 3.0)
	assert_str(_sim.undo_last().reason).is_equal(UndoHistory.EXPIRED)
	assert_bool(_sim.undo.can_undo(_sim)).is_false()
	assert_int(_sim.world.island(0).building_at(Vector2i(41, 11))).is_not_equal(0)


func test_redo_builds_again_and_a_new_action_clears_it() -> void:
	assert_bool(_sim.execute_undoable(PlaceBuildingCommand.new(0, &"house", Vector2i(40, 10), 0)).ok()).is_true()
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_bool(_sim.undo.can_redo(_sim)).is_true()
	assert_bool(_sim.redo_last().ok()).is_true()
	assert_int(_sim.world.island(0).building_at(Vector2i(41, 11))).is_not_equal(0)
	# refeita, ela volta para o histórico: desfaz de novo
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_bool(_sim.execute_undoable(PlaceBuildingCommand.new(0, &"house", Vector2i(45, 10), 0)).ok()).is_true()
	assert_bool(_sim.undo.can_redo(_sim)).is_false()
	assert_str(_sim.redo_last().reason).is_equal(UndoHistory.NOTHING)


func test_a_changed_place_refuses_without_touching_anything() -> void:
	var house := SimFixture.place(_sim, &"house", Vector2i(40, 10), 0)
	assert_bool(_sim.execute_undoable(DemolishCommand.new(0, Rect2i(40, 10, 1, 1))).ok()).is_true()
	# outra casa no lote, fora do histórico
	SimFixture.place(_sim, &"house", Vector2i(40, 10), 0)
	var before := _state()
	assert_str(_sim.undo_last().reason).is_equal(UndoHistory.CHANGED)
	assert_str(_state()).is_equal(before)
	assert_object(_sim.world.building(house)).is_null()


func test_the_history_stays_out_of_the_save_and_resets_with_the_world() -> void:
	assert_bool(_sim.execute_undoable(PlaceBuildingCommand.new(0, &"house", Vector2i(40, 10), 0)).ok()).is_true()
	assert_bool(_sim.undo.can_undo(_sim)).is_true()
	var saved := _sim.world.to_dict()
	assert_bool(var_to_str(saved).contains("undo")).is_false()
	_sim.world = WorldState.from_dict(saved, _sim.data, _sim.config)
	assert_bool(_sim.undo.can_undo(_sim)).is_false()


func test_plans_cost_nothing_and_go_to_the_save() -> void:
	_paying()
	var money := _sim.world.money
	var placed := _sim.execute_undoable(PlacePlanCommand.new(0, &"house", Vector2i(40, 10), 0))
	assert_bool(placed.ok()).is_true()
	assert_bool(placed.plans_changed).is_true()
	assert_float(_sim.world.money).is_equal(money)
	assert_int(_sim.world.island(0).building_at(Vector2i(41, 11))).is_equal(0)
	assert_str(_sim.execute(PlacePlanCommand.new(0, &"house", Vector2i(41, 11), 0)).reason).is_equal(PlacePlanCommand.OVER_PLAN)
	assert_bool(_sim.execute(PlacePlanCommand.new(0, &"house", Vector2i(45, 10), 1)).ok()).is_true()
	var restored := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)
	assert_int(restored.plans.size()).is_equal(2)
	assert_int(restored.next_plan_id).is_equal(3)
	assert_int(restored.plans[2].rotation).is_equal(1)
	# desfazer a planta
	var before_undo := _sim.world.plans.size()
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_int(_sim.world.plans.size()).is_equal(before_undo)


func test_building_plans_uses_the_usual_rules_and_keeps_the_ones_that_fail() -> void:
	_paying()
	_sim.execute(PlacePlanCommand.new(0, &"house", Vector2i(40, 10), 0))
	_sim.execute(PlacePlanCommand.new(0, &"house", Vector2i(45, 10), 0))
	_sim.execute(PlacePlanCommand.new(0, &"house", Vector2i(50, 10), 0))
	# um prédio de verdade por cima da terceira: ela não pode mais ser construída
	_sim.free_build = true
	SimFixture.place(_sim, &"house", Vector2i(50, 10), 0)
	_sim.free_build = false
	var money := _sim.world.money
	var built := _sim.execute_undoable(BuildPlansCommand.new(0))
	assert_int(built.placed.size()).is_equal(2)
	assert_float(_sim.world.money).is_equal_approx(money - 2 * _sim.data.building(&"house").cost_money, 0.0001)
	assert_int(_sim.world.plans.size()).is_equal(1)
	# desfeito: as duas casas somem e as plantas voltam
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_int(_sim.world.plans.size()).is_equal(3)
	assert_float(_sim.world.money).is_equal(money)
	# apagar por área
	assert_bool(_sim.execute(RemovePlansCommand.new(0, Rect2i(39, 9, 10, 4))).ok()).is_true()
	assert_int(_sim.world.plans.size()).is_equal(1)


func test_replace_in_an_area_and_undo_it() -> void:
	var bakery := _sim.data.building(&"bakery")
	var other: BuildingDef = null
	for def: BuildingDef in _sim.data.buildings:
		if def.id != bakery.id and def.size == bakery.size and def.is_production() and def.terrain == BuildingDef.Terrain.NONE \
				and def.modules_required == 0:
			other = def
			break
	assert_object(other).is_not_null()
	var first := SimFixture.place(_sim, &"bakery", Vector2i(40, 2), 0)
	var second := SimFixture.place(_sim, &"bakery", Vector2i(46, 2), 1)
	var before := _state()
	var replaced := _sim.execute_undoable(ReplaceCommand.new(0, Rect2i(38, 0, 20, 10), other.id))
	assert_array(replaced.removed).contains_exactly_in_any_order([first, second])
	assert_int(replaced.placed.size()).is_equal(2)
	var fresh := _sim.world.building(replaced.placed[1])
	assert_str(fresh.def_id).is_equal(other.id)
	var turned := _sim.world.building(_sim.world.island(0).building_at(Vector2i(46, 2)))
	assert_int(turned.rotation).is_equal(1)
	assert_str(_sim.execute(ReplaceCommand.new(0, Rect2i(0, 30, 5, 5), other.id)).reason).is_equal(ReplaceCommand.NOTHING)
	assert_bool(_sim.undo_last().ok()).is_true()
	assert_str(_state()).is_equal(before)


func test_the_save_goes_to_version_sixteen_with_a_migration() -> void:
	assert_int(SaveSystemScript.SAVE_VERSION).is_equal(16)
	assert_int(SaveMigrations.all().size()).is_equal(15)
	# um mundo da versão 15 (sem plantas) abre depois da migração, sem nenhuma
	var old := _sim.world.to_dict()
	old.erase("plans")
	old.erase("next_plan_id")
	assert_object(WorldState.from_dict(old.duplicate(true), _sim.data, _sim.config)).is_null()
	var migrated := SaveMigrations.from_15_to_16({"world": old})
	var world_data: Dictionary = migrated["world"]
	var loaded := WorldState.from_dict(world_data, _sim.data, _sim.config)
	assert_object(loaded).is_not_null()
	assert_int(loaded.plans.size()).is_equal(0)
	assert_int(loaded.next_plan_id).is_equal(1)


func test_plans_survive_saving_and_loading() -> void:
	_sim.execute(PlacePlanCommand.new(0, &"house", Vector2i(40, 10), 3))
	var saves: SaveSystemScript = auto_free(SaveSystemScript.new())
	saves.save_dir = TEST_DIR
	assert_int(saves.save_game("plantas", {"world": _sim.world.to_dict()})).is_equal(OK)
	var loaded := saves.load_game("plantas")
	var world_data: Dictionary = loaded["world"]
	var restored := WorldState.from_dict(world_data, _sim.data, _sim.config)
	assert_int(restored.plans.size()).is_equal(1)
	assert_int(restored.plans[1].rotation).is_equal(3)


func test_routes_keep_a_name_and_a_group_in_the_save() -> void:
	var route := _sim.execute(CreateRouteCommand.new()).created_id
	var renamed := _sim.execute(RenameRouteCommand.new(route, "  Pão para a colônia  ", "Norte"))
	assert_bool(renamed.routes_changed).is_true()
	assert_str(_sim.world.routes[route].name).is_equal("Pão para a colônia")
	assert_str(_sim.world.routes[route].group).is_equal("Norte")
	assert_str(_sim.execute(RenameRouteCommand.new(route, "x".repeat(80), "")).reason).is_equal("")
	assert_int(_sim.world.routes[route].name.length()).is_equal(RenameRouteCommand.MAX_LENGTH)
	var restored := WorldState.from_dict(_sim.world.to_dict(), _sim.data, _sim.config)
	assert_str(restored.routes[route].name).is_equal("x".repeat(RenameRouteCommand.MAX_LENGTH))
	# a migração dá nome e grupo vazios às rotas da versão 15
	var old := _sim.world.to_dict()
	old.erase("plans")
	old.erase("next_plan_id")
	var routes: Array = old["routes"]
	var first: Dictionary = routes[0]
	first.erase("name")
	first.erase("group")
	var migrated: Dictionary = SaveMigrations.from_15_to_16({"world": old})["world"]
	var loaded := WorldState.from_dict(migrated, _sim.data, _sim.config)
	assert_str(loaded.routes[route].name).is_equal("")
	assert_str(_sim.execute(RenameRouteCommand.new(999, "a", "b")).reason).is_equal(ShipRules.NO_ROUTE)
