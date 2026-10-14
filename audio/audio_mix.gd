class_name AudioMix
extends RefCounted
## As contas do áudio (seção 11), sem nós, para testar: o clima da música e o volume de cada zona de
## ambiente. O MusicDirector e o AmbiencePlayer só aplicam o que sai daqui.

enum Mood { CALM, PROGRESS, ALERT }
## Zonas de ambiente, na ordem de GameConfig.ambience_full_counts.
enum Zone { PORT, FACTORY, FIELD, CITY }


## Alerta pesa mais que progresso; sem nada recente, calma.
static func mood(config: GameConfig, money: float, seconds_since_shortage: float, seconds_since_progress: float) -> Mood:
	if money < 0.0 or seconds_since_shortage < config.music_alert_after_shortage_s:
		return Mood.ALERT
	if seconds_since_progress < config.music_progress_after_event_s:
		return Mood.PROGRESS
	return Mood.CALM


## Zona de um prédio para o ambiente, ou -1.
static func zone_of(def: BuildingDef) -> int:
	if def.is_berth() or def.id == &"fishery":
		return Zone.PORT
	if def.kind == BuildingDef.Kind.RESIDENCE or def.kind == BuildingDef.Kind.SERVICE:
		return Zone.CITY
	if def.kind == BuildingDef.Kind.MODULE or def.modules_required > 0:
		return Zone.FIELD
	if def.is_production():
		return Zone.FACTORY
	return -1


## Volume (0 a 1) de cada zona pelos prédios contados e pela distância da câmera.
static func levels(config: GameConfig, counts: PackedFloat32Array, camera_distance_m: float) -> PackedFloat32Array:
	var near := zoom_factor(config, camera_distance_m)
	var result := PackedFloat32Array()
	result.resize(Zone.size())
	for zone: int in Zone.size():
		var full := maxf(config.ambience_full_counts[zone], 0.001)
		result[zone] = clampf(counts[zone] / full, 0.0, 1.0) * near
	return result


## 1 de perto, 0 de longe.
static func zoom_factor(config: GameConfig, camera_distance_m: float) -> float:
	return 1.0 - smoothstep(config.ambience_near_m, config.ambience_far_m, camera_distance_m)


## O vento cresce com a altura da câmera (lá em cima só se ouve vento) e com a chuva.
static func wind_level(config: GameConfig, camera_distance_m: float, rain: float) -> float:
	return clampf(0.15 + 0.6 * (1.0 - zoom_factor(config, camera_distance_m)) + 0.3 * rain, 0.0, 1.0)
