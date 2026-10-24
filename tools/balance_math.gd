class_name BalanceMath
extends RefCounted
## Contas de balanceamento a partir dos dados (Fase 27), para a planilha e o relatório: quanto custa, em
## manutenção por minuto, a cadeia inteira que abastece um morador, contra o imposto que ele paga. Conta como o
## jogo: cada prédio faz output_per_min() e gasta 1 t de cada entrada por tonelada feita; numa categoria com
## vários bens o consumo se divide entre eles (seção 4). Serviços, armazéns e quem trabalha não entram.


## Manutenção por tonelada do bem, somando a cadeia de cima a baixo (0 para bem sem produtor, como o importado).
static func upkeep_per_ton(data: GameData, good: StringName) -> float:
	for def: BuildingDef in data.buildings:
		if def.is_production() and def.output == good and def.output_per_min() > 0.0:
			var cost := def.upkeep_per_min / def.output_per_min()
			for input: StringName in def.inputs:
				cost += upkeep_per_ton(data, input)
			return cost
	return 0.0


## Manutenção da cadeia por morador e minuto para atender as categorias, com o consumo dividido entre os bens
## de cada uma.
static func needs_upkeep_per_resident(data: GameData, needs: Array[NeedCategoryDef]) -> float:
	var total := 0.0
	for need: NeedCategoryDef in needs:
		if need.goods.is_empty():
			continue
		for good_id: StringName in need.goods:
			var good := data.good(good_id)
			total += good.consumption_per_resident_t_min / need.goods.size() * upkeep_per_ton(data, good_id)
	return total
