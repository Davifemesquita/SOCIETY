extends GdUnitTestSuite
## Copa sem bolhas (Fase 327): nas folhosas, o claro e o escuro das folhas saem da copa inteira (o alto da copa claro, a base
## escura), não de cada massa (cada uma clara em cima e escura embaixo, uma bola), e o lado de cada massa virado para o meio da
## copa fica mais escuro. O pinheiro não muda.

# antes da fase, na variante 0 de perto: [correlação entre a altura e o brilho das folhas, brilho médio]
const BEFORE := {
	TreeModel.Species.OAK: Vector2(0.718, 0.868),
	TreeModel.Species.BEECH: Vector2(0.613, 0.980),
	TreeModel.Species.BIRCH: Vector2(0.368, 1.084),
	TreeModel.Species.TROPICAL_BROADLEAF: Vector2(0.659, 0.713),
	TreeModel.Species.SCOTS_PINE: Vector2(0.584, 0.903),
}


## [correlação entre a altura e o brilho (r + g + b) das folhas, brilho médio] da variante 0 de perto.
static func leaf_light(species: TreeModel.Species) -> Vector2:
	var arrays := TreeModel.mesh(species, 0).surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var heights := PackedFloat32Array()
	var lights := PackedFloat32Array()
	for i: int in vertices.size():
		var color := colors[i]
		if color.g < color.r * 1.05:
			continue
		heights.append(vertices[i].y)
		lights.append(color.r + color.g + color.b)
	var mean_y := 0.0
	var mean_l := 0.0
	for k: int in heights.size():
		mean_y += heights[k] / heights.size()
		mean_l += lights[k] / heights.size()
	var xy := 0.0
	var xx := 0.0
	var yy := 0.0
	for k: int in heights.size():
		xy += (heights[k] - mean_y) * (lights[k] - mean_l)
		xx += (heights[k] - mean_y) ** 2
		yy += (lights[k] - mean_l) ** 2
	return Vector2(xy / sqrt(xx * yy), mean_l)


func test_the_light_follows_the_whole_crown_in_the_broadleaves() -> void:
	# a luz das folhas segue a altura na copa mais que antes (o tropical, de copa larga e baixa, fica de fora da conta)
	for species: TreeModel.Species in [TreeModel.Species.OAK, TreeModel.Species.BEECH, TreeModel.Species.BIRCH]:
		var now := leaf_light(species)
		var before: Vector2 = BEFORE[species]
		assert_float(now.x).override_failure_message("espécie %d: %.3f" % [species, now.x]).is_greater(before.x + 0.05)
		assert_float(now.x).is_greater(0.75)


func test_the_forest_is_not_darker_than_phase_326() -> void:
	# a sombra por dentro não desfaz a Fase 326: o brilho médio cai no máximo 5%
	for species: TreeModel.Species in [TreeModel.Species.OAK, TreeModel.Species.BEECH, TreeModel.Species.BIRCH,
			TreeModel.Species.TROPICAL_BROADLEAF]:
		var now := leaf_light(species)
		var before: Vector2 = BEFORE[species]
		assert_float(now.y).override_failure_message("espécie %d: %.3f" % [species, now.y]).is_greater(before.y * 0.95)
		assert_float(now.y).is_less_equal(before.y * 1.001)


func test_the_pine_keeps_its_masses() -> void:
	var now := leaf_light(TreeModel.Species.SCOTS_PINE)
	var before: Vector2 = BEFORE[TreeModel.Species.SCOTS_PINE]
	assert_float(now.x).is_equal_approx(before.x, 0.002)
	assert_float(now.y).is_equal_approx(before.y, 0.002)


func test_the_crown_constants() -> void:
	assert_float(TreeModel.CROWN_ROUND).is_greater(0.65)
	assert_float(TreeModel.CROWN_ROUND).is_less(1.0)
	assert_float(TreeModel.CROWN_WHOLE).is_between(0.5, 1.0)
	assert_float(TreeModel.CROWN_INNER).is_between(0.8, 0.95)
	# o pinheiro e o abeto seguem com a normal de antes
	assert_float(TreeModel.CONIFER_ROUND).is_equal_approx(0.65, 0.0001)
