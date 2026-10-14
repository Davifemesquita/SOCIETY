class_name AmbiencePlayer
extends Node
## Ambiente por zona (seção 11): porto (gaivotas e ondas), fábrica (máquina a vapor), campo (ovelhas e
## pássaros) e cidade (gente na rua), cada um num laço no barramento Ambience, com o volume pelos
## prédios em volta do ponto que a câmera olha e pelo zoom (AudioMix). Vento e chuva não são arquivo:
## saem de ruído filtrado gerado aqui, o vento mais forte com a câmera alta e a chuva com o clima.

const LOOPS := {
	AudioMix.Zone.PORT: ["res://assets/audio/ambience/ambience_port_waves.ogg", "res://assets/audio/ambience/ambience_port_gulls.mp3"],
	AudioMix.Zone.FACTORY: ["res://assets/audio/ambience/ambience_factory_steam.ogg"],
	AudioMix.Zone.FIELD: ["res://assets/audio/ambience/ambience_field_sheep.ogg"],
	AudioMix.Zone.CITY: ["res://assets/audio/ambience/ambience_city_market.ogg"],
}
const REFRESH_SECONDS := 0.5
const SILENT_DB := -60.0
## Ruído gerado: taxa baixa basta para vento e chuva (e pesa pouco no GDScript).
const NOISE_RATE := 22050.0

## Volume alvo (0 a 1) de cada zona e o que está tocando agora (anda devagar até o alvo).
var targets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var levels := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var wind: float = 0.0
var rain: float = 0.0

var _config: GameConfig
var _simulation: Simulation
var _camera: StrategyCamera
var _weather: WeatherView
var _players: Array[Array] = []
var _noise := AudioStreamPlayer.new()
var _noise_playback: AudioStreamGeneratorPlayback
var _refresh_left: float = 0.0
var _rng := RandomNumberGenerator.new()
var _wind_state: float = 0.0
var _rain_state: float = 0.0
var _gust_phase: float = 0.0


func setup(config: GameConfig, simulation: Simulation, camera: StrategyCamera, weather: WeatherView) -> void:
	_config = config
	_simulation = simulation
	_camera = camera
	_weather = weather
	var audible := DisplayServer.get_name() != "headless"
	for zone: int in AudioMix.Zone.size():
		var list: Array[AudioStreamPlayer] = []
		var paths: Array = LOOPS[zone]
		for path: String in paths:
			var player := AudioStreamPlayer.new()
			player.bus = &"Ambience"
			player.stream = load(path) as AudioStream
			player.volume_db = SILENT_DB
			add_child(player)
			if audible:
				player.play()
			list.append(player)
		_players.append(list)
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = NOISE_RATE
	generator.buffer_length = 0.25
	_noise.stream = generator
	_noise.bus = &"Ambience"
	add_child(_noise)
	if audible:
		_noise.play()
		_noise_playback = _noise.get_stream_playback() as AudioStreamGeneratorPlayback
	_rng.seed = 1840


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh()
	var step := _config.ambience_fade_per_second * delta
	for zone: int in levels.size():
		levels[zone] = move_toward(levels[zone], targets[zone], step)
		for player: AudioStreamPlayer in _players[zone]:
			player.volume_db = linear_to_db(maxf(levels[zone], 0.001)) if levels[zone] > 0.001 else SILENT_DB
	_fill_noise()


## Conta os prédios por zona em volta do ponto da câmera e acha os volumes alvo.
func refresh() -> void:
	var focus := _camera.rig.focus if _camera != null else Vector3.ZERO
	var distance := _camera.rig.distance if _camera != null else 100.0
	var counts := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var radius_sq := _config.ambience_radius_m * _config.ambience_radius_m
	var world := _simulation.world
	for record: BuildingRecord in world.buildings.values():
		var def := _simulation.def_of(record)
		var zone := AudioMix.zone_of(def)
		if zone < 0:
			continue
		var center := world.island(record.island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation))
		if Vector2(center.x - focus.x, center.z - focus.z).length_squared() <= radius_sq:
			counts[zone] += 1.0
	targets = AudioMix.levels(_config, counts, distance)
	rain = _weather.sample.rain if _weather != null else 0.0
	wind = AudioMix.wind_level(_config, distance, rain)


## Vento: ruído grave (passa-baixa que oscila em rajadas). Chuva: ruído agudo e constante.
func _fill_noise() -> void:
	if _noise_playback == null:
		return
	var frames := _noise_playback.get_frames_available()
	if frames <= 0:
		return
	var buffer := PackedVector2Array()
	buffer.resize(frames)
	for i: int in frames:
		_gust_phase += 1.0 / NOISE_RATE
		var gust := 0.5 + 0.5 * sin(_gust_phase * 0.45) * sin(_gust_phase * 0.17 + 1.3)
		var white := _rng.randf_range(-1.0, 1.0)
		_wind_state += (white - _wind_state) * (0.01 + 0.03 * gust)
		_rain_state += (white - _rain_state) * 0.55
		var sample := _wind_state * 2.2 * wind * (0.4 + 0.6 * gust) + _rain_state * 0.22 * rain
		buffer[i] = Vector2(sample, sample)
	_noise_playback.push_buffer(buffer)
