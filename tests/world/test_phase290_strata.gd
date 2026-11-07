extends GdUnitTestSuite
## Estratos na rocha (Fase 290): o mesmo fator de estratos e sulcos no terreno e nas pedras (o rock_strata.gdshaderinc), aplicado
## à cor da rocha nos dois; só na face inclinada; com a borda clara e a sombra suaves; os shaders compilam com os uniformes
## novos (com tela).

const INCLUDE := "res://shaders/rock_strata.gdshaderinc"


func _uniforms(path: String) -> Array[StringName]:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(path) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	return names


func test_both_shaders_use_the_strata() -> void:
	var terrain := FileAccess.get_file_as_string("res://shaders/terrain.gdshader")
	var rock := FileAccess.get_file_as_string("res://shaders/sea_rock.gdshader")
	for code: String in [terrain, rock]:
		assert_str(code).contains("#include \"%s\"" % INCLUDE)
	# no terreno, depois da cor cinza da rocha (Fase 261); nas pedras, também
	# só onde há rocha (o fator custava ~0,2 ms rodando em toda encosta)
	# (desde a Fase 322, no terreno, pela normal da face misturada à do vértice: blend_normal)
	var gray_at := terrain.find("rock_a.rgb = mix(rock_a.rgb, rock_gray, rock_grey_mix) * rock_light;")
	var only_rock := terrain.find("if (rock > 0.001) {", gray_at)
	assert_int(only_rock).is_greater(gray_at)
	assert_int(terrain.find("rock_a.rgb *= strata_factor(world_position, blend_normal);")).is_greater(only_rock)
	assert_int(rock.find("color *= strata_factor(world_position, world_normal);")).is_greater(
			rock.find("color = mix(color, grey, stone_grey_mix) * stone_light;"))


func test_the_strata_stay_on_slopes_and_are_gentle() -> void:
	var code := FileAccess.get_file_as_string(INCLUDE)
	assert_str(code).contains("float steep = 1.0 - smoothstep(0.55, 0.9, normal_w.y);")
	assert_str(code).contains("return 1.0;")
	for uniform_name: String in ["strata_light", "strata_shade", "gully_strength"]:
		var at := code.find("uniform float %s = " % uniform_name)
		assert_int(at).is_greater(0)
		var value := code.substr(at + uniform_name.length() + 17, 6).split(";")[0].to_float()
		assert_float(value).override_failure_message(uniform_name).is_between(0.05, 0.4)
	var layer := code.substr(code.find("uniform float strata_m = ") + 25, 6).split(";")[0].to_float()
	assert_float(layer).is_between(0.6, 2.5)


func test_the_shaders_compile_with_the_strata_uniforms() -> void:
	for path: String in ["res://shaders/terrain.gdshader", "res://shaders/sea_rock.gdshader"]:
		var names := _uniforms(path)
		if DisplayServer.get_name() == "headless":
			# sem tela (dummy) a lista vem vazia: os shaders só compilam com GPU
			return
		# com tela, a lista vazia é o shader que não compilou
		assert_array(names).override_failure_message(path).is_not_empty()
		for uniform_name: StringName in [&"strata_m", &"strata_warp_m", &"strata_light", &"strata_shade", &"gully_strength"]:
			assert_bool(names.has(uniform_name)).override_failure_message("%s: %s" % [path, uniform_name]).is_true()
