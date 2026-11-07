extends GdUnitTestSuite
## Barranco de terra vermelha (Fase 170): o material do terreno das ilhas tropicais leva a lama da margem do rio vermelha
## (laterita); o das temperadas fica com a do shader (marrom escura).


func test_tropical_islands_get_red_earth_banks() -> void:
	var config := GameConfig.new()
	config.island_sizes_cells = PackedInt32Array([70, 40])
	config.tropical_island_sizes_cells = PackedInt32Array([30])
	var data := GameData.get_default()
	var world := ArchipelagoGenerator.new_world(5, config, data)
	var view: TerrainView = auto_free(TerrainView.new())
	add_child(view)
	view.setup(world, config, data)
	var materials := view.materials()
	assert_int(materials.size()).is_equal(world.islands.size())
	var tropical := 0
	for index: int in world.islands.size():
		var tint: Variant = materials[index].get_shader_parameter(&"mud_tint")
		if world.is_tropical(index, data):
			tropical += 1
			assert_bool(tint is Vector3).is_true()
			var red: Vector3 = tint
			assert_bool(red.is_equal_approx(TerrainView.TROPICAL_MUD_TINT)).is_true()
			# vermelha: o vermelho bem acima do verde e do azul
			assert_float(red.x).is_greater(red.y * 1.6)
		elif tint is Vector3:
			# sem o parâmetro, vale o padrão do shader; com ele, não a cor tropical
			var temperate: Vector3 = tint
			assert_bool(temperate.is_equal_approx(TerrainView.TROPICAL_MUD_TINT)).is_false()
	assert_int(tropical).is_greater(0)
	remove_child(view)
