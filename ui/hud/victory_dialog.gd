class_name VictoryDialog
extends PanelContainer
## Fim da partida com objetivo (Fase 12): vitória ou prazo vencido, o objetivo, o tempo de jogo e o
## resumo (moradores por classe, dinheiro, ilhas, navios, prédios perdidos no fogo, encomendas
## cumpridas). Continuar fecha e a partida segue livre; o menu principal sai da partida.

signal continue_requested()
signal menu_requested()


func _init(simulation: Simulation) -> void:
	name = "Victory"
	theme_type_variation = &"MenuPanel"
	custom_minimum_size = Vector2(560, 0)
	var world := simulation.world
	var state := world.victory_state
	var won := state.outcome == VictoryState.Outcome.WON
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	var title := UiKit.label("VICTORY_WON" if won else "VICTORY_LOST", &"BigLabel")
	title.name = "Title"
	UiPalette.paint(title, UiPalette.Status.GOOD if won else UiPalette.Status.BAD)
	column.add_child(title)
	column.add_child(UiKit.label(ObjectiveText.describe(state.kind, state.target, state.amount, simulation.data), &"HeaderLabel"))
	for line: String in summary(simulation):
		column.add_child(UiKit.label(line))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override(&"separation", 12)
	column.add_child(buttons)
	var menu := UiKit.button("VICTORY_MENU", "action_back", func() -> void: menu_requested.emit())
	menu.name = "Menu"
	buttons.add_child(menu)
	var keep := UiKit.button("VICTORY_CONTINUE", "action_continue", func() -> void: continue_requested.emit(), "VICTORY_CONTINUE_TIP")
	keep.name = "Continue"
	buttons.add_child(keep)


## As linhas do resumo, já traduzidas.
static func summary(simulation: Simulation) -> PackedStringArray:
	var world := simulation.world
	var data := simulation.data
	var lines: PackedStringArray = []
	var ended := world.victory_state.ended_tick if world.victory_state.ended_tick > 0 else world.tick
	lines.append(_t("VICTORY_TIME") % Fmt.countdown(float(ended) / simulation.config.ticks_per_second))
	var people: PackedStringArray = []
	for tier: TierDef in data.tiers:
		people.append("%s %s" % [Fmt.integer(world.population(tier.id)), _t(tier.name_key)])
	lines.append(_t("VICTORY_POPULATION") % ", ".join(people))
	lines.append(_t("VICTORY_MONEY") % Fmt.integer(world.money))
	lines.append(_t("VICTORY_ISLANDS") % Fmt.integer(world.colonized_islands(data).size()))
	lines.append(_t("VICTORY_SHIPS") % [Fmt.integer(world.player_ships().size()), Fmt.integer(world.shipyard_state.ships_built)])
	lines.append(_t("VICTORY_RISKS") % [Fmt.integer(world.risks_state.buildings_lost), Fmt.integer(world.events_state.missions_done)])
	return lines


static func _t(key: String) -> String:
	return TranslationServer.translate(key)
