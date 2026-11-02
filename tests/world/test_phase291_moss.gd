extends GdUnitTestSuite
## Musgo nas saliências (Fase 291): o mesmo musgo no terreno (só onde há rocha) e nas pedras (na do mar, só acima da pedra
## molhada), nas partes quase planas e nos ressaltos das camadas, em manchas, mais no lado da sombra fixo (não anda com o sol);
## os shaders compilam com os uniformes novos (com tela).

const INCLUDE := "res://shaders/rock_strata.gdshaderinc"


func test_both_shaders_paint_the_moss() -> void:
	var terrain := FileAccess.get_file_as_string("res://shaders/terrain.gdshader")
	var rock := FileAccess.get_file_as_string("res://shaders/sea_rock.gdshader")
	var rock_block := terrain.find("if (rock > 0.001) {\n\t\trock_a.rgb *= strata_factor")
	assert_int(terrain.find("moss_amount(world_position, world_normal)")).is_greater(rock_block)
	assert_str(rock).contains("float moss = moss_amount(world_position, world_normal)")
	# na pedra do mar, acima da pedra molhada
	assert_str(rock).contains("moss *= smoothstep(wet_top_m, wet_top_m + 0.6, world_position.y);")


func test_the_moss_sits_on_ledges_and_flats_in_a_fixed_shade() -> void:
	var code := FileAccess.get_file_as_string(INCLUDE)
	var body := code.substr(code.find("float moss_amount("))
	assert_str(body).contains("smoothstep(moss_flat.x, moss_flat.y, normal_w.y)")
	assert_str(body).contains("moss_shade_dir")
	# o lado da sombra é fixo: nada do sol do dia
	assert_str(body).not_contains("sun_direction")
	assert_str(code).contains("uniform vec3 moss_color : source_color")


func test_the_shaders_compile_with_the_moss_uniforms() -> void:
	for path: String in ["res://shaders/terrain.gdshader", "res://shaders/sea_rock.gdshader"]:
		var names: Array[StringName] = []
		for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
			var raw: String = entry["name"]
			names.append(StringName(raw))
		if DisplayServer.get_name() == "headless":
			# sem tela (dummy) a lista vem vazia: os shaders só compilam com GPU
			return
		# com tela, a lista vazia é o shader que não compilou
		assert_array(names).override_failure_message(path).is_not_empty()
		for uniform_name: StringName in [&"moss_flat", &"moss_patch_m", &"moss_amount_max", &"moss_shade_dir", &"moss_color"]:
			assert_bool(names.has(uniform_name)).override_failure_message("%s: %s" % [path, uniform_name]).is_true()
