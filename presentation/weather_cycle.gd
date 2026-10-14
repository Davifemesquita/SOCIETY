class_name WeatherCycle
extends RefCounted
## Clima (seção 9, Fase 9): só visual, sem efeito na economia e fora do save. Sai da semente da
## partida e da hora (GameClock.total_hours): cada dia sorteia céu limpo, nublado ou com chuva, a
## janela da chuva e se a manhã tem neblina. A mesma semente e a mesma hora dão sempre o mesmo céu.

enum Kind { CLEAR, CLOUDY, RAIN }


class Sample:
	var kind: Kind = Kind.CLEAR
	## Nuvens no céu, chuva caindo, neblina e chão molhado, cada um de 0 a 1.
	var coverage: float = 0.0
	var rain: float = 0.0
	var mist: float = 0.0
	var wetness: float = 0.0


## O dia sorteado: tipo, começo e fim da chuva (horas do dia) e a força da neblina da manhã.
class Day:
	var kind: Kind = Kind.CLEAR
	var rain_start: float = 0.0
	var rain_end: float = 0.0
	var mist: float = 0.0


static func day(seed_value: int, day_index: int, config: GameConfig) -> Day:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, day_index, "clima"])
	var result := Day.new()
	var roll := rng.randf()
	if roll < config.weather_rain_chance:
		result.kind = Kind.RAIN
	elif roll < config.weather_rain_chance + config.weather_cloudy_chance:
		result.kind = Kind.CLOUDY
	result.rain_start = rng.randf_range(config.weather_rain_start_hours.x, config.weather_rain_start_hours.y)
	result.rain_end = result.rain_start + rng.randf_range(config.weather_rain_duration_hours.x, config.weather_rain_duration_hours.y)
	result.mist = rng.randf_range(0.4, 1.0) if rng.randf() < config.weather_mist_chance else 0.0
	return result


static func sample(seed_value: int, total_hours: float, config: GameConfig) -> Sample:
	var index := floori(total_hours / 24.0)
	var hour := total_hours - index * 24.0
	var today := day(seed_value, index, config)
	var result := Sample.new()
	result.kind = today.kind
	result.rain = _rain_at(today, hour, config)
	# a cobertura troca devagar nas duas últimas horas do dia, rumo à do dia seguinte
	var base := _coverage_of(today.kind, config)
	var blend := smoothstep(22.0, 24.0, hour)
	if blend > 0.0:
		base = lerpf(base, _coverage_of(day(seed_value, index + 1, config).kind, config), blend)
	# a chuva fecha o céu antes de chegar ao máximo
	result.coverage = lerpf(base, config.weather_rain_coverage, smoothstep(0.0, 0.5, result.rain))
	result.mist = today.mist * _mist_curve(hour, config)
	result.wetness = maxf(_wet_after(today, hour, config), _wet_after(day(seed_value, index - 1, config), hour + 24.0, config))
	return result


static func _coverage_of(kind: Kind, config: GameConfig) -> float:
	match kind:
		Kind.CLOUDY:
			return config.weather_cloudy_coverage
		Kind.RAIN:
			return config.weather_cloudy_coverage
	return config.weather_clear_coverage


## Intensidade da chuva na hora do dia (sobe e desce em rain_fade_hours).
static func _rain_at(today: Day, hour: float, config: GameConfig) -> float:
	if today.kind != Kind.RAIN:
		return 0.0
	var fade := maxf(config.weather_rain_fade_hours, 0.001)
	return smoothstep(today.rain_start, today.rain_start + fade, hour) * (1.0 - smoothstep(today.rain_end - fade, today.rain_end, hour))


## Chão molhado: acompanha a chuva e seca em weather_dry_hours depois que ela para.
static func _wet_after(the_day: Day, hour: float, config: GameConfig) -> float:
	if the_day.kind != Kind.RAIN or hour < the_day.rain_start:
		return 0.0
	if hour <= the_day.rain_end:
		return _rain_at(the_day, hour, config)
	return 1.0 - smoothstep(the_day.rain_end, the_day.rain_end + config.weather_dry_hours, hour)


static func _mist_curve(hour: float, config: GameConfig) -> float:
	if hour <= config.weather_mist_peak_hour:
		return smoothstep(config.weather_mist_start_hour, config.weather_mist_peak_hour, hour)
	return 1.0 - smoothstep(config.weather_mist_peak_hour, config.weather_mist_end_hour, hour)
