extends GdUnitTestSuite
## Parede sem esticado (Fase 322): a projeção triplanar da rocha e os estratos e blocos dela (Fases 290 e 310) saem da normal da
## face misturada à do vértice (na parede de uma célula, a do vértice aponta quase para cima e a rocha esticava descendo a parede);
## a normal da face sai fora do if da rocha (derivada em fluxo não uniforme não vale); o shader compila (com tela).

const TERRAIN := "res://shaders/terrain.gdshader"


func _number(code: String, name: String) -> float:
	var key := "uniform float %s = " % name
	return code.substr(code.find(key) + key.length(), 8).split(";")[0].to_float()


func test_the_rock_projection_follows_the_face() -> void:
	var code := FileAccess.get_file_as_string(TERRAIN)
	var face := code.find("vec3 face_normal = normalize(cross(dFdx(world_position), dFdy(world_position)));")
	var rock_if := code.find("if (rock > 0.001 && !use_triplanar) {")
	assert_int(face).is_greater(0)
	# antes do if da rocha: a derivada fica em fluxo uniforme
	assert_int(rock_if).is_greater(face)
	assert_int(code.find("wall_face_blend));", face)).is_between(face, rock_if)
	assert_int(code.find("vec3 blend = pow(abs(blend_normal), vec3(triplanar_sharpness));", rock_if)).is_greater(rock_if)
	# os estratos e os blocos pela mesma normal
	assert_str(code).contains("rock_a.rgb *= strata_factor(world_position, blend_normal);")
	assert_str(code).contains("rock_a.rgb *= block_factor(world_position, blend_normal);")
	# misturada, não só a da face (só ela deixava quinas duras entre triângulos vizinhos), e o expoente de antes
	assert_float(_number(code, "wall_face_blend")).is_between(0.5, 0.9)
	assert_float(_number(code, "triplanar_sharpness")).is_equal_approx(4.0, 0.001)


func test_the_shader_compiles_with_the_wall_uniforms() -> void:
	var names: Array[StringName] = []
	for entry: Dictionary in (load(TERRAIN) as Shader).get_shader_uniform_list():
		var raw: String = entry["name"]
		names.append(StringName(raw))
	if names.is_empty():
		# sem tela (dummy) a lista vem vazia: o shader só compila com GPU
		return
	for uniform_name: StringName in [&"wall_face_blend", &"triplanar_sharpness"]:
		assert_bool(names.has(uniform_name)).override_failure_message(uniform_name).is_true()
