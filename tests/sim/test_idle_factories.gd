extends GdUnitTestSuite
## Fábricas ociosas (Fase 28): a produção não pausada abaixo de config.idle_productivity conta como ociosa e o total
## da manutenção dela vai para a dica do saldo; pausada ou produzindo, não conta.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()


func test_a_factory_below_the_idle_productivity_counts_until_it_is_paused_or_working() -> void:
	var sawmill := SimFixture.place(_sim, &"sawmill", Vector2i(10, 12), 0)
	var record := _sim.world.buildings[sawmill]
	var def := _sim.def_of(record)
	record.productivity = 0.0
	assert_bool(_sim.is_idle(record)).is_true()
	assert_vector(_sim.idle_upkeep()).is_equal(Vector2(1.0, def.upkeep_per_min))
	# produzindo acima do limite, não é ociosa
	record.productivity = _sim.config.idle_productivity + 0.1
	assert_bool(_sim.is_idle(record)).is_false()
	assert_vector(_sim.idle_upkeep()).is_equal(Vector2.ZERO)
	# pausada já paga a fração de pausa: não entra na conta
	record.productivity = 0.0
	assert_bool(_sim.execute(SetPausedCommand.new(sawmill, true)).ok()).is_true()
	assert_bool(_sim.is_idle(record)).is_false()
	# casa, serviço e armazém nunca são ociosos
	var house := SimFixture.house(_sim, 30, 20, &"peasants", 0.0)
	assert_bool(_sim.is_idle(_sim.world.buildings[house])).is_false()
