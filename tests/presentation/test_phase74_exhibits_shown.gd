extends GdUnitTestSuite
## Recintos e vitrines (Fase 74): o zoológico ganha o pátio com seis cercados e o museu, seis pedestais na frente; cada
## peça posta aparece na vaga dela (o bicho no meio do cercado, a peça no tampo do pedestal), na ordem do catálogo, e
## sai quando o prédio é demolido. Só apresentação.

const STREET := 20

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation()
	_sim.free_build = true


func _spec(def_id: StringName) -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, BuildingRecord.new(5, def_id, 0, Vector2i(10, 10), 0), 2.0)


func test_the_zoo_has_six_pens_and_the_museum_six_pedestals() -> void:
	var zoo := _spec(&"zoo")
	assert_int(zoo.silhouette).is_equal(BuildingDef.Silhouette.MENAGERIE)
	assert_int(zoo.court_rows).is_equal(6 - BuildingKit.MENAGERIE_HALL_ROWS)
	var museum := _spec(&"museum")
	assert_int(museum.silhouette).is_equal(BuildingDef.Silhouette.GALLERY)
	assert_int(museum.court_rows).is_equal(1)
	for spec: BuildingKit.Spec in [zoo, museum]:
		var spots := BuildingKit.exhibit_spots(spec)
		assert_int(spots.size()).is_equal(_sim.data.building(&"zoo").exhibit_slots)
		var size := spec.size_m()
		var yard_end := -size.y * 0.5 + spec.court_rows * spec.cell_m
		for spot: Vector3 in spots:
			# todas as vagas no pátio, dentro do lote, sem repetir
			assert_float(absf(spot.x)).is_less(size.x * 0.5)
			assert_float(spot.z).is_between(-size.y * 0.5, yard_end)
			assert_int(spots.count(spot)).is_equal(1)
		var plain := _spec(&"zoo" if spec == zoo else &"museum")
		plain.silhouette = BuildingDef.Silhouette.NONE
		assert_int(BuildingKit.triangles(spec)).is_greater(BuildingKit.triangles(plain))
	# o caminho da porta do museu fica livre: nenhum pedestal na coluna do meio
	for spot: Vector3 in BuildingKit.exhibit_spots(museum):
		assert_float(absf(spot.x)).is_greater(1.0)
		assert_float(spot.y).is_equal_approx(BuildingKit.GALLERY_PEDESTAL_M, 0.001)


func test_every_exhibit_has_its_own_model() -> void:
	var seen: Array[String] = []
	for def: ExhibitDef in _sim.data.exhibits:
		var made := ExhibitModels.mesh(def.id) as ArrayMesh
		assert_object(made).override_failure_message(String(def.id)).is_not_null()
		var box := made.get_aabb()
		# de pé no chão (ou no tampo) e de um tamanho que cabe no cercado ou no pedestal
		assert_float(box.position.y).override_failure_message(String(def.id)).is_greater_equal(-0.01)
		assert_float(box.size.y).override_failure_message(String(def.id)).is_greater(0.3)
		assert_float(maxf(box.size.x, box.size.z)).override_failure_message(String(def.id)).is_less(3.6)
		# cada uma com a sua forma: as caixas não se repetem
		var shape := "%.2f %.2f %.2f" % [box.size.x, box.size.y, box.size.z]
		assert_bool(seen.has(shape)).override_failure_message(String(def.id) + " igual a outra").is_false()
		seen.append(shape)
	assert_object(ExhibitModels.mesh(&"elephant")).is_same(ExhibitModels.mesh(&"elephant"))


func test_placed_exhibits_show_in_their_spots() -> void:
	SimFixture.road(_sim, Vector2i(0, STREET), Vector2i(119, STREET))
	var zoo_id := SimFixture.place(_sim, &"zoo", Vector2i(10, STREET + 1), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	assert_int(view.exhibit_nodes(zoo_id).size()).is_equal(0)
	assert_bool(_sim.execute(PlaceExhibitCommand.new(&"lion", zoo_id)).ok()).is_true()
	assert_bool(_sim.execute(PlaceExhibitCommand.new(&"elephant", zoo_id)).ok()).is_true()
	var shown := view.exhibit_nodes(zoo_id)
	assert_int(shown.size()).is_equal(2)
	# na ordem do catálogo, cada um na sua vaga
	var spots := BuildingKit.exhibit_spots(BuildingKit.spec_for(_sim, _sim.world.building(zoo_id), _sim.config.cell_size_m))
	var listed := _sim.world.exhibits_state.in_building(zoo_id, _sim.data)
	for k: int in shown.size():
		assert_str(String(shown[k].name)).is_equal(String(listed[k].id))
		assert_vector(shown[k].position).is_equal(spots[k])
	_sim.execute(DemolishCommand.new(SimFixture.ISLAND, Rect2i(Vector2i(10, STREET + 1), Vector2i(6, 6))))
	assert_int(view.exhibit_nodes(zoo_id).size()).is_equal(0)
