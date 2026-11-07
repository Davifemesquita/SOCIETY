extends GdUnitTestSuite
## Lamaçal do chiqueiro (Fase 227): só os pastos de uma fazenda de porcos têm a poça; ela fica dentro do pasto, do lado oposto
## ao cocho; a poça é rasa, no chão, e cabe no pasto.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


## A fazenda e os pastos que ela pede, em volta dela.
func _farm(def_id: StringName, origin: Vector2i) -> int:
	var farm := SimFixture.place(_sim, def_id, origin, 0)
	var def := _sim.data.building(def_id)
	var reach := Footprint.rect(origin, def.size, 0).grow(def.module_radius_cells)
	var placed := 0
	for y: int in range(reach.position.y, reach.end.y - 2):
		for x: int in range(reach.position.x, reach.end.x - 2):
			if placed < def.modules_required and _sim.execute(PlaceBuildingCommand.new(SimFixture.ISLAND,
					def.module_id, Vector2i(x, y), 0)).ok():
				placed += 1
	assert_int(placed).is_equal(def.modules_required)
	return farm


func _view() -> MudWallowView:
	var view: MudWallowView = auto_free(MudWallowView.new())
	add_child(view)
	view.setup(_sim)
	return view


func test_only_pig_pastures_get_a_wallow() -> void:
	_farm(&"sheep_farm", Vector2i(10, 15))
	assert_int(_view().wallow_count()).is_equal(0)
	_farm(&"pig_farm", Vector2i(50, 15))
	var view := _view()
	var pastures := _sim.data.building(&"pig_farm").modules_required
	assert_int(view.wallow_count()).is_equal(pastures)


func test_the_wallow_lies_inside_the_pasture_away_from_the_trough() -> void:
	_farm(&"pig_farm", Vector2i(30, 15))
	var grid := _sim.world.island(SimFixture.ISLAND)
	var derived := _sim.derived_state()
	var checked := 0
	for id: int in _sim.world.building_ids():
		var record := _sim.world.building(id)
		if record.def_id != &"pasture" or derived.module_owner.get(id, 0) == 0:
			continue
		var def := _sim.def_of(record)
		var place := MudWallowView.spot(_sim.world, _sim.data, record)
		var area := Footprint.rect(record.origin, def.size, record.rotation)
		assert_bool(area.has_point(grid.world_to_cell(place.origin))).is_true()
		var trough := RoadMask.trough_of(record, def, grid.cell_size)
		var trough_at := Vector2(grid.origin_m.x + trough[0].x, grid.origin_m.y + trough[0].y)
		var mud_at := Vector2(place.origin.x, place.origin.z)
		assert_float(mud_at.distance_to(trough_at)).is_greater(MudWallowView.RADIUS_M.x + 0.8)
		checked += 1
	assert_int(checked).is_greater(0)


func test_the_wallow_is_flat_and_fits_the_pasture() -> void:
	var box := MudWallowView.mud_mesh().get_aabb()
	assert_float(box.size.y).is_less(0.2)
	assert_float(box.size.x).is_less(3.2)
	assert_float(box.size.z).is_less(3.2)
