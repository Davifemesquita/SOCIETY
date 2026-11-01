extends GdUnitTestSuite
## Pombos na cumeeira (Fase 210): só as casas do resto certo, de telhado de duas águas, têm a fila de pombos, na altura da
## cumeeira, dentro do comprimento dela, longe da chaminé; as outras não têm.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(120, 40))
	_sim.free_build = true


func _houses(tier: StringName, count: int) -> Array[int]:
	SimFixture.road(_sim, Vector2i(0, 20), Vector2i(119, 20))
	var ids: Array[int] = []
	for i: int in count:
		ids.append(SimFixture.house(_sim, 2 + i * 5, 20, tier, 5.0))
	return ids


func test_pigeons_sit_on_the_ridge_of_the_houses_of_their_rest() -> void:
	var grid := _sim.world.island(SimFixture.ISLAND)
	var count := 0
	for tier: StringName in [&"peasants", &"workers", &"artisans"]:
		_sim = SimFixture.simulation(Vector2i(120, 40))
		_sim.free_build = true
		grid = _sim.world.island(SimFixture.ISLAND)
		for id: int in _houses(tier, 20):
			var record := _sim.world.building(id)
			var found := RoofPigeonView.pigeons(_sim, record)
			if posmod(id, RoofPigeonView.PIGEON_EVERY) != RoofPigeonView.PIGEON_REST:
				assert_int(found.size()).is_equal(0)
				continue
			var spec := BuildingKit.spec_for(_sim, record, grid.cell_size)
			var gable := spec.roof in [BuildingKit.Roof.GABLE_X, BuildingKit.Roof.GABLE_Z] and spec.wing == 0 \
					and not spec.mansard and not spec.vault
			assert_bool(found.is_empty()).is_equal(not gable)
			if found.is_empty():
				continue
			var hall := spec.hall()
			var model := BuildingView.model_place(grid, record, Footprint.rect(record.origin, _sim.def_of(record).size,
					record.rotation))
			var ridge := spec.hall_offset() + Vector3(0.0, hall.height_m + hall.roof_m, 0.0)
			var chimney: Variant = BuildingKit.chimney_top(spec)
			for place: Transform3D in found:
				var local := model.affine_inverse() * place.origin
				# na capa da cumeeira, sobre a linha dela
				assert_float(local.y - ridge.y).is_between(0.0, BuildingKit.RIDGE_CAP_M)
				var across := local.z - ridge.z if spec.roof == BuildingKit.Roof.GABLE_X else local.x - ridge.x
				assert_float(absf(across)).is_less(0.01)
				if chimney is Vector3:
					var top: Vector3 = chimney
					assert_float(Vector2(local.x - top.x, local.z - top.z).length()).is_greater(0.3)
				count += 1
	assert_int(count).is_greater(0)
