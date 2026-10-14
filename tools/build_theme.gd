extends SceneTree
## Grava o Theme único (ui/theme/society_theme.tres) a partir do ThemeBuilder.
##   tools/godot.sh godot --headless --path . --script res://tools/build_theme.gd

const PATH := "res://ui/theme/society_theme.tres"


func _init() -> void:
	# o papel primeiro: o Theme carrega a textura dele
	ThemeBuilder.paper_image(192, ThemeBuilder.PAPER_FRAME_PX, 1840).save_png(ThemeBuilder.PAPER_TEXTURE)
	ThemeBuilder.paper_image(384, ThemeBuilder.PAPER_FRAME_PX, 1841).save_png(ThemeBuilder.MENU_TEXTURE)
	var error := ResourceSaver.save(ThemeBuilder.build(), PATH)
	print("build_theme: %s (%s)" % [PATH, error_string(error)])
	quit()
