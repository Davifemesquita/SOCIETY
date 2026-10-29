class_name FestivalSounds
extends Node
## Som da festa (Fase 85): o estouro de cada fogo e as palmas do povo na praça, gerados aqui (sem arquivo, como o
## vento e a chuva do AmbiencePlayer). O estouro toca no ponto do céu e chega atrasado pela distância até a câmera
## (SOUND_SPEED_M_S); as palmas tocam na praça, um pouco depois (o povo reage), mais altas com mais gente batendo.
## Sem tela (headless) nada toca: os testes conferem `played` e `pending_count`.

const RATE := 22050
const SOUND_SPEED_M_S := 343.0
## Vozes ao mesmo tempo de cada som.
const BANG_VOICES := 4
const CLAP_VOICES := 3
## As palmas começam junto da reação do povo (Crowd.REACT_DELAY_S, no meio).
const CLAP_DELAY_S := 0.35
## Volume das palmas: CLAP_QUIET_DB com uma pessoa, CLAP_FULL_DB a partir de CLAP_FULL_PEOPLE.
const CLAP_QUIET_DB := -14.0
const CLAP_FULL_DB := 0.0
const CLAP_FULL_PEOPLE := 12
const BANG_DB := 2.0
## Duração dos sons gerados (s).
const BANG_S := 1.8
const CLAP_S := 2.2

## Quantas vezes cada som tocou (&"bang", &"applause").
var played: Dictionary[StringName, int] = {}

## Os sons gerados ficam entre partidas (gerar leva algumas dezenas de ms).
static var _bang_cache: AudioStreamWAV
static var _applause_cache: AudioStreamWAV

var _camera: StrategyCamera
var _bang: AudioStreamWAV
var _applause: AudioStreamWAV
var _bangs: Array[AudioStreamPlayer3D] = []
var _claps: Array[AudioStreamPlayer3D] = []
## Sons esperando a hora: [tempo que falta, chave, posição, volume em dB].
var _pending: Array[Array] = []
var _audible: bool = true
var _rng := RandomNumberGenerator.new()


func setup(camera: StrategyCamera, festival: FestivalView, crowd: Crowd) -> void:
	_camera = camera
	_audible = DisplayServer.get_name() != "headless"
	_rng.seed = 1840
	if _bang_cache == null:
		_bang_cache = bang_stream()
		_applause_cache = applause_stream()
	_bang = _bang_cache
	_applause = _applause_cache
	for i: int in BANG_VOICES:
		_bangs.append(_voice(_bang, 40.0, 900.0))
	for i: int in CLAP_VOICES:
		_claps.append(_voice(_applause, 10.0, 220.0))
	festival.exploded.connect(func(island_id: int, at: Vector3) -> void:
		on_burst(at, crowd.react_to_burst(island_id, at) if crowd != null else 0))


## Um estouro em at, com people batendo palmas por ele: o estrondo chega pela distância e as palmas logo depois.
func on_burst(at: Vector3, people: int) -> void:
	var delay := listener_distance(at) / SOUND_SPEED_M_S
	_pending.append([delay, &"bang", at, BANG_DB])
	if people > 0:
		var ground := Vector3(at.x, at.y - FestivalView.FIREWORK_HEIGHT_M.x, at.z)
		_pending.append([maxf(delay, CLAP_DELAY_S), &"applause", ground, clap_db(people)])


## Volume das palmas de people pessoas.
static func clap_db(people: int) -> float:
	var share := clampf(float(people - 1) / float(CLAP_FULL_PEOPLE - 1), 0.0, 1.0)
	return lerpf(CLAP_QUIET_DB, CLAP_FULL_DB, sqrt(share))


func listener_distance(at: Vector3) -> float:
	if _camera == null or _camera.camera == null or not _camera.camera.is_inside_tree():
		return 0.0
	return _camera.camera.global_position.distance_to(at)


func pending_count() -> int:
	return _pending.size()


func _process(delta: float) -> void:
	if _pending.is_empty():
		return
	var speed := GameClock.clock.speed_multiplier()
	if speed <= 0.0:
		return
	var left: Array[Array] = []
	for item: Array in _pending:
		var wait: float = item[0]
		wait -= delta
		if wait > 0.0:
			item[0] = wait
			left.append(item)
			continue
		var key: StringName = item[1]
		var at: Vector3 = item[2]
		var volume_db: float = item[3]
		_play(key, at, volume_db)
	_pending = left


func _play(key: StringName, at: Vector3, volume_db: float) -> void:
	played[key] = played.get(key, 0) + 1
	if not _audible:
		return
	var pool := _bangs if key == &"bang" else _claps
	if pool.is_empty():
		return
	var player := pool[0]
	for candidate: AudioStreamPlayer3D in pool:
		if not candidate.playing:
			player = candidate
			break
	player.global_position = at
	player.volume_db = volume_db
	player.pitch_scale = _rng.randf_range(0.9, 1.1)
	player.play()


func _voice(stream: AudioStream, unit_size: float, max_distance: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = &"Effects"
	player.unit_size = unit_size
	player.max_distance = max_distance
	add_child(player)
	return player


## O estouro: um baque grave que desce de tom, o estalo do ruído e o crepitar das faíscas caindo, cada vez mais raro.
static func bang_stream() -> AudioStreamWAV:
	var count := roundi(BANG_S * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 85
	var phase := 0.0
	var low := 0.0
	for i: int in count:
		var t := float(i) / RATE
		phase += TAU * lerpf(90.0, 38.0, minf(t / 0.4, 1.0)) / RATE
		var thump := sin(phase) * exp(-t / 0.22)
		low += (rng.randf_range(-1.0, 1.0) - low) * 0.18
		var crack := low * exp(-t / 0.07) * 1.4
		samples[i] = thump + crack
	# o crepitar: estalos curtos espalhados depois do estouro
	var crackles := 160
	for k: int in crackles:
		var start := rng.randf_range(0.15, BANG_S - 0.05)
		if rng.randf() > exp(-(start - 0.15) / 0.6):
			continue
		var at := roundi(start * RATE)
		var strength := rng.randf_range(0.15, 0.45) * exp(-(start - 0.15) / 0.8)
		for j: int in 90:
			if at + j >= count:
				break
			samples[at + j] += rng.randf_range(-1.0, 1.0) * strength * exp(-float(j) / 18.0)
	return _wav(samples)


## As palmas de um grupo: muitas batidas curtas (ruído em faixa), mais densas logo depois do estouro e rareando.
static func applause_stream() -> AudioStreamWAV:
	var count := roundi(CLAP_S * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1840
	var claps := 120
	for k: int in claps:
		var start := rng.randf_range(0.0, CLAP_S - 0.05)
		# mais palmas no começo
		if rng.randf() > exp(-start / 0.9):
			continue
		var at := roundi(start * RATE)
		var strength := rng.randf_range(0.4, 1.0) * minf(1.0, (CLAP_S - start) / 0.4)
		var low := 0.0
		var lower := 0.0
		for j: int in 260:
			if at + j >= count:
				break
			var noise := rng.randf_range(-1.0, 1.0)
			low += (noise - low) * 0.55
			lower += (noise - lower) * 0.08
			# faixa: o agudo do ruído sem o grave, um estalo de mãos
			samples[at + j] += (low - lower) * strength * exp(-float(j) / 55.0)
	return _wav(samples)


## PCM de 16 bits, mono, normalizado a 0,8.
static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.0001
	for value: float in samples:
		peak = maxf(peak, absf(value))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, clampi(roundi(samples[i] / peak * 0.8 * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
