extends "res://tools/capture_phase305.gd"
## Roteiro de verificação visual do ciclo da luz e da sombra (Fases 330 a 334): na semente 1840, às 10h30, a vila de cima e de
## perto, a mata alta de perto e de meia distância, a mata baixa de perto e a vila de longe (o ar). As mesmas vistas antes e
## depois de cada fase. CAPTURA_AMBIENTE ("180/0.6,135/0.6,...") tira a vila de perto e a mata alta de perto com cada giro do sol
## (sun_azimuth_offset_deg) e força da luz ambiente de dia (ambient_day_energy), com os valores na frente do nome. Precisa de GPU; no PC do dono roda na área de trabalho
## escondida:
##   godot --path . --resolution 1920x1080 --quit-after 120000 res://tools/capture_phase330.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	var grid := game.simulation.world.island(Simulation.MAIN_ISLAND)
	var high := grid.cell_world(_forest(grid, points[0], true))
	var low := grid.cell_world(_forest(grid, points[0], false))
	# CAPTURA_AGUA ("nome=valor;nome=valor|...") tira a vila de longe com cada troca de uniformes da água, uma por variante
	var water_lab := OS.get_environment("CAPTURA_AGUA")
	if water_lab != "":
		var material: ShaderMaterial = game.water_view._material
		var index := 0
		for variant: String in water_lab.split("|"):
			_set_uniforms(material, variant)
			await _shot(game, "w%d_vila_de_longe.png" % index, points[0], 420.0, 0.6)
			index += 1
		get_tree().quit()
		return
	var lab := OS.get_environment("CAPTURA_AMBIENTE")
	if OS.get_environment("CAPTURA_SOL") == "1":
		var sun := game.sky.sun()
		print("SOL sombra=", sun.shadow_enabled, " opacidade=", sun.shadow_opacity, " força=", sun.light_energy, " dir=",
				sun.global_basis.z, " distância=", sun.directional_shadow_max_distance, " modo=", sun.directional_shadow_mode,
				" ambiente=", game.sky.environment().ambient_light_energy, " céu=", game.sky.environment().ambient_light_sky_contribution,
				" ssao=", game.sky.environment().ssao_enabled)
		await _shot(game, "sol_com_sombra.png", points[0], 45.0, 0.6)
		sun.shadow_enabled = false
		await _shot(game, "sol_sem_sombra.png", points[0], 45.0, 0.6)
		get_tree().quit()
		return
	if lab != "":
		# cada valor é "giro/ambiente" (graus do sol e força da luz ambiente de dia)
		for value: String in lab.split(","):
			var parts := value.split("/")
			GameConfig.get_default().sun_azimuth_offset_deg = parts[0].to_float()
			GameConfig.get_default().ambient_day_energy = parts[1].to_float()
			game.sky.refresh()
			var prefix := "g%s_a%s" % [parts[0], parts[1]]
			await _shot(game, prefix + "_vila_de_perto.png", points[0], 45.0, 0.0)
			await _shot(game, prefix + "_mata_alta_de_perto.png", high, 70.0, 0.0)
		get_tree().quit()
		return
	await _shot(game, "01_vila_de_cima.png", points[0], 110.0, 0.6)
	await _shot(game, "02_vila_de_perto.png", points[0], 45.0, 0.6)
	await _shot(game, "03_mata_alta_de_perto.png", high, 70.0, 0.6)
	await _shot(game, "04_mata_alta.png", high, 160.0, 0.6)
	await _shot(game, "05_mata_baixa_de_perto.png", low, 70.0, 0.6)
	await _shot(game, "06_vila_de_longe.png", points[0], 420.0, 0.6)
	get_tree().quit()


## Troca uniformes do material ("nome=valor;nome=valor").
func _set_uniforms(material: ShaderMaterial, pairs: String) -> void:
	for pair: String in pairs.split(";", false):
		var parts := pair.split("=")
		if parts.size() == 2:
			material.set_shader_parameter(StringName(parts[0].strip_edges()), parts[1].to_float())
			print("uniforme ", parts[0], " = ", parts[1])
