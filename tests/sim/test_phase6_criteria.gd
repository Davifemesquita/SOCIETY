extends GdUnitTestSuite
## Critério de pronto da Fase 6: no arquipélago da semente 1840, uma rota automática abastece a
## ilha principal com tijolos da segunda ilha por 1 hora de jogo sem intervenção. A colônia tem a
## cava de argila, a olaria e os operários; o navio carrega os tijolos lá e descarrega na
## principal, voltando sozinho a cada ciclo.

const SEED := 1840
const HOUR_S := 3600.0
const QUARTER_S := 900.0


func test_route_supplies_the_main_island_with_bricks_for_an_hour() -> void:
	var config := GameConfig.get_default()
	var data := GameData.get_default()
	var sim := Simulation.new(config, data, ArchipelagoGenerator.new_world(SEED, config, data))
	var ids: Dictionary = TradeDemo.build(sim)
	var colony := 1
	var ship_id: int = ids["ship"]
	var brickworks: int = ids["brickworks"]
	var route: int = ids["route"]
	var ship := sim.world.ship(ship_id)
	var main := sim.world.economy(Simulation.MAIN_ISLAND)
	assert_float(main.amount(&"bricks")).is_equal(0.0)
	var deliveries := 0
	var last_stock := 0.0
	var by_quarter: Array[float] = []
	var elapsed := 0.0
	var dt := config.tick_interval()
	while elapsed < HOUR_S:
		sim.tick(0)
		elapsed += dt
		var stock := main.amount(&"bricks")
		if stock > last_stock + 0.0001:
			deliveries += 1
		last_stock = stock
		if fmod(elapsed + dt * 0.5, QUARTER_S) < dt:
			by_quarter.append(stock)
	# a colônia produziu de verdade, e o navio fez várias viagens
	assert_float(sim.world.building(brickworks).productivity).is_greater(0.8)
	assert_int(deliveries).override_failure_message("entregas: %d" % deliveries).is_greater_equal(4)
	assert_array(by_quarter).has_size(4)
	# cada quarto de hora chega mais tijolo à principal: o abastecimento não para
	for quarter: int in range(1, by_quarter.size()):
		assert_float(by_quarter[quarter]).override_failure_message("quartos: %s" % [by_quarter]).is_greater(by_quarter[quarter - 1])
	assert_float(by_quarter[3]).is_greater(30.0)
	# o navio continua na rota, e a colônia não acumula tijolo parado
	assert_int(ship.route_id).is_equal(route)
	assert_float(sim.world.economy(colony).amount(&"bricks")).is_less(20.0)
