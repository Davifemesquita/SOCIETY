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


func test_the_church_gets_a_belfry_with_a_bell_above_the_roof() -> void:
	var church := _spec(&"church")
	assert_int(church.silhouette).is_equal(BuildingDef.Silhouette.BELFRY)
	var box := BuildingKit.mesh(church).get_aabb()
	# a agulha (e a cruz em cima dela) é o ponto mais alto, acima da cumeeira da igreja
	assert_float(box.end.y).is_greater_equal(BuildingKit.belfry_top(church))
	assert_float(BuildingKit.belfry_top(church)).is_greater(church.height_m + church.roof_m + 3.0)
	# a torre fica no canto da frente e sai só um pouco das paredes
	var tower := BuildingKit.belfry_center(church)
	var size := church.size_m()
	assert_float(tower.x).is_less(-size.x * 0.25)
	assert_float(tower.z).is_less(-size.y * 0.25)
	# (desde a Fase 95 o beiral redondo põe a borda do telhado EAVE_ROLL_M mais para fora)
	assert_float(box.position.x).is_greater_equal(-size.x * 0.5 - BuildingKit.BELFRY_OUT_M - 0.3 - BuildingKit.EAVE_ROLL_M)
	var plain := _spec(&"church")
	plain.silhouette = BuildingDef.Silhouette.NONE
	assert_int(BuildingKit.triangles(church)).is_greater(BuildingKit.triangles(plain) + BuildingKit.BELL_SEGMENTS * 6)


func test_heavy_factories_get_a_wide_gate() -> void:
	for def_id: StringName in [&"furnace", &"glassworks", &"brickworks", &"steel_beam_works", &"power_station"]:
		var spec := _spec(def_id)
		assert_int(spec.door).override_failure_message(String(def_id)).is_equal(BuildingKit.Door.GATE)
		assert_str(String(BuildingKit.slot(spec, 0, spec.door_index, 0))).is_equal("arch")
		var arch := _spec(def_id)
		arch.door = BuildingKit.Door.ARCH
		assert_int(BuildingKit.triangles(spec)).override_failure_message(String(def_id)).is_greater(BuildingKit.triangles(arch))
		# as folhas abertas saem da frente
		assert_float(BuildingKit.mesh(spec).get_aabb().position.z).is_less(-spec.size_m().y * 0.5 - 0.5)
	# fumaça leve fica com a porta comum
	assert_int(_spec(&"bakery").door).is_equal(BuildingKit.Door.DOOR)


func test_upper_class_houses_get_cornice_lintels_pediment_and_iron_railings() -> void:
	# cornija e uma verga de pedra (uma caixa, 12 triângulos) sobre cada janela, dos artesãos para cima
	for tier: StringName in [&"artisans", &"engineers", &"investors"]:
		var spec := _house(tier)
		var bare := _house(tier)
		bare.trim = TierDef.HouseTrim.NONE
		var lintels := BuildingKit.windows(spec).size() * 12
		assert_int(BuildingKit.triangles(spec) - BuildingKit.triangles(bare)).override_failure_message(String(tier)) \
				.is_greater(lintels)
	# a sacada dos engenheiros tem a grade de ferro no lugar da peça de madeira do kit
	var engineers := _house(&"engineers")
	var wood := _house(&"engineers")
	wood.trim = TierDef.HouseTrim.NONE
	var railing_triangles := BuildingKit.triangles(engineers) - BuildingKit.triangles(wood)
	assert_int(railing_triangles).is_greater(int(engineers.size_m().x / BuildingKit.RAIL_STEP_M) * 12)
	# o frontão dos investidores passa do alto da parede, na frente
	var investors := _house(&"investors")
	var pediment := BuildingKit.mesh(investors).get_aabb()
	assert_float(pediment.end.y).is_greater_equal(investors.height_m + BuildingKit.PEDIMENT_M)


## Fase 24: a sacada dos investidores tem balaustrada de pedra com balaústres torneados no lugar da grade de
## ferro (que fica com os engenheiros); as duas têm consolos de pedra embaixo; e toda janela com verga ganha o
## peitoril.
func test_balconies_get_turned_balusters_corbels_and_sills() -> void:
	var investors := _house(&"investors")
	var bare := _house(&"investors")
	bare.trim = TierDef.HouseTrim.NONE
	# cada balaústre: os segmentos do perfil em BALUSTER_SIDES faces, dois triângulos cada, um a cada
	# BALUSTER_STEP_M na frente da sacada
	var baluster := (BuildingKit.BALUSTER_PROFILE.size() - 1) * BuildingKit.BALUSTER_SIDES * 2
	var front := int(investors.size_m().x / BuildingKit.BALUSTER_STEP_M)
	assert_int(BuildingKit.triangles(investors) - BuildingKit.triangles(bare)).is_greater(front * baluster)
	# a dos engenheiros continua de ferro: os balaústres finos da grade, sem o perfil torneado
	var engineers := _house(&"engineers")
	var engineers_bare := _house(&"engineers")
	engineers_bare.trim = TierDef.HouseTrim.NONE
	assert_int(BuildingKit.triangles(engineers) - BuildingKit.triangles(engineers_bare)).is_less(
			BuildingKit.triangles(investors) - BuildingKit.triangles(bare))
	# consolos: o fundo da sacada fica CORBEL_M abaixo do piso dela
	for tier: StringName in [&"engineers", &"investors"]:
		var spec := _house(tier)
		var floor_y := spec.hall().floor_m()
		var lowest := INF
		for vertex: Vector3 in BuildingKit.mesh(spec).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if vertex.z < -spec.size_m().y * 0.5 - 0.2 and vertex.y > floor_y * 0.5:
				lowest = minf(lowest, vertex.y)
		assert_float(lowest).override_failure_message(String(tier)).is_less(floor_y - 0.12 - BuildingKit.CORBEL_M + 0.05)
	# verga e peitoril: duas caixas (24 triângulos) por janela, dos artesãos para cima
	for tier: StringName in [&"artisans", &"engineers", &"investors"]:
		var spec := _house(tier)
		var plain := _house(tier)
		plain.trim = TierDef.HouseTrim.NONE
		assert_int(BuildingKit.triangles(spec) - BuildingKit.triangles(plain)).override_failure_message(String(tier)) \
				.is_greater(BuildingKit.windows(spec).size() * 24)


## Fase 25: nos engenheiros e investidores a janela ganha a guarnição de pedra (duas ombreiras e a pedra de
## fecho, três caixas a mais por janela); os artesãos ficam só com a verga e o peitoril.
func test_upper_houses_frame_their_windows_in_stone() -> void:
	for tier: StringName in [&"engineers", &"investors"]:
		var spec := _house(tier)
		var plain := _house(tier)
		plain.trim = TierDef.HouseTrim.NONE
		assert_int(BuildingKit.triangles(spec) - BuildingKit.triangles(plain)).override_failure_message(String(tier)) \
				.is_greater(BuildingKit.windows(spec).size() * 60)
	# a pedra de fecho passa da verga para cima: há vértice na altura do alto dela (em cada andar) nos
	# engenheiros e investidores, e não nos artesãos
	for tier: StringName in [&"artisans", &"engineers", &"investors"]:
		var spec := _house(tier)
		var floor_m := spec.hall().floor_m()
		var key_top := floor_m * (BuildingKit.WINDOW_CENTER + BuildingKit.WINDOW_HEIGHT * 0.5) \
				+ BuildingKit.LINTEL_M * 0.5 + BuildingKit.KEYSTONE_M
		if spec.arched:
			# Fase 99: nos investidores a pedra de fecho fica no alto do arco da janela
			var step := spec.hall().size_m().x / spec.hall().cells.x
			key_top = BuildingKit.arch_spring(floor_m) + BuildingKit.arch_radius(step) + BuildingKit.ARCH_BAND_M * 1.4
		var found := false
		for vertex: Vector3 in BuildingKit.mesh(spec).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if absf(fposmod(vertex.y, floor_m) - key_top) < 0.002:
				found = true
				break
		assert_bool(found).override_failure_message(String(tier)).is_equal(tier != &"artisans")


func test_plantations_get_a_veranda_in_front_of_the_house() -> void:
	for def_id: StringName in [&"sugar_cane_farm", &"coffee_plantation", &"tobacco_plantation"]:
		var spec := _spec(def_id)
		assert_int(spec.silhouette).override_failure_message(String(def_id)).is_equal(BuildingDef.Silhouette.VERANDA)
		# a fileira da frente é a varanda: a casa e a porta recuam uma célula
		assert_int(spec.court_rows).is_equal(1)
		var size := spec.size_m()
		assert_float(BuildingKit.door_position(spec).z).is_greater(-size.y * 0.5 + spec.cell_m * 0.8)
		var porch := BuildingKit.veranda_box(spec)
		assert_float(porch.position.z).is_equal_approx(-size.y * 0.5, 0.01)
		assert_float(porch.size.z).is_greater(spec.cell_m * 0.8)
		# a água da varanda fica entre os andares, abaixo das janelas de cima
		var hall := spec.hall()
		var upper_sill := hall.floor_m() * (1.0 + BuildingKit.WINDOW_CENTER - BuildingKit.WINDOW_HEIGHT * 0.5)
		assert_float(porch.end.y).is_greater(hall.floor_m())
		assert_float(porch.end.y).is_less(upper_sill)
		# assoalho, esteios, guarda-corpo e telhado: bem mais que a casa sem a varanda
		var bare := _spec(def_id)
		bare.silhouette = BuildingDef.Silhouette.NONE
		assert_int(BuildingKit.triangles(spec)).is_greater(BuildingKit.triangles(bare) + spec.cells.x * 60)
		# o telhado da varanda vai até a frente da área (sem passar muito dela)
		var box := BuildingKit.mesh(spec).get_aabb()
		assert_float(box.position.z).is_less(-size.y * 0.5 + 0.05)
		assert_float(box.position.z).is_greater(-size.y * 0.5 - 0.5)
	# as outras fazendas seguem sem varanda
	assert_int(_spec(&"wheat_farm").court_rows).is_equal(0)


func test_the_warehouse_gets_a_loading_dock_that_grows_with_its_level() -> void:
	var record := BuildingRecord.new(6, &"warehouse", 0, Vector2i(10, 10), 0)
	var dock := BuildingKit.spec_for(_sim, record, 2.0)
	assert_bool(dock.dock).is_true()
	assert_int(dock.court_rows).is_equal(1)
	# a plataforma fica na fileira da frente, entre as rampas, na altura da caçamba
	var size := dock.size_m()
	var platform := BuildingKit.dock_box(dock)
	assert_float(platform.position.z).is_greater_equal(-size.y * 0.5)
	assert_float(platform.end.z).is_less(-size.y * 0.5 + dock.cell_m + 0.2)
	assert_float(platform.end.y).is_equal_approx(BuildingKit.DOCK_M, 0.001)
	assert_float(platform.position.x - BuildingKit.DOCK_RAMP_M).is_equal_approx(-size.x * 0.5, 0.001)
	# sem o guindaste nos dois (sem a plataforma, a silhueta seria o guindaste de coluna)
	var platform_only := BuildingKit.spec_for(_sim, record, 2.0)
	platform_only.silhouette = BuildingDef.Silhouette.NONE
	var bare := BuildingKit.spec_for(_sim, record, 2.0)
	bare.silhouette = BuildingDef.Silhouette.NONE
	bare.dock = false
	assert_int(BuildingKit.triangles(platform_only)).is_greater(BuildingKit.triangles(bare))
	# o entreposto tem o cais (HarborView), não a plataforma
	assert_bool(_spec(&"trading_post").dock).is_false()
	# nível 1: alpendre e portas de carga no lugar das janelas do térreo da frente
	record.level = 1
	var canopy := BuildingKit.spec_for(_sim, record, 2.0)
	assert_str(canopy.key()).is_not_equal(dock.key())
	var arches := func(spec: BuildingKit.Spec) -> int:
		var count := 0
		for index: int in spec.hall().cells.x:
			if BuildingKit.slot(spec.hall(), 0, index, 0) == &"arch":
				count += 1
		return count
	assert_int(arches.call(dock)).is_equal(1)
	assert_int(arches.call(canopy)).is_greater(1)
	assert_float(BuildingKit.mesh(canopy).get_aabb().position.z).is_less(-size.y * 0.5)
	assert_bool(BuildingKit.brick(canopy)).is_false()
	# nível 2 (o que custa tijolo): paredes de tijolo
	record.level = 2
	var brick := BuildingKit.spec_for(_sim, record, 2.0)
	assert_bool(BuildingKit.brick(brick)).is_true()
	assert_int(brick.walls).is_equal(BuildingKit.Walls.PLASTER)
	assert_int(dock.walls).is_equal(BuildingKit.Walls.WOOD)


func test_upgrading_the_warehouse_rebuilds_its_model_in_brick() -> void:
	SimFixture.road(_sim, Vector2i(0, 10), Vector2i(79, 10))
	var warehouse := SimFixture.place(_sim, &"warehouse", Vector2i(20, 11), 0)
	var view: BuildingView = auto_free(BuildingView.new())
	add_child(view)
	view.setup(_sim, _sim.config.cell_size_m)
	var layer := func() -> float:
		for node: Node in view.find_children("Model", "MeshInstance3D", true, false):
			# o prédio refeito deixa o nó antigo na fila de apagar até o fim do quadro
			if not node.get_parent().is_queued_for_deletion():
				return (node as MeshInstance3D).get_instance_shader_parameter(&"layer")
		return -1.0
	assert_float(layer.call()).is_equal(float(BuildingMaterials.Wall.WOOD))
	for i: int in 2:
		assert_bool(_sim.execute(UpgradeBuildingCommand.new(warehouse)).ok()).is_true()
	assert_int(_sim.world.building(warehouse).level).is_equal(2)
	assert_float(layer.call()).is_equal(float(BuildingMaterials.Wall.BRICK))
	assert_int(view.building_count()).is_equal(1)


func test_harbour_buildings_get_a_jib_crane_with_a_hanging_crate() -> void:
	for def_id: StringName in [&"trading_post", &"shipyard"]:
		var spec := _spec(def_id)
		assert_int(spec.silhouette).override_failure_message(String(def_id)).is_equal(BuildingDef.Silhouette.CRANE)
		var size := spec.size_m()
		var tip := BuildingKit.crane_tip(spec)
		# a lança sobe acima do mastro e a ponta sai da parede do lado: o caixote não encosta nela
		assert_float(tip.y).is_greater(BuildingKit.crane_height(spec))
		assert_float(tip.x - BuildingKit.CRANE_CRATE_M * 0.5).is_greater(size.x * 0.5 + 0.3)
		var hook := BuildingKit.crane_hook(spec)
		assert_float(hook.y).is_between(BuildingKit.CRANE_LOAD_M + BuildingKit.CRANE_CRATE_M, tip.y)
		var box := BuildingKit.mesh(spec).get_aabb()
		assert_float(box.end.y).is_greater_equal(tip.y)
		assert_float(box.end.x).is_less(size.x * 0.5 + 1.5)
		# mastro, lança, tirantes, sarilho, cabo e caixote: bem mais que o prédio sem o guindaste
		var bare := _spec(def_id)
		bare.silhouette = BuildingDef.Silhouette.NONE
		assert_int(BuildingKit.triangles(spec)).is_greater(BuildingKit.triangles(bare) + 200)


func test_the_docked_warehouse_hoists_from_a_beam_over_the_loading_door() -> void:
	var spec := _spec(&"warehouse")
	assert_bool(spec.dock).is_true()
	var size := spec.size_m()
	var tip := BuildingKit.hoist_tip(spec)
	# a viga passa da frente da área (e do alpendre), abaixo do beiral, sobre a porta
	assert_float(tip.z).is_less(-size.y * 0.5)
	assert_float(tip.y).is_less(spec.hall().height_m)
	assert_float(tip.x).is_equal_approx(BuildingKit.door_position(spec).x, 0.01)
	# a janela de cima da porta vira a porta de carga do sótão
	for level: int in range(1, spec.hall().floors()):
		assert_str(String(BuildingKit.slot(spec.hall(), 0, spec.door_index, level))).is_equal("plain")
	# sem o guindaste de coluna: do lado do armazém só passa o beiral do telhado
	var box := BuildingKit.mesh(spec).get_aabb()
	assert_float(box.end.x).is_less_equal(size.x * 0.5 + spec.overhang_m + 0.01)
	assert_float(box.position.z).is_less_equal(tip.z - BuildingKit.CRANE_CRATE_M * 0.5 + 0.01)
