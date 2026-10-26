extends GdUnitTestSuite
## Kit de época (Fase 50): as regras de importação (orçamento por categoria, uma malha, frente em −Z, pivô e tamanho no
## lote, LOD, nome e crédito), a varredura da pasta e o gancho do BuildingKit (a peça entra no lugar da forma
## procedural; sem peça, nada muda). Peças sintéticas, feitas aqui.

const KIT_DIR := "user://test_kit_phase50"

var _data: GameData


func before_test() -> void:
	_data = GameData.get_default()


func after_test() -> void:
	BuildingKit.kit_root = "res://assets/kit"
	BuildingKit.forget_assets()
	if DirAccess.dir_exists_absolute(KIT_DIR):
		for file_name: String in DirAccess.get_files_at(KIT_DIR):
			DirAccess.remove_absolute(KIT_DIR.path_join(file_name))
		DirAccess.remove_absolute(KIT_DIR)


## Malha de "count" triângulos dentro da caixa centrada no lote (size_m em x e z), do chão até height_m.
static func box_mesh(count: int, size_m: Vector2, height_m: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var half := Vector3(size_m.x * 0.5, 0.0, size_m.y * 0.5)
	for k: int in count:
		var t := float(k) / maxf(count - 1, 1)
		vertices.append(Vector3(-half.x, 0.0, -half.z))
		vertices.append(Vector3(half.x, height_m * t, -half.z))
		vertices.append(Vector3(half.x * (1.0 - 2.0 * t), height_m, half.z))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func piece(count: int, size_m: Vector2, front_z: float = -2.0, meshes: int = 1) -> Node3D:
	var root := Node3D.new()
	root.name = "Peca"
	for k: int in meshes:
		var instance := MeshInstance3D.new()
		instance.name = "Corpo%d" % k
		instance.mesh = box_mesh(count, size_m, 6.0)
		root.add_child(instance)
		instance.owner = root
	if not is_nan(front_z):
		var front := Marker3D.new()
		front.name = AssetRules.FRONT_NODE
		front.position = Vector3(0.0, 0.0, front_z)
		root.add_child(front)
		front.owner = root
	return root


func _lods(on: bool) -> ConfigFile:
	var options := ConfigFile.new()
	options.set_value("params", "meshes/generate_lods", on)
	return options


func test_a_good_house_passes() -> void:
	var house := _data.building(&"house")
	var lot := Vector2(house.size) * 2.0
	var root: Node3D = auto_free(piece(5000, lot))
	var result := AssetRules.check(root, "res://assets/kit/house_peasants.glb", house, 2.0, "assets/kit/house_peasants.glb",
			_lods(true))
	assert_array(Array(result[0])).is_empty()
	assert_array(Array(result[1])).is_empty()
	assert_int(AssetRules.triangles(root)).is_equal(5000)


func test_each_rule_reports_its_problem() -> void:
	var house := _data.building(&"house")
	var lot := Vector2(house.size) * 2.0
	var credits := "assets/kit/"
	# acima do teto da casa
	var heavy: Node3D = auto_free(piece(9000, lot))
	assert_str(" ".join(AssetRules.check(heavy, "res://assets/kit/house.glb", house, 2.0, credits, _lods(true))[0])).contains("teto")
	# abaixo do piso: só aviso
	var light: Node3D = auto_free(piece(500, lot))
	var light_result := AssetRules.check(light, "res://assets/kit/house.glb", house, 2.0, credits, _lods(true))
	assert_array(Array(light_result[0])).is_empty()
	assert_str(" ".join(light_result[1])).contains("piso")
	# duas malhas, sem a frente, frente para trás, maior que o lote, sem LOD, nome e crédito
	var cases := {
		"uma malha só": piece(4000, lot, -2.0, 2),
		"sem o nó Front": piece(4000, lot, NAN),
		"+Z": piece(4000, lot, 2.0),
		"maior que o lote": piece(4000, lot * 2.0),
	}
	for expected: String in cases:
		var root: Node3D = auto_free(cases[expected])
		var problems: PackedStringArray = AssetRules.check(root, "res://assets/kit/house.glb", house, 2.0, credits, _lods(true))[0]
		assert_str(" ".join(problems)).override_failure_message(expected).contains(expected)
	var plain: Node3D = auto_free(piece(4000, lot))
	assert_str(" ".join(AssetRules.check(plain, "res://assets/kit/house.glb", house, 2.0, credits, _lods(false))[0])).contains("LOD")
	assert_str(" ".join(AssetRules.check(plain, "res://assets/kit/mill.glb", house, 2.0, credits, _lods(true))[0])).contains("id do prédio")
	assert_str(" ".join(AssetRules.check(plain, "res://assets/kit/house.glb", house, 2.0, "", _lods(true))[0])).contains("crédito")


func test_categories_and_names() -> void:
	assert_int(AssetRules.category_for(_data.building(&"house"))).is_equal(AssetRules.Category.HOUSE)
	assert_int(AssetRules.category_for(_data.building(&"bakery"))).is_equal(AssetRules.Category.FACTORY)
	assert_str(AssetRules.def_for("res://assets/kit/house_workers.glb", _data).id).is_equal("house")
	assert_object(AssetRules.def_for("res://assets/kit/nada.glb", _data)).is_null()


func test_the_scan_and_the_building_kit_hook() -> void:
	DirAccess.make_dir_recursive_absolute(KIT_DIR)
	var bakery := _data.building(&"bakery")
	var root := piece(10000, Vector2(bakery.size) * 2.0)
	var scene := PackedScene.new()
	assert_int(scene.pack(root)).is_equal(OK)
	root.free()
	assert_int(ResourceSaver.save(scene, KIT_DIR.path_join("bakery.tscn"))).is_equal(OK)
	var report := AssetRules.scan(KIT_DIR, _data, 2.0, KIT_DIR.trim_prefix("res://"))
	assert_int(report.size()).is_equal(1)
	var problems: PackedStringArray = report[KIT_DIR.path_join("bakery.tscn")][0]
	assert_array(Array(problems)).is_empty()
	# o gancho: a padaria passa a usar a peça; a casa, sem peça, segue procedural
	BuildingKit.kit_root = KIT_DIR
	BuildingKit.forget_assets()
	var sim := SimFixture.simulation(Vector2i(40, 40))
	var bakery_id := SimFixture.place(sim, &"bakery", Vector2i(5, 5))
	var house_id := SimFixture.place(sim, &"house", Vector2i(20, 5))
	var spec := BuildingKit.spec_for(sim, sim.world.building(bakery_id), 2.0)
	if spec == null:
		# sem o kit de fachadas no projeto (não acontece no repositório): nada a conferir aqui
		return
	assert_str(spec.asset).is_equal(KIT_DIR.path_join("bakery.tscn"))
	assert_int(AssetRules.triangles_of(BuildingKit.mesh(spec))).is_equal(10000)
	var house_spec := BuildingKit.spec_for(sim, sim.world.building(house_id), 2.0)
	assert_str(house_spec.asset).is_empty()
	assert_int(AssetRules.triangles_of(BuildingKit.mesh(house_spec))).is_not_equal(10000)


func test_the_repository_kit_folder_is_clean() -> void:
	# a pasta do kit de época ainda vazia (a arte é do dono): o que entrar nela tem de passar
	var credits := FileAccess.get_file_as_string("res://CREDITS.md")
	var report := AssetRules.scan("res://assets/kit", _data, 2.0, credits)
	for path: String in report:
		var problems: PackedStringArray = report[path][0]
		assert_array(Array(problems)).override_failure_message(path).is_empty()
