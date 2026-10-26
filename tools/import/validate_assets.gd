extends Node
## Confere o kit de época (Fase 50) pelas AssetRules: cada peça de res://assets/kit/ (ou da pasta dada depois de "--").
## Sai com código 1 se alguma tiver problema (serve para o CI). Cena e não --script: o jogo inteiro (autoloads) carrega.
##   godot --headless --path . res://tools/import/validate_assets.tscn [-- <pasta>]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var root_dir := args[0] if not args.is_empty() else BuildingKit.kit_root
	var credits := FileAccess.get_file_as_string("res://CREDITS.md")
	var report := AssetRules.scan(root_dir, GameData.get_default(), GameConfig.get_default().cell_size_m, credits)
	var failed := 0
	for path: String in report:
		var problems: PackedStringArray = report[path][0]
		var warnings: PackedStringArray = report[path][1]
		print("%s: %s" % [path, "ok" if problems.is_empty() else "; ".join(problems)])
		for warning: String in warnings:
			print("    aviso: ", warning)
		if not problems.is_empty():
			failed += 1
	print("validate_assets: %d arquivos, %d com problema (em %s)" % [report.size(), failed, root_dir])
	get_tree().quit(1 if failed > 0 else 0)
