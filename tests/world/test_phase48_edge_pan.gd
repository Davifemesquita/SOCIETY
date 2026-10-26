extends GdUnitTestSuite
## Pan pela borda (Fase 48, achado medindo a 4.8): sem um movimento de verdade do mouse na janela a câmera não anda
## sozinha, mesmo com a posição lida num canto (xvfb, área de trabalho escondida, janela recém-aberta).


func _camera() -> StrategyCamera:
	var camera: StrategyCamera = auto_free(StrategyCamera.new())
	add_child(camera)
	camera.setup(GameConfig.get_default(), Rect2(0, 0, 1000, 1000))
	return camera


func test_no_edge_pan_before_the_mouse_moves() -> void:
	var camera := _camera()
	assert_bool(camera.mouse_seen).is_false()
	assert_vector(camera._edge_input()).is_equal(Vector2.ZERO)
	var focus := camera.rig.focus
	for frame: int in 10:
		camera._process(0.1)
	assert_vector(camera.rig.focus).is_equal(focus)


func test_a_real_mouse_motion_arms_it() -> void:
	var camera := _camera()
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(500, 400)
	camera._input(motion)
	assert_bool(camera.mouse_seen).is_true()
	remove_child(camera)
