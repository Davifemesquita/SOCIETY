extends GdUnitTestSuite
## Fase 384: com o MegaKit, o lanço da cerca do pasto é a cerca de tábuas do pacote, no mesmo lanço de 1 m em +x (o mourão no
## começo), no material do kit; sem ele, a cerca gerada de sempre.

var _sim: Simulation


func before_test() -> void:
	_sim = SimFixture.simulation(Vector2i(80, 40))
	_sim.free_build = true
	_sim.ignore_terrain = true


func after_test() -> void:
	BuildingKit.reset_megakit()


func _view() -> CropView:
	var view: CropView = auto_free(CropView.new())
	add_child(view)
	view.setup(_sim)
	return view


func test_the_piece_fits_the_fence_span() -> void:
	BuildingKit.use_megakit(true)
	var mesh := CropView.pasture_fence_pack()
	assert_object(mesh).is_not_null()
	var box := mesh.get_aabb()
	assert_float(box.position.x).is_equal_approx(0.0, 0.05)
	assert_float(box.end.x).is_equal_approx(CropView.FENCE_STEP_M, 0.05)
	assert_float(box.position.y).is_equal_approx(0.0, 0.05)
	assert_float(box.end.y).is_between(0.8, 1.1)
	assert_float(box.size.z).is_less(0.3)


func test_the_fence_layer_takes_the_pack_fence() -> void:
	BuildingKit.use_megakit(true)
	var layer := _view().get_node("Fence") as MultiMeshInstance3D
	assert_object(layer.multimesh.mesh).is_same(CropView.pasture_fence_pack())
	assert_object(layer.material_override).is_same(BuildingMaterials.kit())


func test_the_kenney_keeps_the_generated_fence() -> void:
	BuildingKit.use_megakit(false)
	assert_object(CropView.pasture_fence_pack()).is_null()
	var layer := _view().get_node("Fence") as MultiMeshInstance3D
	assert_object(layer.material_override).is_not_same(BuildingMaterials.kit())
