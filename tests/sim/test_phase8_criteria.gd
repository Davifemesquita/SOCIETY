extends GdUnitTestSuite
## Critério da Fase 8 (seção 16): é possível chegar à quinta classe numa partida. A partida
## roteirizada (tools/progression_demo.gd) monta a cidade sem custo, mas tudo o que as casas
## consomem e os materiais de cada mudança de classe saem da produção dela.


func test_a_match_reaches_the_fifth_class() -> void:
	var demo := ProgressionDemo.build()
	var elapsed := demo.run_until_tier(&"investors", 2.0 * 3600.0)
	assert_int(demo.houses_of(&"investors")).override_failure_message(
			"sem investidores em %.0f min de jogo" % (elapsed / 60.0)).is_greater(0)
	# passou por todas as classes: cada uma tem casas no fim (o jogador as manteve para trabalhar)
	for tier: TierDef in demo.simulation.data.tiers:
		assert_int(demo.houses_of(tier.id)).override_failure_message(str(tier.id)).is_greater(0)
	# nada veio de fora: o estoque nunca recebeu os importados do comerciante
	for good: StringName in demo.simulation.data.trader().sells:
		if demo.simulation.data.good(good).consumption_per_resident_t_min <= 0.0 and not _is_made(demo, good):
			assert_float(demo.simulation.world.economy(0).amount(good)).is_equal(0.0)


func _is_made(demo: ProgressionDemo, good: StringName) -> bool:
	for def: BuildingDef in demo.simulation.data.buildings:
		if def.is_production() and def.output == good:
			return true
	return false
