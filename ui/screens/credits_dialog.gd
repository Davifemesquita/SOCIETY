class_name CreditsDialog
extends PanelContainer
## Créditos (seções 10 e 14): lidos do CREDITS.md, o mesmo arquivo do repositório (vai junto na
## exportação). Cada linha da tabela vira um item: nome, autor, licença e link.

signal closed()

const CREDITS_PATH := "res://CREDITS.md"

var text := RichTextLabel.new()


func _init() -> void:
	name = "Credits"
	theme_type_variation = &"MenuPanel"
	custom_minimum_size = Vector2(760, 560)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	add_child(column)
	column.add_child(UiKit.header("CREDITS_TITLE", func() -> void: closed.emit()))
	text.bbcode_enabled = true
	text.fit_content = false
	text.scroll_active = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(700, 440)
	text.selection_enabled = true
	column.add_child(text)
	text.text = bbcode(entries(FileAccess.get_file_as_string(CREDITS_PATH)))


## Linhas da tabela do CREDITS.md: [item, autor, link, licença]. O cabeçalho fica de fora.
static func entries(markdown: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	for line: String in markdown.split("\n"):
		if not line.begins_with("|") or line.begins_with("|---") or line.begins_with("| Item"):
			continue
		var cells := line.trim_prefix("|").trim_suffix("|").split("|")
		if cells.size() < 4:
			continue
		var entry := PackedStringArray()
		for index: int in 4:
			entry.append(cells[index].strip_edges().replace("`", ""))
		result.append(entry)
	return result


static func bbcode(items: Array[PackedStringArray]) -> String:
	var lines: PackedStringArray = ["[center][b]%s[/b]\n%s[/center]\n" % [TranslationServer.translate("GAME_TITLE"),
			TranslationServer.translate("CREDITS_INTRO")]]
	for entry: PackedStringArray in items:
		lines.append("[b]%s[/b] — %s\n[i]%s[/i] · %s\n" % [_escape(entry[0]), _escape(entry[1]), _escape(entry[3]), _escape(entry[2])])
	return "\n".join(lines)


static func _escape(value: String) -> String:
	return value.replace("[", "[lb]")
