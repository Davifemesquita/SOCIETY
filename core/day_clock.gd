class_name DayClock
extends RefCounted
## O que sai da hora do dia (seção 9), tudo só visual: a economia conta segundos de jogo e não
## depende de nada daqui. A hora vem do GameClock (TickClock.hour); estas funções dizem quanto
## de noite está (para janelas e luzes) e quanta gente anda na rua.


## 0 de dia, 1 de noite, com transição suave em volta do nascer e do pôr do sol.
static func night_factor(config: GameConfig, hour: float) -> float:
	var h := fposmod(hour, 24.0)
	var twilight := maxf(config.twilight_hours, 0.001)
	var dusk := smoothstep(config.sunset_hour - twilight, config.sunset_hour + twilight, h)
	var dawn := 1.0 - smoothstep(config.sunrise_hour - twilight, config.sunrise_hour + twilight, h)
	return maxf(dusk, dawn)


## Fração dos pedestres na rua nesta hora, interpolada entre os valores de hora em hora.
static func activity(config: GameConfig, hour: float) -> float:
	var curve := config.pedestrian_activity_by_hour
	if curve.is_empty():
		return 1.0
	var h := fposmod(hour, 24.0) * curve.size() / 24.0
	var index := floori(h)
	return clampf(lerpf(curve[index % curve.size()], curve[(index + 1) % curve.size()], h - index), 0.0, 1.0)


## Texto "HH:MM" da hora.
static func clock_text(hour: float) -> String:
	var minutes := floori(fposmod(hour, 24.0) * 60.0)
	return "%02d:%02d" % [minutes / 60, minutes % 60]
