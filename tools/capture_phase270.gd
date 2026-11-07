extends "res://tools/capture_phase255.gd"
## Roteiro de verificação visual da Fase 270 (corvos no campo): a vila do ciclo da cor (semente 1840, 10h30) com as fazendas
## recém-plantadas; os corvos nos vãos entre as fileiras, de perto e de meia distância. Precisa de GPU; no PC do dono roda na
## área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 60000 res://tools/capture_phase270.tscn -- <pasta>


func _run() -> void:
	var game := _open_game()
	var points: Array[Vector3] = await _build_town(game)
	for id: int in game.simulation.world.buildings:
		var farm := game.simulation.world.building(id)
		if farm.def_id in [&"wheat_farm", &"potato_farm"]:
			farm.progress = 0.1
	game.crop_view.refresh()
	game.crow_view.refresh()
	print("corvos: ", game.crow_view.crow_count())
	var shot := 0
	for spot: Vector3 in game.crow_view.spots:
		await _shot(game, "corvo_%d.png" % shot, spot, 4.0, 0.6 + shot)
		shot += 1
		if shot >= 2:
			break
	await _shot(game, "corvos_campos.png", points[1], 30.0, PI + 0.6)
	get_tree().quit()
