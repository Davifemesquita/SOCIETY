extends Node
## Relatório de balanceamento (Fase 10): o jogador-robô joga 3 horas na ilha plana e a linha do
## tempo vai para docs/balanceamento.md (ou para o caminho dado), com população por classe, saldo, o
## pior saldo e o que travou a fila. Use junto da planilha (tools/godot.sh planilha) ao mexer nos números.
##   tools/godot.sh godot --headless --path . res://tools/balance_report.tscn -- "$PWD/docs/balanceamento.md"

const STEP_S := 900.0
const DURATION_S := 3.0 * 3600.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else ProjectSettings.globalize_path("user://balanceamento.md")
	var player := AutoPlayer.create()
	var sim := player.simulation
	var rows: PackedStringArray = []
	var tiers := sim.data.tiers
	var header := "| min | " + " | ".join(tiers.map(func(tier: TierDef) -> String: return tr(tier.name_key))) + " | casas | saldo | renda/min | manutenção/min | próximo da fila | parado por |"
	rows.append(header)
	rows.append("|" + "---|".repeat(tiers.size() + 7))
	var elapsed := 0.0
	while elapsed < DURATION_S:
		player.play(STEP_S)
		elapsed += STEP_S
		var world := sim.world
		var cells: Array[String] = ["%.0f" % (elapsed / 60.0)]
		for tier: TierDef in tiers:
			cells.append(str(world.population(tier.id)))
		cells.append(str(player.houses.size()))
		cells.append("%.0f" % world.money)
		cells.append("%.0f" % world.income_per_min)
		cells.append("%.0f" % world.upkeep_per_min)
		cells.append(String(player.next_in_queue()))
		cells.append(String(player.blocked_reason()))
		rows.append("| " + " | ".join(cells) + " |")
	var text := """# Balanceamento — partida do jogador-robô

Gerado por `tools/balance_report.tscn` em %s. O robô (`tools/auto_player.gd`) joga na ilha plana,
dificuldade normal, pagando cada prédio, esperando material e desbloqueio, com carroças e armazéns;
corrige faltas pondo o produtor na frente da fila e pausa fábrica com o estoque cheio.

- Pior saldo: **%.0f** aos %.0f min (limite para construir: %.0f).
- Prédios no fim: %d; casas: %d.

%s
""" % [Time.get_datetime_string_from_system(), player.lowest_money, player.lowest_at / 60.0,
			sim.config.min_balance_for(sim.world.difficulty), sim.world.buildings.size(), player.houses.size(), "\n".join(rows)]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("balance_report: ", path)
	get_tree().quit()
