class_name Fmt
extends RefCounted
## Números na interface no formato do idioma: 50.000 e 2,5 em pt-BR; 50,000 e 2.5 em inglês.


static func _is_portuguese() -> bool:
	return TranslationServer.get_locale().begins_with("pt")


static func integer(value: float) -> String:
	var number := absi(roundi(value))
	var digits := str(number)
	var groups: Array[String] = []
	while digits.length() > 3:
		groups.push_front(digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.push_front(digits)
	var text := ("." if _is_portuguese() else ",").join(groups)
	return ("-" + text) if roundi(value) < 0 else text


## Com casas decimais fixas (padrão 1).
static func decimal(value: float, places: int = 1) -> String:
	var text := String.num(absf(value), places)
	if places > 0 and not text.contains("."):
		text += "." + "0".repeat(places)
	var parts := text.split(".")
	var whole := integer(float(parts[0]))
	var result := whole + ("," if _is_portuguese() else ".") + parts[1] if parts.size() > 1 else whole
	return ("-" + result) if value < 0.0 and not is_zero_approx(value) else result


## Saldo com sinal: +120 ou -45.
static func signed(value: float) -> String:
	return ("+" if roundi(value) >= 0 else "") + integer(value)


static func percent(fraction: float) -> String:
	return "%d%%" % roundi(fraction * 100.0)


## Nome de um lugar dos navios: a ilha (a principal com marca) ou o posto do comerciante.
static func place(target: int) -> String:
	if target == Ship.TRADER_POST:
		return TranslationServer.translate("PLACE_TRADER")
	if target == 0:
		return TranslationServer.translate("PLACE_MAIN_ISLAND")
	if target < 0:
		return TranslationServer.translate("PLACE_OPEN_SEA")
	return TranslationServer.translate("PLACE_ISLAND") % (target + 1)


## Tempo de jogo restante como m:ss (ou h:mm:ss a partir de uma hora).
static func countdown(seconds: float) -> String:
	var total := maxi(ceili(seconds), 0)
	if total >= 3600:
		return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
	return "%d:%02d" % [total / 60, total % 60]
