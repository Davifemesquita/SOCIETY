extends GdUnitTestSuite
## Prédios de modelo (BuildingKit): toda forma vira malha dentro da área, com a porta na entrada em
## qualquer rotação, as casas iguais dividem a malha e o orçamento de polígonos fica de pé.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func test_the_kit_is_in_the_project() -> void:
	assert_bool(BuildingKit.available()).is_true()
	for piece: String in ["wall", "wall-door", "wall-doorway-round", "wall-window-shutters", "wall-window-glass",
			"wall-window-small", "wall-wood", "wall-wood-door", "wall-wood-doorway-round", "wall-wood-window-shutters",
			"wall-wood-window-glass", "wall-wood-window-small", "chimney", "windmill", "watermill", "wheel",
			"pillar-wood", "stall-red", "stall-green", "banner-red", "fence", "fence-gate", "hedge",
			"balcony-wall-fence", "pillar-stone", "planks-half"]:
		assert_bool(ResourceLoader.exists(BuildingKit.DIR + piece + ".glb")).override_failure_message(piece).is_true()


func test_every_building_but_fields_piers_and_decorations_gets_a_model_inside_its_area() -> void:
	for def: BuildingDef in _sim.data.buildings:
		var record := BuildingRecord.new(1, def.id, 0, Vector2i(10, 10), 0)
		if def.kind == BuildingDef.Kind.RESIDENCE:
			record.tier = &"peasants"
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		# campo, pasto e píer ficam fora do kit; a decoração (Fase 16) é da DecorationView
		if def.kind in [BuildingDef.Kind.MODULE, BuildingDef.Kind.PIER, BuildingDef.Kind.DECORATION]:
			assert_object(spec).override_failure_message(String(def.id)).is_null()
			continue
		var box := BuildingKit.mesh(spec).get_aabb()
		var reach := Vector3(def.size.x * 2.0, 0.0, def.size.y * 2.0) * 0.5 + Vector3.ONE
		assert_float(absf(box.position.x)).override_failure_message(String(def.id)).is_less_equal(reach.x)
		assert_float(absf(box.position.z)).override_failure_message(String(def.id)).is_less_equal(reach.z)
		assert_float(box.end.y).override_failure_message(String(def.id)).is_greater_equal(spec.height_m)
		assert_float(box.position.y).override_failure_message(String(def.id)).is_less(0.0)
		assert_int(BuildingKit.triangles(spec)).override_failure_message(String(def.id)).is_between(100, 30000)


func test_houses_of_each_class_stay_within_the_polygon_budget_and_share_meshes() -> void:
	for tier: StringName in [&"peasants", &"workers", &"artisans", &"engineers", &"investors"]:
		var record := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
		record.tier = tier
		var spec := BuildingKit.spec_for(_sim, record, 2.0)
		assert_int(BuildingKit.triangles(spec)).override_failure_message(String(tier)).is_less_equal(20000)
		var twin := BuildingRecord.new(7, &"house", 0, Vector2i(40, 20), 0)
		twin.tier = tier
		assert_object(BuildingKit.mesh(BuildingKit.spec_for(_sim, twin, 2.0))).is_same(BuildingKit.mesh(spec))
	var wood := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	wood.tier = &"peasants"
	assert_int(BuildingKit.spec_for(_sim, wood, 2.0).walls).is_equal(BuildingKit.Walls.WOOD)
	var brick := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	brick.tier = &"workers"
	assert_int(BuildingKit.spec_for(_sim, brick, 2.0).walls).is_equal(BuildingKit.Walls.PLASTER)


func test_the_door_faces_the_entrance_in_every_rotation() -> void:
	for def_id: StringName in [&"house", &"bakery", &"furnace", &"hospital", &"warehouse"]:
		var def := _sim.data.building(def_id)
		for rotation: int in 4:
			var record := BuildingRecord.new(3, def_id, 0, Vector2i(20, 20), rotation)
			# os camponeses têm o quintal na frente (a porta fica atrás dele): ver o teste do detalhe
			record.tier = &"workers"
			var spec := BuildingKit.spec_for(_sim, record, 2.0)
			var area := Footprint.rect(record.origin, def.size, rotation)
			var center := GridSpace.rect_center(area, 2.0)
			var place := Transform3D(Basis(Vector3.UP, -PI * 0.5 * rotation), center)
			var door := place * BuildingKit.door_position(spec)
			var entrance := GridSpace.cell_center(Footprint.entrance_cell(record.origin, def.size, rotation), 2.0)
			var gap := Vector2(entrance.x - door.x, entrance.z - door.z)
			var label := "%s rotação %d" % [def_id, rotation]
			# a porta fica na fachada, meia célula atrás do meio da célula de entrada
			assert_float(gap.length()).override_failure_message(label).is_less(1.4)
			var front := Footprint.front_direction(rotation)
			assert_float(gap.dot(Vector2(front))).override_failure_message(label).is_greater(0.5)


func test_roof_shapes_follow_the_building() -> void:
	var house := BuildingRecord.new(1, &"house", 0, Vector2i(10, 10), 0)
	house.tier = &"workers"
	var spec := BuildingKit.spec_for(_sim, house, 2.0)
	assert_int(spec.roof).is_equal([BuildingKit.Roof.GABLE_X, BuildingKit.Roof.GABLE_Z, BuildingKit.Roof.FLAT][BuildingView.house_variant(1)])
	var church := BuildingKit.spec_for(_sim, BuildingRecord.new(2, &"church", 0, Vector2i(10, 10), 0), 2.0)
	assert_int(church.roof).is_equal(BuildingKit.Roof.HIP)
	assert_int(church.door).is_equal(BuildingKit.Door.ARCH)
	var mine := BuildingKit.spec_for(_sim, BuildingRecord.new(3, &"iron_mine", 0, Vector2i(10, 10), 0), 2.0)
	assert_int(mine.roof).is_equal(BuildingKit.Roof.FLAT)
	var warehouse := BuildingKit.spec_for(_sim, BuildingRecord.new(4, &"warehouse", 0, Vector2i(10, 10), 0), 2.0)
	assert_int(warehouse.door).is_equal(BuildingKit.Door.ARCH)


func test_the_view_draws_the_model_and_keeps_boxes_for_fields() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var house := SimFixture.house(_sim, 2, 10, &"workers", 10.0)
	var field := SimFixture.place(_sim, &"field", Vector2i(30, 20), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	var models := view.find_children("Model", "MeshInstance3D", true, false)
	assert_int(models.size()).is_equal(1)
	var model := models[0] as MeshInstance3D
	assert_object(model.material_override).is_same(BuildingMaterials.kit())
	assert_float(model.get_instance_shader_parameter(&"layer")).is_equal(float(BuildingMaterials.Wall.BRICK))
	assert_float(model.get_instance_shader_parameter(&"roof_layer")).is_equal(float(BuildingMaterials.Roof.TILES))
	assert_int(view.building_count()).is_equal(2)
	assert_int(house).is_greater(0)
	assert_int(field).is_greater(0)


func _spec(def_id: StringName) -> BuildingKit.Spec:
	return BuildingKit.spec_for(_sim, BuildingRecord.new(5, def_id, 0, Vector2i(10, 10), 0), 2.0)


func test_chains_get_their_own_silhouette() -> void:
	var seen := {}
	for def: BuildingDef in _sim.data.buildings:
		if def.silhouette == BuildingDef.Silhouette.NONE:
			continue
		seen[def.silhouette] = true
		var spec := _spec(def.id)
		assert_int(spec.silhouette).override_failure_message(String(def.id)).is_equal(def.silhouette)
		var plain := _spec(def.id)
		plain.silhouette = BuildingDef.Silhouette.NONE
		plain.court_rows = 0
		var extra := BuildingKit.triangles(spec) - BuildingKit.triangles(plain)
		var rotor := BuildingKit.rotor(spec)
		# a silhueta acrescenta peças paradas, uma parte que gira ou as duas
		assert_bool(extra != 0 or rotor != null).override_failure_message(String(def.id)).is_true()
	# toda silhueta tem ao menos um prédio
	assert_int(seen.size()).is_equal(BuildingDef.Silhouette.size() - 1)
	assert_int(_spec(&"mill").silhouette).is_equal(BuildingDef.Silhouette.WINDMILL)
	assert_int(_spec(&"iron_mine").silhouette).is_equal(BuildingDef.Silhouette.HEADFRAME)
	assert_int(_spec(&"bakery").silhouette).is_equal(BuildingDef.Silhouette.NONE)


func test_rotors_sit_where_the_machine_is() -> void:
	assert_object(BuildingKit.rotor(_spec(&"bakery"))).is_null()
	var mill := _spec(&"mill")
	var blades := BuildingKit.rotor(mill)
	# pás na frente da fachada, sem tocar o chão
	assert_float(blades.pivot.origin.z).is_less(-mill.size_m().y * 0.5)
	assert_float(blades.pivot.origin.y - blades.mesh.get_aabb().size.y * 0.5).is_greater(1.0)
	# o eixo (x da peça) aponta para fora da frente
	assert_float((blades.pivot.basis * Vector3.RIGHT).dot(Vector3.FORWARD)).is_greater(0.99)
	var sawmill := _spec(&"sawmill")
	var wheel := BuildingKit.rotor(sawmill)
	assert_float(wheel.pivot.origin.x).is_greater(sawmill.size_m().x * 0.5)
	var mine := _spec(&"coal_mine")
	var sheave := BuildingKit.rotor(mine)
	assert_float(sheave.pivot.origin.y).is_greater(mine.height_m + BuildingKit.HEADFRAME_M)
	# a polia gira em torno do meio dela
	assert_float(sheave.mesh.get_aabb().get_center().length()).is_less(0.2)
	assert_object(BuildingKit.rotor(_spec(&"mill"))).is_same(blades)


func test_the_market_keeps_a_court_of_stalls_in_front() -> void:
	var market := _spec(&"market")
	assert_int(market.court_rows).is_greater(0)
	var front := -market.size_m().y * 0.5
	var court_end := front + market.court_rows * market.cell_m
	# nenhuma janela no pátio, e a porta no fim dele
	for window: Transform3D in BuildingKit.windows(market):
		assert_float(window.origin.z).is_greater(court_end - 0.5)
	assert_float(BuildingKit.door_position(market).z).is_between(court_end - 0.5, court_end + 0.5)
	# as bancas aparecem no modelo, no pátio
	var box := BuildingKit.mesh(market).get_aabb()
	assert_float(box.position.z).is_less(court_end - market.cell_m)


func test_a_banner_hangs_above_the_door_of_services() -> void:
	var tavern := _spec(&"tavern")
	assert_int(tavern.silhouette).is_equal(BuildingDef.Silhouette.BANNERS)
	assert_str(String(BuildingKit.slot(tavern, 0, tavern.door_index, 1))).is_equal("plain")
	var plain := _spec(&"tavern")
	plain.silhouette = BuildingDef.Silhouette.NONE
	assert_int(BuildingKit.windows(tavern).size()).is_equal(BuildingKit.windows(plain).size() - 1)


func test_rotors_turn_only_while_producing() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var mill := SimFixture.place(_sim, &"mill", Vector2i(2, 11), 0)
	var sawmill := SimFixture.place(_sim, &"sawmill", Vector2i(10, 11), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	assert_int(view.rotor_count()).is_equal(2)
	var rotors := view.find_children("Rotor", "Node3D", true, false)
	var before: Array[Basis] = []
	for rotor: Node in rotors:
		before.append((rotor as Node3D).basis)
	_sim.world.building(mill).state = BuildingRecord.State.PRODUCING
	_sim.world.building(sawmill).state = BuildingRecord.State.NO_INPUT
	view.spin_rotors(1.0)
	var turned := 0
	for i: int in rotors.size():
		if not (rotors[i] as Node3D).basis.is_equal_approx(before[i]):
			turned += 1
	assert_int(turned).is_equal(1)
	# o giro é em torno do próprio eixo: o eixo não sai do lugar
	_sim.world.building(mill).paused = true
	var frozen: Array[Basis] = []
	for rotor: Node in rotors:
		frozen.append((rotor as Node3D).basis)
	view.spin_rotors(1.0)
	for i: int in rotors.size():
		assert_bool((rotors[i] as Node3D).basis.is_equal_approx(frozen[i])).is_true()
	_sim.execute(DemolishCommand.new(0, Rect2i(Vector2i(2, 11), Vector2i(1, 1))))
	assert_int(view.rotor_count()).is_equal(1)


func _house(tier: StringName) -> BuildingKit.Spec:
	var record := BuildingRecord.new(7, &"house", 0, Vector2i(10, 10), 0)
	record.tier = tier
	return BuildingKit.spec_for(_sim, record, 2.0)


func test_houses_get_the_trim_of_their_class() -> void:
	# quintal cercado na frente dos camponeses: a casa e as janelas recuam uma fileira, a cerca fica na borda
	var cottage := _house(&"peasants")
	assert_int(cottage.trim).is_equal(TierDef.HouseTrim.YARD)
	assert_int(cottage.court_rows).is_equal(1)
	var front := -cottage.size_m().y * 0.5
	var yard_end := front + cottage.cell_m
	for window: Transform3D in BuildingKit.windows(cottage):
		assert_float(window.origin.z).is_greater(yard_end - 0.5)
	assert_float(BuildingKit.door_position(cottage).z).is_between(yard_end - 0.5, yard_end + 0.5)
	assert_float(BuildingKit.mesh(cottage).get_aabb().position.z).is_less(front)
	assert_int(_house(&"workers").trim).is_equal(TierDef.HouseTrim.NONE)
	assert_int(_house(&"workers").court_rows).is_equal(0)
	# floreiras, sacadas e pórtico acrescentam peças; a sacada sai da frente
	for tier: StringName in [&"artisans", &"engineers", &"investors"]:
		var spec := _house(tier)
		var bare := _house(tier)
		bare.trim = TierDef.HouseTrim.NONE
		assert_int(BuildingKit.triangles(spec)).override_failure_message(String(tier)).is_greater(BuildingKit.triangles(bare))
	var engineers := _house(&"engineers")
	var balcony_front := -engineers.size_m().y * 0.5 - BuildingKit.BALCONY_OUT_M * 0.9
	assert_float(BuildingKit.mesh(engineers).get_aabb().position.z).is_less(balcony_front)
	assert_int(_house(&"engineers").trim).is_equal(TierDef.HouseTrim.BALCONIES)
	assert_int(_house(&"investors").trim).is_equal(TierDef.HouseTrim.PORTICO)
