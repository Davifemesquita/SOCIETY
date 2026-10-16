class_name AchievementsDialog
extends PanelContainer
## Conquistas (Fase 12): todas, com ícone, título e descrição; as ganhas com a data, as outras
## apagadas. No topo, quantas já foram ganhas.

signal closed()


func _init() -> void:
	name = "Achievements"
	theme_type_variation = &"MenuPanel"
	custom_minimum_size = Vector2(720, 0)
	var data := GameData.get_default()
	var store := Achievements.shared()
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	column.add_child(UiKit.header("ACHIEVEMENTS_TITLE", func() -> void: closed.emit()))
	var won := data.achievements.filter(func(def: AchievementDef) -> bool: return store.is_unlocked(def.id)).size()
	var summary := UiKit.label(TranslationServer.translate("ACHIEVEMENTS_COUNT") % [won, data.achievements.size()], &"DimLabel")
	summary.name = "Count"
	column.add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 8)
	scroll.add_child(list)
	for def: AchievementDef in data.achievements:
		list.add_child(_row(def, store))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	buttons.add_child(UiKit.button("UI_BACK", "action_back", func() -> void: closed.emit()))


func _row(def: AchievementDef, store: Achievements) -> Control:
	var row := HBoxContainer.new()
	row.name = "Achievement_" + def.id
	row.add_theme_constant_override(&"separation", 12)
	var unlocked := store.is_unlocked(def.id)
	var icon := UiKit.icon_rect(Icons.get_icon(def.icon), 40)
	if not unlocked:
		icon.modulate = Color(1, 1, 1, 0.3)
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UiKit.label(def.title_key(), &"" if unlocked else &"DimLabel"))
	var description := UiKit.label(description_of(def), &"DimLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(description)
	var state_text: String = TranslationServer.translate("ACHIEVEMENT_LOCKED")
	if unlocked:
		state_text = TranslationServer.translate("ACHIEVEMENT_WON_ON") % Fmt.date(store.unlocked[def.id])
	var state := UiKit.label(state_text, &"DimLabel")
	state.name = "State"
	if unlocked:
		UiPalette.paint(state, UiPalette.Status.GOOD)
	row.add_child(state)
	return row


## A descrição com a quantidade (a classe, no caso da população).
static func description_of(def: AchievementDef) -> String:
	var text := TranslationServer.translate(def.description_key())
	if not text.contains("%"):
		return text
	if def.kind == AchievementDef.Kind.TIER_POPULATION:
		var tier := GameData.get_default().tier(def.target)
		return text % [Fmt.integer(def.amount), TranslationServer.translate(tier.name_key).to_lower() if tier != null else ""]
	return text % Fmt.integer(def.amount)
