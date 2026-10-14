extends SceneTree
## Compila todos os scripts do jogo (fora de addons/) e lista os que têm erro: pega o erro de
## tipo antes de rodar a suíte inteira.
##   tools/godot.sh godot --headless --path . --script res://tools/check_scripts.gd


func _initialize() -> void:
	var failed := 0
	var total := 0
	for path: String in _scripts("res://"):
		total += 1
		var script: Script = load(path)
		if script == null or not script.can_instantiate() and not script.is_abstract():
			failed += 1
			print("ERRO: ", path)
	print("check_scripts: %d scripts, %d com erro" % [total, failed])
	quit(1 if failed > 0 else 0)


func _scripts(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		if sub in ["addons", ".godot", "exportado", "reports"]:
			continue
		found.append_array(_scripts(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			found.append(dir.path_join(file))
	return found
