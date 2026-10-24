extends GdUnitTestSuite
## Convés e cordame (Fase 26): os navios de modelo ganham ovéns e estais lidos do próprio modelo (o alto de cada
## mastro é a bandeira, a borda sai dos vértices) e uma peça de carga no convés por porão ocupado.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))


func _model(def: ShipDef) -> Node3D:
	return auto_free((load(ShipView.MODEL_DIR % def.model) as PackedScene).instantiate() as Node3D)


func test_every_ship_model_gets_shrouds_to_the_rail_and_stays_along_the_masts() -> void:
	for def: ShipDef in GameData.get_default().ships:
		var model := _model(def)
		var tops := ShipRigging.mast_tops(model)
		# os três navios do kit têm dois ou três mastros, com a bandeira no alto, da proa para a popa
		assert_int(tops.size()).override_failure_message(String(def.id)).is_between(2, 3)
		for i: int in range(1, tops.size()):
			assert_float(tops[i].z).is_less(tops[i - 1].z)
		var points := ShipRigging.hull_points(model)
		var spans := ShipRigging.spans(tops, points)
		# ovéns dos dois lados de cada mastro, o estai de proa, um entre cada par de mastros e o brandal
		assert_int(spans.size()).is_equal(tops.size() * 2 * ShipRigging.SHROUDS + 1 + (tops.size() - 1) + 1)
		var bounds := AABB(points[0], Vector3.ZERO)
		for point: Vector3 in points:
			bounds = bounds.expand(point)
		bounds = bounds.grow(0.05)
		for span: PackedVector3Array in spans:
			for point: Vector3 in span:
				assert_bool(bounds.has_point(point)).override_failure_message("%s %s" % [def.id, point]).is_true()
		# o pé do ovém fica na borda (no corte do casco naquele z): longe do meio e no alto do costado — na
		# abertura da amurada do meio do navio, a borda é a do próprio convés
		for k: int in tops.size() * 2 * ShipRigging.SHROUDS:
			var foot := spans[k][spans[k].size() - 1]
			assert_float(absf(foot.x)).override_failure_message("%s %s" % [def.id, foot]).is_greater(1.0)
			assert_float(foot.y).override_failure_message("%s %s" % [def.id, foot]).is_greater_equal(ShipRigging.DECK_Y - 0.001)


func test_the_view_hangs_the_rigging_and_the_deck_in_model_space() -> void:
	var view: ShipView = auto_free(ShipView.new())
	add_child(view)
	view.setup(_sim)
	var def := _sim.data.ship(&"merchant_ship")
	var model: Node3D = auto_free(view._model(def, Color.WHITE))
	var rigging := model.get_node(^"Rigging") as MeshInstance3D
	assert_object(rigging).is_not_null()
	assert_object(rigging.mesh).is_not_null()
	assert_object(model.get_node_or_null(^"DeckCargo")).is_not_null()
	# o cordame é filho do modelo: o ShipView estica o modelo e o cabo vem, por isso, dividido pela escala
	assert_object(rigging.get_parent()).is_same(model)
	assert_float(model.scale.x).is_greater(1.0)


func test_each_loaded_hold_shows_one_piece_on_deck_ahead_of_the_main_mast() -> void:
	var view: ShipView = auto_free(ShipView.new())
	add_child(view)
	view.setup(_sim)
	var ship := Ship.new(_sim.world.next_ship_id, _sim.data.ship(&"clipper"))
	_sim.world.next_ship_id += 1
	ship.position = Vector2(20.0, -30.0)
	ship.previous_position = ship.position
	_sim.world.ships[ship.id] = ship
	await await_idle_frame()
	var deck := view.ship_node(ship.id).get_node(^"Hull/DeckCargo") as Node3D
	assert_int(deck.get_child_count()).is_equal(0)
	# dois bens de pilha diferente em três porões e um sem pilha: três peças, em dois MultiMesh
	var piled: Array[GoodDef] = []
	var bare: GoodDef = null
	for good: GoodDef in _sim.data.goods:
		if good.pile == GoodDef.Pile.NONE:
			bare = good
		elif piled.size() < 2 and (piled.is_empty() or piled[0].pile != good.pile):
			piled.append(good)
	ship.load_good(piled[0].id, 20.0, 10.0)
	ship.load_good(piled[1].id, 10.0, 10.0)
	if bare != null:
		ship.load_good(bare.id, 10.0, 10.0)
	assert_int(view.deck_goods(ship).size()).is_equal(3)
	await await_idle_frame()
	var pieces := 0
	var main := ShipRigging.main_mast(ShipRigging.mast_tops(view.ship_node(ship.id).get_node(^"Hull") as Node3D))
	for child: Node in deck.get_children():
		var multimesh := (child as MultiMeshInstance3D).multimesh
		pieces += multimesh.instance_count
		for i: int in multimesh.instance_count:
			var at := multimesh.get_instance_transform(i).origin
			assert_float(at.z).is_greater(main.z)
			assert_float(at.y).is_equal_approx(ShipRigging.DECK_Y, 0.001)
	assert_int(deck.get_child_count()).is_equal(2)
	assert_int(pieces).is_equal(3)
	# descarregou tudo: o convés fica vazio
	for good: StringName in ship.goods():
		ship.unload_good(good, 100.0)
	await await_idle_frame()
	await await_idle_frame()
	var left := 0
	for child: Node in deck.get_children():
		if not child.is_queued_for_deletion():
			left += 1
	assert_int(left).is_equal(0)
