class_name StatusIconRule
extends RefCounted
## Quais ícones de estado aparecem sobre os prédios e com que opacidade (Fase 33). Função pura: a BuildingView
## passa a posição e o motivo de cada ícone e a câmera.
## - Até status_icon_full_m da câmera: cada um, inteiro.
## - Mais longe: os de mesmo motivo no mesmo quadrado de status_icon_cluster_m viram um só (o de menor id), que
##   esmaece até status_icon_min_alpha em status_icon_fade_end_m. Cada motivo segue com um ícone em cada pedaço.
## - Os de "always" (o prédio sob o cursor e o selecionado) e todos, com show_all, aparecem inteiros.


## Opacidade por prédio (só os que aparecem). points e keys: posição e motivo do ícone de cada prédio.
static func alphas(points: Dictionary[int, Vector3], keys: Dictionary[int, String], camera: Vector3,
		config: GameConfig, always: Array[int] = [], show_all: bool = false) -> Dictionary[int, float]:
	var result: Dictionary[int, float] = {}
	var cluster_leader: Dictionary[String, int] = {}
	var ids := points.keys()
	ids.sort()
	for building_id: int in ids:
		var point := points[building_id]
		var distance := camera.distance_to(point)
		if show_all or building_id in always or distance <= config.status_icon_full_m:
			result[building_id] = 1.0
			continue
		var cluster := "%d,%d|%s" % [floori(point.x / config.status_icon_cluster_m),
				floori(point.z / config.status_icon_cluster_m), keys.get(building_id, "")]
		if cluster_leader.has(cluster):
			continue
		cluster_leader[cluster] = building_id
		result[building_id] = fade(distance, config)
	return result


## Opacidade do ícone agregado à distância dada: 1 em status_icon_full_m, min_alpha em fade_end_m e além.
static func fade(distance: float, config: GameConfig) -> float:
	var t := clampf((distance - config.status_icon_full_m) / (config.status_icon_fade_end_m - config.status_icon_full_m),
			0.0, 1.0)
	return lerpf(1.0, config.status_icon_min_alpha, t)
