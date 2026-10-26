class_name BreakdownLabel
extends Label
## Rótulo com a dica que decompõe o número (Fase 47): ao passar o mouse, pede as parcelas a "provider" (só nessa
## hora: nada é calculado no tick nem a cada refresco da janela) e mostra uma linha por fonte, + o que entra e − o que
## sai, por minuto, e a soma embaixo.

## Devolve Array[Breakdown.Source] (chamado só quando a dica abre).
var provider: Callable
## Casas decimais (2 para t/min, 0 para moedas).
var places: int = 2
## Chave do título da dica (com %s para o nome do que se decompõe, se houver).
var title_key: String = ""
var title_arg: String = ""
var data: GameData


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	# sem texto de dica o Godot não chama _make_custom_tooltip
	tooltip_text = " "


func _make_custom_tooltip(_for_text: String) -> Object:
	if not provider.is_valid():
		return null
	var raw: Array = provider.call()
	var sources: Array[Breakdown.Source] = []
	sources.assign(raw)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.x = 300
	label.text = text_of(sources, data, places, tr(title_key) % title_arg if title_arg != "" else tr(title_key))
	return label


## O texto da dica (BBCode): o título, uma linha por parcela e a soma. Estático para os testes.
static func text_of(sources: Array[Breakdown.Source], game_data: GameData, decimals: int, title: String) -> String:
	var lines: PackedStringArray = []
	if title != "":
		lines.append("[b]%s[/b]" % title)
	if sources.is_empty():
		lines.append(TranslationServer.translate("BREAKDOWN_NOTHING"))
	for source: Breakdown.Source in sources:
		var color := UiPalette.status(UiPalette.Status.GOOD if source.per_min >= 0.0 else UiPalette.Status.BAD)
		lines.append("[color=#%s]%s[/color]  %s" % [color.to_html(false), amount(source.per_min, decimals), name_of(source, game_data)])
	lines.append("= %s %s" % [amount(Breakdown.total(sources), decimals), TranslationServer.translate("BREAKDOWN_PER_MIN")])
	return "\n".join(lines)


## Com sinal sempre (+ e −), no formato do idioma.
static func amount(value: float, decimals: int) -> String:
	var shown := Fmt.integer(absf(value))
	if decimals > 0:
		# casas fixas (o Fmt.decimal deixa "2,0" com duas casas pedidas); os milhares e a vírgula do idioma
		var parts := (("%." + str(decimals) + "f") % absf(value)).split(".")
		var comma := "," if TranslationServer.get_locale().begins_with("pt") else "."
		shown = Fmt.integer(float(parts[0])) + comma + parts[1]
	var zero := is_zero_approx(snappedf(value, pow(10.0, -decimals)))
	return ("+" if value >= 0.0 or zero else "−") + shown


static func name_of(source: Breakdown.Source, game_data: GameData) -> String:
	match source.kind:
		Breakdown.Kind.BUILDING:
			if source.id == &"":
				return TranslationServer.translate("BREAKDOWN_BUILDINGS")
			var name := TranslationServer.translate(game_data.building(source.id).name_key)
			return name + (" ×%d" % source.count if source.count > 1 else "")
		Breakdown.Kind.TIER:
			return TranslationServer.translate(game_data.tier(source.id).name_key)
		Breakdown.Kind.SHIPS:
			return TranslationServer.translate("BREAKDOWN_SHIPS") % source.count
		Breakdown.Kind.SALARIES:
			return TranslationServer.translate("BREAKDOWN_SALARIES")
		_:
			return TranslationServer.translate("BREAKDOWN_TREATY")
