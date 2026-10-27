extends GdUnitTestSuite
## Fase 57: as pedras soltas dos barrancos e do litoral são a rocha gerada (RockModel) com o material da RockView, e
## não mais as lajes do Kenney.

var _world: WorldState
var _config: GameConfig


func before() -> void:
	_config = GameConfig.get_default()
	_world = ArchipelagoGenerator.new_world(1840, _config, GameData.get_default())


## A grade da ilha que contém o ponto.
func _grid_at(point: Vector3) -> IslandGrid:
	for index: int in _world.islands.size():
		var grid := _world.island(index)
		if grid.in_bounds(grid.world_to_cell(point)):
			return grid
	return null


## O modelo da camada pelo nome ("Trees6", ou "@Trees6@123" quando o Godot renomeia o repetido de outro trecho); -1 se
## não for de árvore ou pedra.
func _model(layer: MultiMeshInstance3D) -> int:
	var clean := String(layer.name).trim_prefix("@").get_slice("@", 0)
	return int(clean.trim_prefix("Trees")) if clean.begins_with("Trees") else -1


func _rock_nodes(view: TreeView) -> Array[MultiMeshInstance3D]:
	var first := TreeView.BROADLEAF.size() + TreeView.CONIFER.size()
	var result: Array[MultiMeshInstance3D] = []
	for node: Node in view.get_children():
		var layer := node as MultiMeshInstance3D
		if layer == null:
			continue
		var model := _model(layer)
		if model >= first and model < first + TreeView.ROCKS:
			result.append(layer)
	return result


func test_loose_rocks_use_the_generated_rock() -> void:
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(_world, GameData.get_default(), _config)
	var layers := _rock_nodes(view)
	assert_int(layers.size()).override_failure_message("nenhuma pedra solta desenhada").is_greater(0)
	var shapes: Dictionary[int, bool] = {}
	var total := 0
	for layer: MultiMeshInstance3D in layers:
		var mesh := layer.multimesh.mesh as ArrayMesh
		var model := _model(layer) - TreeView.BROADLEAF.size() - TreeView.CONIFER.size()
		var original := RockModel.mesh(model)
		# a mesma malha da RockModel (mesmos vértices), numa cópia com o material
		assert_int(mesh.surface_get_array_len(0)).is_equal(original.surface_get_array_len(0))
		assert_object(original.surface_get_material(0)).override_failure_message("a malha guardada ganhou material").is_null()
		var material := mesh.surface_get_material(0) as StandardMaterial3D
		assert_object(material).is_not_null()
		assert_bool(material.uv1_world_triplanar).is_true()
		assert_bool(material.albedo_color.is_equal_approx(RockView.TINT)).is_true()
		shapes[model] = true
		total += layer.multimesh.instance_count
	print("pedras soltas: %d em %d formas" % [total, shapes.size()])
	assert_int(shapes.size()).is_greater(1)
	remove_child(view)


func test_loose_rock_is_taller_than_wide_and_sits_in_the_ground() -> void:
	var view: TreeView = auto_free(TreeView.new())
	add_child(view)
	view.setup(_world, GameData.get_default(), _config)
	var layers := _rock_nodes(view)
	assert_int(layers.size()).is_greater(0)
	var multimesh := layers[0].multimesh
	for i: int in mini(multimesh.instance_count, 20):
		var placed := multimesh.get_instance_transform(i)
		var wide := placed.basis.x.length()
		var tall := placed.basis.y.length()
		assert_float(tall / wide).is_equal_approx(TreeView.ROCK_TALL, 0.001)
		# raio entre 0,7 e 1,3 vez o tamanho e a base enterrada (o fundo da RockModel abaixo da malha)
		assert_float(wide).is_between(TreeView.ROCK_SIZE_M * 0.69, TreeView.ROCK_SIZE_M * 1.31)
		var grid := _grid_at(placed.origin)
		assert_object(grid).is_not_null()
		var ground := grid.height_at(placed.origin.x, placed.origin.z) \
				+ TerrainDetail.offset_at(grid, _config, placed.origin.x, placed.origin.z)
		assert_float(placed.origin.y + RockModel.BOTTOM * tall).is_less(ground - 0.2)
	remove_child(view)
