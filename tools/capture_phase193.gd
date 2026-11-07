extends "res://tools/capture_phase190.gd"
## Roteiro de verificação visual da Fase 193 (carroça de feno parada): as fazendas do roteiro da Fase 190 e as carroças de feno
## ao lado das medas, de perto e de meia distância. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase193.tscn -- <pasta>


func _shoot(game: GameScreen) -> void:
	game.hay_wagon_view.rebuild()
	print("carroças de feno: ", game.hay_wagon_view.wagon_count())
	var shot := 0
	for place: Transform3D in game.hay_wagon_view.places:
		var yaw := _away_from_farm(game, place.origin)
		await _aimed(game, "carroca_feno_%d.png" % shot, place.origin + Vector3(0.0, 0.8, 0.0), 5.5, yaw + 0.4)
		await _aimed(game, "carroca_feno_%d_longe.png" % shot, place.origin + Vector3(0.0, 1.0, 0.0), 14.0, yaw + 0.6)
		shot += 1
