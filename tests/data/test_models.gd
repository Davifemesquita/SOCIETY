extends GdUnitTestSuite
## Modelos de terceiros (Kenney, CC0): todo navio aponta um .glb que existe e tem o tamanho do tipo
## depois de esticado; a carroça vira uma malha só (o MultiMesh desenha uma).


func test_every_ship_has_a_model_with_its_length() -> void:
	for def: ShipDef in GameData.get_default().ships:
		var path := ShipView.MODEL_DIR % def.model
		assert_bool(ResourceLoader.exists(path)).override_failure_message(path).is_true()
		var model := (load(path) as PackedScene).instantiate() as Node3D
		var size := ShipView._model_size(model)
		assert_float(size.z).override_failure_message(String(def.id)).is_greater(size.x)
		model.free()


func test_cart_is_one_textured_mesh() -> void:
	var mesh := CartView.model_mesh()
	assert_object(mesh).is_not_null()
	assert_int(mesh.get_surface_count()).is_equal(1)
	assert_float(mesh.get_aabb().size.z).is_equal_approx(CartView.MODEL_LENGTH_M, 0.05)
	var material := mesh.surface_get_material(0) as StandardMaterial3D
	assert_object(material.albedo_texture).is_not_null()
