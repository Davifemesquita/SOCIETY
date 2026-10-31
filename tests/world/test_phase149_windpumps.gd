extends GdUnitTestSuite
## Cata-vento no pasto (Fase 149): cada pasto (na ilha com relevo) ganha um cata-vento ao lado do cocho, dentro da cerca;
## a roda vira para o vento com o leme atrás e só gira com vento; a ilha plana não tem.

var _config: GameConfig
var _sim: Simulation


func before_test() -> void:
	_config = GameConfig.new()
	_config.island_sizes_cells = PackedInt32Array([90, 40])
	_config.tropical_island_sizes_cells = PackedInt32Array([30])
	_sim = Simulation.new(_config, GameData.get_default(), ArchipelagoGenerator.new_world(1840, _config, GameData.get_default()))
	_sim.free_build = true
	_sim.ignore_terrain = true


func _pasture() -> BuildingRecord:
	var grid := _sim.world.island(0)
	var found: Array = SiteFinder.find(_sim, &"pasture", 0, grid.size / 2)
	assert_bool(found.is_empty()).is_false()
	var origin: Vector2i = found[0]
	var rotation: int = found[1]
	var result := _sim.execute(PlaceBuildingCommand.new(0, &"pasture", origin, rotation))
	assert_bool(result.ok()).is_true()
	return _sim.world.building(result.placed[0])


func test_the_pump_stands_beside_the_trough_inside_the_fence() -> void:
	var record := _pasture()
	var grid := _sim.world.island(0)
	var def := _sim.def_of(record)
	var foot := WindpumpView.spot(grid, record, def)
	var area := Footprint.rect(record.origin, def.size, record.rotation)
	var lot := Rect2(grid.origin_m + Vector2(area.position) * grid.cell_size, Vector2(area.size) * grid.cell_size)
	assert_bool(lot.grow(-0.3).has_point(Vector2(foot.x, foot.z))).is_true()
	var trough := RoadMask.trough_of(record, def, grid.cell_size)
	var trough_at := grid.origin_m + trough[0]
	assert_float(Vector2(foot.x, foot.z).distance_to(trough_at)).is_equal_approx(WindpumpView.BESIDE_M, 0.01)
	# do lado do meio do lote
	var middle := lot.get_center()
	assert_float(Vector2(foot.x, foot.z).distance_to(middle)).is_less(trough_at.distance_to(middle))
	assert_float(foot.y).is_equal_approx(grid.height_at(foot.x, foot.z), 0.001)


func test_the_wheel_turns_into_the_wind_and_spins_with_it() -> void:
	_pasture()
	var view: WindpumpView = auto_free(WindpumpView.new())
	add_child(view)
	view.setup(_sim)
	assert_int(view.pump_count()).is_equal(1)
	var wind := Vector2(1.0, 0.0)
	view.turn(wind, 0.8, WindpumpView.TURN_S * 3.0)
	var pose := WindpumpView.rotor_pose(Vector3.ZERO, view._yaw, 0.0)
	# o leme (+Z da roda) aponta para onde o vento sopra
	assert_float(pose.basis.z.normalized().dot(Vector3(wind.x, 0.0, wind.y))).is_greater(0.95)
	assert_float(WindpumpView.spin_of(0.0)).is_equal(0.0)
	assert_float(WindpumpView.spin_of(WindpumpView.CALM * 0.5)).is_equal(0.0)
	assert_float(WindpumpView.spin_of(1.0)).is_equal_approx(WindpumpView.SPIN_MAX, 0.001)
	assert_float(WindpumpView.spin_of(0.6)).is_greater(WindpumpView.spin_of(0.3))


func test_the_flat_island_has_no_windpump() -> void:
	var flat := SimFixture.simulation()
	flat.free_build = true
	SimFixture.place(flat, &"pasture", Vector2i(20, 10))
	var view: WindpumpView = auto_free(WindpumpView.new())
	add_child(view)
	view.setup(flat)
	assert_int(view.pump_count()).is_equal(0)
