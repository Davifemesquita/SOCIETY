extends Node
## Fase 387: o jogador-robô joga o jogo de verdade (o arquipélago do jogo novo, com eventos, rivais e riscos) em algumas
## sementes e grava o que travou: o que não coube, o que ficou preso, os invariantes quebrados e os erros do log.
##   godot --headless --path . res://tools/real_game_report.tscn -- docs/jogo_real.md [minutos] [semente,semente,...]

const DEFAULT_MINUTES := 120.0
const DEFAULT_SEEDS: Array[int] = [1840, 7, 2024]
const STEP_S := 600.0


class Catcher extends Logger:
	var errors: PackedStringArray = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s %s (%s, tipo %d)" % [file, line, code, rationale, function, error_type])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else ProjectSettings.globalize_path("user://jogo_real.md")
	var minutes := float(args[1]) if args.size() > 1 else DEFAULT_MINUTES
	var seeds: Array[int] = DEFAULT_SEEDS.duplicate()
	if args.size() > 2:
		seeds.clear()
		for text: String in args[2].split(","):
			seeds.append(text.to_int())
	var catcher := Catcher.new()
	OS.add_logger(catcher)
	var lines: PackedStringArray = ["# O robô no jogo de verdade (Fase 387)", "",
			"Gerado por `tools/real_game_report.tscn` em %s: %.0f min de jogo por semente, arquipélago do jogo novo com eventos, rivais e riscos ligados." % [Time.get_date_string_from_system(), minutes], ""]
	for seed_value: int in seeds:
		var started := Time.get_ticks_msec()
		var player := TerrainAutoPlayer.on_archipelago(seed_value)
		var errors_before := catcher.errors.size()
		var timeline: PackedStringArray = []
		var elapsed := 0.0
		while elapsed < minutes * 60.0:
			player.play(STEP_S)
			elapsed += STEP_S
			timeline.append("- " + player.summary())
		lines.append("## Semente %d (%.0f s)" % [seed_value, (Time.get_ticks_msec() - started) / 1000.0])
		lines.append("")
		lines.append_array(timeline)
		lines.append("")
		lines.append("```")
		lines.append(player.report())
		var counted: Dictionary[String, int] = {}
		for i: int in range(errors_before, catcher.errors.size()):
			counted[catcher.errors[i]] = counted.get(catcher.errors[i], 0) + 1
		lines.append("erros no log (%d, %d diferentes):" % [catcher.errors.size() - errors_before, counted.size()])
		for text: String in counted:
			lines.append("  %d× %s" % [counted[text], text])
		lines.append("```")
		lines.append("")
		print("semente %d pronta" % seed_value)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("relatório em ", path)
	get_tree().quit()
