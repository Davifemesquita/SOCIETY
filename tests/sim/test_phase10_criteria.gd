extends GdUnitTestSuite
## Critério da Fase 10 (seção 16): uma partida de 3 horas roda sem erros. O jogador-robô
## (tools/auto_player.gd) joga de verdade — paga, espera material e desbloqueio, usa carroças — e a
## cada meia hora o mundo vai para o save e volta, e a partida segue no mundo carregado. Nenhum erro
## nem aviso pode aparecer no log, e o estado tem de fazer sentido do começo ao fim.


class Catcher extends Logger:
	var errors: PackedStringArray = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s %s (%s, tipo %d)" % [file, line, code, rationale, function, error_type])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func test_a_three_hour_match_runs_without_errors() -> void:
	var catcher := Catcher.new()
	OS.add_logger(catcher)
	var player := AutoPlayer.create()
	var sim := player.simulation
	var floor_money := sim.config.min_balance_for(sim.world.difficulty)
	for half_hour: int in 6:
		player.play(1800.0)
		_assert_sane(sim, "aos %d min" % ((half_hour + 1) * 30))
		var saved := sim.world.to_dict()
		var loaded := WorldState.from_dict(saved, sim.data, sim.config)
		assert_object(loaded).override_failure_message("o save dos %d min não abriu" % ((half_hour + 1) * 30)).is_not_null()
		sim.world = loaded
	OS.remove_logger(catcher)
	assert_array(Array(catcher.errors)).is_empty()
	assert_float(player.lowest_money).override_failure_message(player.summary()).is_greater_equal(floor_money)
	# a partida anda: operários e artesãos em 3 horas
	assert_int(sim.world.population(&"workers")).override_failure_message(player.summary()).is_greater(500)
	assert_int(sim.world.population(&"artisans")).override_failure_message(player.summary()).is_greater(0)


func _assert_sane(sim: Simulation, when: String) -> void:
	var world := sim.world
	assert_bool(is_finite(world.money)).override_failure_message("dinheiro %s" % when).is_true()
	var capacity := sim.storage_capacity(0)
	for good: StringName in world.economy(0).stock:
		var tons := world.economy(0).amount(good)
		assert_float(tons).override_failure_message("estoque de %s %s" % [good, when]).is_between(-0.0001, capacity + 0.0001)
	for record: BuildingRecord in world.buildings.values():
		if record.is_house():
			var most := float(sim.data.tier(record.tier).residents_per_house)
			assert_float(record.residents).override_failure_message("casa %d %s" % [record.id, when]).is_between(0.0, most + 0.0001)
			assert_float(record.happiness).is_between(0.0, 100.0)
	for cart: Cart in world.carts.values():
		assert_object(world.building(cart.home_id)).override_failure_message("carroça sem casa %s" % when).is_not_null()
		assert_float(cart.tons()).is_less_equal(sim.config.cart_capacity_t + 0.0001)
