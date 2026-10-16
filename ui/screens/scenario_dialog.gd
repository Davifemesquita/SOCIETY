class_name ScenarioDialog
extends PanelContainer
## Cenários (Fase 12): cada um com título, descrição, objetivo e prazo, e o selo de vencido quando a
## conquista dele já foi ganha. Jogar avisa pelo sinal start com o id do cenário.

signal start(scenario_id: StringName)
signal closed()


func _init() -> void:
	name = "Scenarios"
	theme_type_variation = &"MenuPanel"
	custom_minimum_size = Vector2(760, 0)
	var data := GameData.get_default()
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	add_child(column)
	column.add_child(UiKit.header("SCENARIOS_TITLE", func() -> void: closed.emit()))
	for def: ScenarioDef in data.scenarios:
		column.add_child(_row(def, data))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	buttons.add_child(UiKit.button("UI_BACK", "action_back", func() -> void: closed.emit()))


func _row(def: ScenarioDef, data: GameData) -> Control:
	var row := HBoxContainer.new()
	row.name = "Scenario_" + def.id
	row.add_theme_constant_override(&"separation", 14)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var title := UiKit.label(def.title_key(), &"HeaderLabel")
	text.add_child(title)
	var description := UiKit.label(def.description_key())
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 520
	text.add_child(description)
	var goal := UiKit.label(ObjectiveText.describe(def.victory_kind, def.victory_target, def.victory_amount, data)
			+ "  ·  " + ObjectiveText.deadline(def.time_limit_min), &"DimLabel")
	text.add_child(goal)
	var won := Achievements.shared().is_unlocked(StringName("won_" + def.id))
	if won:
		var badge := UiKit.label("SCENARIO_WON")
		badge.name = "Won"
		UiPalette.paint(badge, UiPalette.Status.GOOD)
		text.add_child(badge)
	var play := UiKit.button("SCENARIO_PLAY", "action_new_game", func() -> void: start.emit(def.id), "SCENARIO_PLAY_TIP")
	play.name = "Play"
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(play)
	return row
