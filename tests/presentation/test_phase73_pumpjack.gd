extends GdUnitTestSuite
## O cavalo-de-pau do poço de petróleo (Fase 73): o poço deixa a torre de mina e ganha o pátio da frente com o cavalete,
## a caixa de engrenagens e a cabeça do poço, e o galpão baixo atrás; o balancim balança (não gira) em volta do eixo no
## alto do cavalete enquanto o poço produz, até PUMPJACK_ROCK para cada lado, e para com o poço parado.

const STREET := 20

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _spec(def_id: StringName) -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, BuildingRecord.new(5, def_id, 0, Vector2i(10, 10), 0), 2.0)


func test_the_well_has_a_pumpjack_yard_and_a_low_shed() -> void:
	var spec := _spec(&"oil_well")
	assert_int(spec.silhouette).is_equal(BuildingDef.Silhouette.PUMPJACK)
	assert_int(spec.court_rows).is_equal(BuildingKit.PUMPJACK_ROWS)
	assert_float(spec.height_m).is_less_equal(BuildingKit.PUMPJACK_SHED_M)
	# o cavalete e o resto acrescentam peças à forma sem o pátio
	var plain := _spec(&"oil_well")
	plain.silhouette = BuildingDef.Silhouette.NONE
	assert_int(BuildingKit.triangles(spec)).is_greater(BuildingKit.triangles(plain))
	# a torre de mina continua nas minas
	assert_int(_spec(&"coal_mine").silhouette).is_equal(BuildingDef.Silhouette.HEADFRAME)


func test_the_walking_beam_sits_on_the_post_inside_the_yard() -> void:
	var spec := _spec(&"oil_well")
	var beam := BuildingKit.rotor(spec)
	assert_object(beam).is_not_null()
	assert_float(beam.rock).is_equal(BuildingKit.PUMPJACK_ROCK)
	var size := spec.size_m()
	var yard_end := -size.y * 0.5 + spec.court_rows * spec.cell_m
	var box := beam.mesh.get_aabb()
	# o balancim cabe no pátio (da frente da área até o galpão), mesmo no ângulo maior
	for angle: float in [-BuildingKit.PUMPJACK_ROCK, 0.0, BuildingKit.PUMPJACK_ROCK]:
		var placed := Transform3D(Basis(Vector3.RIGHT, angle), beam.pivot.origin) * box
		assert_float(placed.position.z).is_greater(-size.y * 0.5 - 0.3)
		assert_float(placed.end.z).is_less(yard_end + 0.3)
		assert_float(placed.position.y).is_greater(0.0)
	assert_float(beam.pivot.origin.y).is_equal_approx(BuildingKit.PUMPJACK_PIVOT_M, 0.001)


func test_the_beam_rocks_while_the_well_produces() -> void:
	SimFixture.road(_sim, Vector2i(0, STREET), Vector2i(119, STREET))
	var grid := _sim.world.island(SimFixture.ISLAND)
	grid.oil_spots = PackedInt32Array([grid.index(Vector2i(11, STREET + 2))])
	var well_id := SimFixture.place(_sim, &"oil_well", Vector2i(10, STREET + 1), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	var pivot := view.building_node(well_id).find_child("Rotor", true, false) as Node3D
	assert_object(pivot).is_not_null()
	var record := _sim.world.building(well_id)
	record.state = BuildingRecord.State.PRODUCING
	var angles: Array[float] = []
	for step: int in 12:
		view.spin_rotors(0.25)
		var forward := pivot.basis * Vector3.FORWARD
		angles.append(atan2(forward.y, -forward.z))
	# balança para os dois lados, sem passar da amplitude, e o eixo não sai do lugar
	assert_float(angles.max()).is_greater(BuildingKit.PUMPJACK_ROCK * 0.5)
	assert_float(angles.min()).is_less(-BuildingKit.PUMPJACK_ROCK * 0.5)
	for angle: float in angles:
		assert_float(absf(angle)).is_less_equal(BuildingKit.PUMPJACK_ROCK + 0.001)
	# parado (saída cheia), o balancim fica onde está
	record.state = BuildingRecord.State.OUTPUT_FULL
	var held := pivot.basis
	view.spin_rotors(1.0)
	assert_bool(pivot.basis.is_equal_approx(held)).is_true()
