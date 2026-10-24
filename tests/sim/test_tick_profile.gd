extends GdUnitTestSuite
## Perfil do tick (Fase 29): com profiling ligado, cada etapa do tick soma o tempo dela em Simulation.profile; desligado,
## nada é medido.


func test_the_tick_profiles_its_steps_only_when_asked() -> void:
	var sim := SimFixture.simulation()
	sim.tick(0)
	assert_bool(sim.profile.is_empty()).is_true()
	sim.profiling = true
	for tick: int in 5:
		sim.tick(tick)
	for step: StringName in [&"força de trabalho", &"produção", &"logística", &"necessidades", &"população", &"estatísticas"]:
		assert_bool(sim.profile.has(step)).override_failure_message(String(step)).is_true()
		assert_int(sim.profile[step]).is_greater_equal(0)
	sim.profiling = false
	var before := sim.profile.duplicate()
	sim.tick(5)
	assert_dict(sim.profile).is_equal(before)
