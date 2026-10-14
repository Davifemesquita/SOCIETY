extends SceneTree
## Grava o Theme único (ui/theme/society_theme.tres) a partir do ThemeBuilder.
##   tools/godot.sh godot --headless --path . --script res://tools/build_theme.gd

const PATH := "res://ui/theme/society_theme.tres"


func _init() -> void:
	var error := ResourceSaver.save(ThemeBuilder.build(), PATH)
	print("build_theme: %s (%s)" % [PATH, error_string(error)])
	quit()
