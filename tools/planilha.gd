extends SceneTree
## Gera as planilhas de balanceamento (CSV) a partir dos dados do jogo (seção 5). Os .tres
## continuam sendo a fonte: a planilha é para ler, comparar e decidir os ajustes.
##   tools/godot.sh planilha            → exportado/balanceamento/{predios,bens,classes}.csv


func _init() -> void:
	var data := load("res://data/game_data.tres") as GameData
	var out := ProjectSettings.globalize_path("res://exportado/balanceamento")
	DirAccess.make_dir_recursive_absolute(out)
	_buildings(data, out.path_join("predios.csv"))
	_goods(data, out.path_join("bens.csv"))
	_tiers(data, out.path_join("classes.csv"))
	print(out)
	quit()


func _buildings(data: GameData, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_csv_line(["id", "tipo", "tamanho", "custo_moedas", "custo_materiais", "manutencao_min",
			"desbloqueio", "classe_trabalho", "trabalhadores", "entradas", "saida", "ciclo_s", "t_min",
			"modulos", "terreno", "fertilidade", "poluicao"])
	for def: BuildingDef in data.buildings:
		var materials: PackedStringArray = []
		for material: StringName in def.cost_materials:
			materials.append("%d %s" % [def.cost_materials[material], material])
		file.store_csv_line([def.id, BuildingDef.Kind.keys()[def.kind], "%dx%d" % [def.size.x, def.size.y],
				str(def.cost_money), " + ".join(materials), str(def.upkeep_per_min),
				"%d %s" % [def.unlock_residents, def.unlock_tier] if def.unlock_tier != &"" else "",
				def.workforce_tier, str(def.workers), " + ".join(def.inputs), def.output,
				str(def.cycle_s) if def.is_production() else "", "%.2f" % def.output_per_min() if def.is_production() else "",
				"%d %s" % [def.modules_required, def.module_id] if def.modules_required > 0 else "",
				BuildingDef.Terrain.keys()[def.terrain], def.fertility,
				"%d células x %.1f" % [def.pollution_radius_cells, def.pollution_strength] if def.pollution_radius_cells > 0 else ""])


func _goods(data: GameData, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_csv_line(["id", "preco_base", "consumo_t_min_por_morador", "moradores_por_produtor"])
	for good: GoodDef in data.goods:
		var producer := ""
		for def: BuildingDef in data.buildings:
			if def.is_production() and def.output == good.id and good.consumption_per_resident_t_min > 0.0:
				producer = "%.0f (%s)" % [def.output_per_min() / good.consumption_per_resident_t_min, def.id]
		file.store_csv_line([good.id, str(good.base_price), str(good.consumption_per_resident_t_min), producer])


func _tiers(data: GameData, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_csv_line(["id", "moradores_por_casa", "imposto_min_por_morador", "materiais_upgrade", "basicas", "luxo"])
	for tier: TierDef in data.tiers:
		var materials: PackedStringArray = []
		for material: StringName in tier.upgrade_materials:
			materials.append("%d %s" % [tier.upgrade_materials[material], material])
		file.store_csv_line([tier.id, str(tier.residents_per_house), str(tier.tax_per_resident_min), " + ".join(materials),
				" | ".join(tier.basic_needs.map(_need)), " | ".join(tier.luxury_needs.map(_need))])


func _need(need: NeedCategoryDef) -> String:
	return "%s: %s" % [need.id, ", ".join(need.goods + need.services)]
