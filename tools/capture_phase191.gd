extends "res://tools/capture_phase190.gd"
## Roteiro de verificação visual da Fase 191 (pombal): as fazendas do roteiro da Fase 190 e os pombais no canto delas, de
## perto e de meia distância. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 res://tools/capture_phase191.tscn -- <pasta>


func _shoot(game: GameScreen) -> void:
	game.dovecote_view.rebuild()
	print("pombais: ", game.dovecote_view.dovecote_count())
	var shot := 0
	for place: Transform3D in game.dovecote_view.places:
		var yaw := _away_from_farm(game, place.origin)
		await _aimed(game, "pombal_%d.png" % shot, place.origin + Vector3(0.0, 2.9, 0.0), 4.5, yaw + 0.3)
		await _aimed(game, "pombal_%d_longe.png" % shot, place.origin + Vector3(0.0, 1.5, 0.0), 14.0, yaw + 0.5)
		shot += 1
