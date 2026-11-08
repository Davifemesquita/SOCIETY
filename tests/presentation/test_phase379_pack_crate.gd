extends GdUnitTestSuite
## Fase 379: com o MegaKit, o caixote da carga (pilhas de estoque, carroças, cais, convés e colheita) é o caixote de tábuas do
## pacote, na madeira dele (UV2.x = 2), do mesmo tamanho da peça de antes; sem o MegaKit, o do Kenney Pirate Kit.


func after_test() -> void:
	BuildingKit.reset_megakit()


func _wood_vertices(mesh: Mesh) -> int:
	var count := 0
	for surface: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		if not arrays[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
			continue
		var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		for uv2: Vector2 in uv2s:
			count += int(is_equal_approx(uv2.x, 2.0))
	return count


func test_the_crate_is_the_pack_one_with_the_megakit() -> void:
	BuildingKit.use_megakit(true)
	var crate := CargoKit.mesh(GoodDef.Pile.CRATE)
	assert_object(crate).is_not_null()
	assert_int(_wood_vertices(crate)).is_greater(0)
	var box := crate.get_aabb()
	assert_float(maxf(box.size.x, box.size.z)).is_equal_approx(CargoKit.ITEM_M, 0.01)
	assert_float(box.position.y).is_equal_approx(0.0, 0.01)
	assert_object(crate.surface_get_material(0)).is_same(BuildingMaterials.kit())


func test_the_kenney_keeps_its_crate() -> void:
	BuildingKit.use_megakit(false)
	var crate := CargoKit.mesh(GoodDef.Pile.CRATE)
	assert_object(crate).is_not_null()
	assert_int(_wood_vertices(crate)).is_equal(0)
	assert_object(crate.surface_get_material(0)).is_not_same(BuildingMaterials.kit())
