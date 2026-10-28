extends GdUnitTestSuite
## Trem no trilho (Fase 71): o caminho mais curto pelo trilho entre o poço e a usina (RailNetwork.route), um trem por
## ligação que vai e volta por ele (espera, anda, espera, volta de ré), parado quando o poço é pausado, e sumindo quando
## o trilho é cortado. Só apresentação: a simulação não muda.

const STREET := 20

var _sim: Simulation
var _view: TrainView
var _ids: Array[int] = []


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true
	SimFixture.road(_sim, Vector2i(0, STREET), Vector2i(119, STREET))
	var grid := _sim.world.island(SimFixture.ISLAND)
	grid.oil_spots = PackedInt32Array([grid.index(Vector2i(11, STREET + 2))])
	_ids = [SimFixture.place(_sim, &"oil_well", Vector2i(10, STREET + 1), 0),
			SimFixture.place(_sim, &"oil_power_station", Vector2i(30, STREET + 1), 0)]
	# o mesmo trilho da Fase 70: uma linha embaixo dos dois e uma perna subindo até o lado de baixo do poço
	var path: Array[Vector2i] = []
	for x: int in range(10, 35):
		path.append(Vector2i(x, STREET + 6))
	for y: int in range(STREET + 4, STREET + 6):
		path.append(Vector2i(11, y))
	assert_bool(_sim.execute(BuildRailCommand.new(SimFixture.ISLAND, path)).ok()).is_true()
	_view = auto_free(TrainView.new())
	add_child(_view)
	_view.setup(_sim, _sim.config)


func test_the_route_follows_the_rail_from_the_well_to_the_station() -> void:
	var grid := _sim.world.island(SimFixture.ISLAND)
	var well := _sim.world.building(_ids[0])
	var station := _sim.world.building(_ids[1])
	var cells := RailNetwork.route(grid, well, _sim.def_of(well), station, _sim.def_of(station))
	assert_int(cells.size()).is_greater(1)
	assert_bool(RailNetwork.side_cells(grid, well, _sim.def_of(well)).has(cells[0])).is_true()
	assert_bool(RailNetwork.side_cells(grid, station, _sim.def_of(station)).has(cells[cells.size() - 1])).is_true()
	for index: int in cells.size():
		assert_bool(grid.has_rail(cells[index])).is_true()
		if index > 0:
			var step := cells[index] - cells[index - 1]
			assert_int(absi(step.x) + absi(step.y)).is_equal(1)
	# o mais curto: a perna do poço (11, 24) e a linha até a primeira célula embaixo da usina (30, 26)
	assert_vector(cells[0]).is_equal(Vector2i(11, STREET + 4))
	assert_vector(cells[cells.size() - 1]).is_equal(Vector2i(30, STREET + 6))
	assert_int(cells.size()).is_equal(2 + 20)


func test_one_train_shuttles_on_each_link() -> void:
	assert_int(_view.train_count()).is_equal(1)
	var start := _view.loco_transform(0).origin
	# espera no poço com o trem inteiro no trilho
	_view.advance(TrainView.DWELL_S * 0.5)
	assert_vector(_view.loco_transform(0).origin).is_equal_approx(start, Vector3.ONE * 0.01)
	_view.advance(TrainView.DWELL_S)
	var moving := _view.loco_transform(0).origin
	assert_float(moving.distance_to(start)).is_greater(1.0)
	# a locomotiva puxa: o vagão fica atrás dela, do lado do poço
	var wagon := _view.wagon_transform(0).origin
	assert_float(wagon.distance_to(start)).is_less(moving.distance_to(start))
	# o vaivém: frente da locomotiva pelo caminho ao longo de um ciclo
	var length := 30.0
	var train_m := TrainView.LOCO_M + TrainView.GAP_M + TrainView.WAGON_M
	var run_s := (length - train_m) / TrainView.SPEED_M_S
	assert_float(TrainView.head_at(length, 0.0)).is_equal_approx(train_m, 0.001)
	assert_float(TrainView.head_at(length, TrainView.DWELL_S + run_s * 0.5)).is_equal_approx((train_m + length) * 0.5, 0.001)
	assert_float(TrainView.head_at(length, TrainView.DWELL_S * 1.5 + run_s)).is_equal_approx(length, 0.001)
	assert_float(TrainView.head_at(length, TrainView.DWELL_S * 2.0 + run_s * 1.5)).is_equal_approx((train_m + length) * 0.5, 0.001)
	# caminho mais curto que o trem: parado
	assert_float(TrainView.head_at(4.0, 7.0)).is_equal(4.0)


func test_the_train_stops_with_the_well_paused_and_goes_with_the_rail() -> void:
	_sim.world.building(_ids[0]).paused = true
	var parked := _view.loco_transform(0).origin
	_view.advance(TrainView.DWELL_S * 2.0)
	assert_vector(_view.loco_transform(0).origin).is_equal_approx(parked, Vector3.ONE * 0.01)
	_sim.world.building(_ids[0]).paused = false
	_sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(20, STREET + 6), Vector2i(1, 1))))
	_view.refresh()
	assert_int(_view.train_count()).is_equal(0)
