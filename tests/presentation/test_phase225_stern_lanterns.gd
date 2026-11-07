extends GdUnitTestSuite
## Lanterna na popa (Fase 225): cada navio de modelo ganha a lanterna no meio da ré, no alto do casco junto da popa, filha do
## modelo com a escala desfeita (medidas em metros); o vidro fica atrás do pau, para fora da popa, no material dos lampiões.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(60, 40))


func _model(def: ShipDef) -> Node3D:
	return auto_free((load(ShipView.MODEL_DIR % def.model) as PackedScene).instantiate() as Node3D)


func test_the_stern_is_the_back_of_the_hull_at_its_top() -> void:
	for def: ShipDef in GameData.get_default().ships:
		var model := _model(def)
		var points := ShipRigging.hull_points(model)
		var stern := SternLantern.stern_point(points)
		var bow := ShipRigging.bow_point(points)
		# a popa do lado oposto da proa, no meio e acima da linha d'água
		assert_float(stern.z).override_failure_message(String(def.id)).is_less(bow.z)
		# no meio da largura da popa
		assert_float(absf(stern.x)).is_less(1.0)
		assert_float(stern.y).override_failure_message(String(def.id)).is_greater(1.0)
		for point: Vector3 in points:
			assert_float(point.z).is_greater_equal(stern.z - 0.001)


func test_the_view_hangs_the_lantern_on_every_ship_model() -> void:
	var view: ShipView = auto_free(ShipView.new())
	add_child(view)
	view.setup(_sim)
	for def: ShipDef in _sim.data.ships:
		if def.model.is_empty():
			continue
		var model: Node3D = auto_free(view._model(def, Color.WHITE))
		var lantern := model.get_node_or_null(^"SternLantern") as Node3D
		assert_object(lantern).override_failure_message(String(def.id)).is_not_null()
		# a escala do modelo desfeita: a lanterna fica em metros no mundo
		assert_float(lantern.scale.x * model.scale.x).is_equal_approx(1.0, 0.001)
		var glass := lantern.get_node(^"Glass") as MeshInstance3D
		assert_object(glass.material_override).is_not_null()
		assert_bool((glass.material_override as ShaderMaterial).shader.resource_path.ends_with("night_glow.gdshader")).is_true()


func test_the_glass_hangs_behind_the_pole_out_over_the_stern() -> void:
	var center := SternLantern.glass_center()
	assert_float(center.z).is_less(0.0)
	assert_float(center.y).is_between(SternLantern.POLE_M * 0.5, SternLantern.POLE_M)
	var frame := SternLantern.frame_mesh().get_aabb()
	assert_float(frame.end.y).is_less(SternLantern.POLE_M + 0.3)
	assert_float(frame.size.x).is_less(0.5)
