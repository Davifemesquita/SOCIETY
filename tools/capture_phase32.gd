extends "res://tools/capture_phase5.gd"
## Roteiro de verificação visual da Fase 32 (sem tela, roda no xvfb):
##   tools/godot.sh godot --path . --resolution 1920x1080 --quit-after 400000 res://tools/capture_phase32.tscn -- <pasta>
## O conjunto padrão do roteiro de melhorias (docs/plano_melhorias.md) no arquipélago da semente 1840, com a vila da
## Fase 5 montada: o arquipélago (1.500 m), a ilha principal (420 m), a vila no relevo (110 m), o litoral (70 m), a
## jazida com a prévia da mina (55 m) e a vila de perto (40 m), em cada nível gráfico, para comparar o
## antisserrilhado. Os arquivos levam o nível na frente (low_07_vila_no_relevo.png). CAPTURA_NIVEIS=0,2 escolhe os
## níveis (padrão: os quatro; o alto e o ultra por software levam ~30 s por captura).


func _run() -> void:
	_sim = _game.simulation
	var grid := _sim.world.island(0)
	_set_hour(11.0)
	var post := SiteFinder.find(_sim, &"trading_post", 0, Vector2i(grid.size.x / 2, 0))
	var post_origin: Vector2i = post[0]
	var post_rotation: int = post[1]
	var mine := SiteFinder.find(_sim, &"coal_mine", 0, grid.size / 2)
	var mine_origin: Vector2i = mine[0]
	_build_village(post_origin, post_rotation)
	_sim.run_ticks(roundi(240.0 / _sim.config.tick_interval()))
	var bounds := _game.world_bounds()
	var levels := PackedStringArray(["0", "1", "2", "3"])
	if not OS.get_environment("CAPTURA_NIVEIS").is_empty():
		levels = OS.get_environment("CAPTURA_NIVEIS").split(",")
	for level_text: String in levels:
		Settings.set_graphics_preset(level_text.to_int())
		Settings.apply()
		var prefix := String(Settings.preset().id) + "_"
		print("nível %s: AA de tela %d, FSR %s" % [Settings.preset().id, Settings.preset().screen_aa_for(Settings.render_scale),
				Settings.preset().uses_temporal(Settings.render_scale)])
		await _shot(prefix + "01_arquipelago.png", Vector3(bounds.get_center().x, 0.0, bounds.get_center().y), 1500.0, 0.0)
		await _shot(prefix + "02_ilha_principal.png", grid.cell_world(grid.size / 2), 420.0, 0.0)
		await _shot(prefix + "07_vila_no_relevo.png", grid.cell_world(post_origin), 110.0, 0.6)
		await _shot(prefix + "03_litoral.png", grid.cell_world(post_origin), 70.0, 0.6)
		_game.tool.island_id = 0
		_game.tool.start_building(_sim.data.building(&"coal_mine"))
		_game.tool.hover(mine_origin + Vector2i(2, 2))
		await _shot(prefix + "06_mina_na_jazida.png", grid.cell_world(mine_origin), 55.0, 0.0)
		_game.tool.cancel()
		await _shot(prefix + "10_vila_de_perto.png", grid.cell_world(post_origin), 40.0, 0.6)
	get_tree().quit()
