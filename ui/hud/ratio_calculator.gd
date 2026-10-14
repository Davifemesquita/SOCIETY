class_name RatioCalculator
extends RefCounted
## Calculadora de proporção (seção 10: "1 moinho abastece 2 padarias"): quantos prédios
## consumidores um produtor abastece, pela razão dos ciclos (cada ciclo = 1 t), e quantos moradores
## um produtor de bem de consumo atende, pelo consumo por morador. Só conta; o texto sai traduzido.


## Prédios que usam a saída do produtor: [consumidor, quantos 1 produtor abastece].
static func consumers(def: BuildingDef, data: GameData) -> Array[Array]:
	var result: Array[Array] = []
	if not def.is_production():
		return result
	for other: BuildingDef in data.buildings:
		if other.is_production() and other.inputs.has(def.output):
			result.append([other, other.cycle_s / def.cycle_s])
	return result


## Moradores que um produtor atende sozinho (0 = o bem não é de consumo).
static func residents_served(def: BuildingDef, data: GameData) -> float:
	if not def.is_production():
		return 0.0
	var good := data.good(def.output)
	if good == null or good.consumption_per_resident_t_min <= 0.0:
		return 0.0
	return def.output_per_min() / good.consumption_per_resident_t_min


## Linhas da calculadora para o painel e a dica do prédio.
static func lines(def: BuildingDef, data: GameData) -> PackedStringArray:
	var text := PackedStringArray()
	for pair: Array in consumers(def, data):
		var consumer: BuildingDef = pair[0]
		var count: float = pair[1]
		text.append(TranslationServer.translate("RATIO_SUPPLIES") % [TranslationServer.translate(def.name_key),
				Fmt.decimal(count, 0 if is_equal_approx(count, roundf(count)) else 1), TranslationServer.translate(consumer.name_key)])
	var residents := residents_served(def, data)
	if residents > 0.0:
		text.append(TranslationServer.translate("RATIO_RESIDENTS") % [TranslationServer.translate(def.name_key), Fmt.integer(residents)])
	return text
