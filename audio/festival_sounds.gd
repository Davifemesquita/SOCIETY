class_name FestivalSounds
extends Node
## Som da festa (Fase 85): o estouro de cada fogo e as palmas do povo na praça, gerados aqui (sem arquivo, como o
## vento e a chuva do AmbiencePlayer). O estouro toca no ponto do céu e chega atrasado pela distância até a câmera
## (SOUND_SPEED_M_S); as palmas tocam na praça, um pouco depois (o povo reage), mais altas com mais gente batendo.
## Desde a Fase 86, o assobio do foguete subindo (segue o foguete e acaba no estouro) e o eco do estrondo (ECHO_*).
## Desde a Fase 87, as vivas do povo: a gravação de uma multidão (CHEER_PATH, Gregor Quendel, CC BY 4.0) em laço na
## praça, que sobe a cada estouro com gente reagindo (a partir de CHEER_MIN_PEOPLE) e some devagar (cheer_level); desde
## a Fase 88 com a faixa calma (CHEER_SOFT_PATH) para pouca gente, misturada pelo nível (cheer_mix).
## Sem tela (headless) nada toca: os testes conferem `played`, `pending_count`, `flights_count` e `cheer_level`.

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
## Fase 86: o assobio (WHISTLE_S, tocado mais depressa para acabar no estouro) e o eco: o estrondo de novo, mais fraco e
## mais grave, ECHO_DELAY_S depois.
const WHISTLE_VOICES := 3
const WHISTLE_S := 1.4
const WHISTLE_DB := -8.0
const ECHO_DELAY_S := 0.45
const ECHO_DB := -12.0
const ECHO_PITCH := 0.85
## Fase 87: as vivas: a partir de CHEER_MIN_PEOPLE reagindo, o nível vai a cheer_share (cheio com CLAP_FULL_PEOPLE) e cai
## CHEER_FADE_PER_S por segundo; no nível 1 toca a CHEER_DB.
const CHEER_PATH := "res://assets/audio/sfx/crowd_cheer.mp3"
const CHEER_MIN_PEOPLE := 3
const CHEER_DB := -3.0
const CHEER_FADE_PER_S := 0.35
const CHEER_SILENT := 0.02
## Fase 88: a faixa calma do mesmo pacote ("Soft cheering - II") para pouca gente: até CHEER_MIX_FROM do nível só ela,
## a partir de CHEER_MIX_TO só a forte, e entre as duas, a mistura (cheer_mix).
const CHEER_SOFT_PATH := "res://assets/audio/sfx/crowd_cheer_soft.mp3"
const CHEER_MIX_FROM := 0.35
const CHEER_MIX_TO := 0.8

## Quantas vezes cada som tocou (&"bang", &"echo", &"applause", &"whistle", &"cheer").
var played: Dictionary[StringName, int] = {}
## Fase 87: o volume das vivas agora (0 a 1).
var cheer_level: float = 0.0

## Os sons gerados ficam entre partidas (gerar leva algumas dezenas de ms).
static var _bang_cache: AudioStreamWAV
static var _applause_cache: AudioStreamWAV
static var _whistle_cache: AudioStreamWAV

var _camera: StrategyCamera
var _bang: AudioStreamWAV
var _applause: AudioStreamWAV
var _bangs: Array[AudioStreamPlayer3D] = []
var _claps: Array[AudioStreamPlayer3D] = []
var _whistles: Array[AudioStreamPlayer3D] = []
## Assobios no ar: [voz, de, até, segundos da subida, segundos andados] (tempo de jogo).
var _flights: Array[Array] = []
## As vivas: [calma, forte] (Fase 88; null quando a gravação falta).
var _cheers: Array[AudioStreamPlayer3D] = []
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
		_whistle_cache = whistle_stream()
	_bang = _bang_cache
	_applause = _applause_cache
	for i: int in BANG_VOICES:
		_bangs.append(_voice(_bang, 40.0, 900.0))
	for i: int in CLAP_VOICES:
		_claps.append(_voice(_applause, 10.0, 220.0))
	for i: int in WHISTLE_VOICES:
		_whistles.append(_voice(_whistle_cache, 20.0, 500.0))
	for path: String in [CHEER_SOFT_PATH, CHEER_PATH]:
		var recording := load(path) as AudioStreamMP3
		var player: AudioStreamPlayer3D = null
		if recording != null:
			var looped := recording.duplicate() as AudioStreamMP3
			looped.loop = true
			player = _voice(looped, 14.0, 260.0)
		_cheers.append(player)
	festival.launched.connect(func(_island_id: int, from: Vector3, to: Vector3, rise_s: float) -> void:
		on_launch(from, to, rise_s))
	festival.exploded.connect(func(island_id: int, at: Vector3) -> void:
		on_burst(at, crowd.react_to_burst(island_id, at) if crowd != null else 0))


## Um estouro em at, com people batendo palmas por ele: o estrondo chega pela distância e as palmas logo depois.
func on_burst(at: Vector3, people: int) -> void:
	var delay := listener_distance(at) / SOUND_SPEED_M_S
	_pending.append([delay, &"bang", at, BANG_DB])
	_pending.append([delay + ECHO_DELAY_S, &"echo", at, ECHO_DB])
	if people > 0:
		var ground := Vector3(at.x, at.y - FestivalView.FIREWORK_HEIGHT_M.x, at.z)
		_pending.append([maxf(delay, CLAP_DELAY_S), &"applause", ground, clap_db(people)])
		if people >= CHEER_MIN_PEOPLE:
			_pending.append([maxf(delay, CLAP_DELAY_S), &"cheer", ground, cheer_share(people)])


## Fase 87: o nível das vivas de people pessoas reagindo (0 abaixo de CHEER_MIN_PEOPLE, 1 com CLAP_FULL_PEOPLE).
static func cheer_share(people: int) -> float:
	if people < CHEER_MIN_PEOPLE:
		return 0.0
	var share := float(people - CHEER_MIN_PEOPLE + 1) / float(CLAP_FULL_PEOPLE - CHEER_MIN_PEOPLE + 1)
	return sqrt(clampf(share, 0.0, 1.0))


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


func flights_count() -> int:
	return _flights.size()


## Fase 86: um foguete subindo de from até to em rise_s segundos de jogo: o assobio sai dele e acaba no estouro.
func on_launch(from: Vector3, to: Vector3, rise_s: float) -> void:
	played[&"whistle"] = played.get(&"whistle", 0) + 1
	var player: AudioStreamPlayer3D = null
	if _audible and not _whistles.is_empty():
		player = _whistles[0]
		for candidate: AudioStreamPlayer3D in _whistles:
			if not candidate.playing:
				player = candidate
				break
		player.global_position = from
		player.volume_db = WHISTLE_DB
		# mais depressa (e mais agudo) para acabar junto do estouro
		player.pitch_scale = clampf(WHISTLE_S / maxf(rise_s, 0.1), 0.6, 2.0) * maxf(GameClock.clock.speed_multiplier(), 1.0)
		player.play()
	_flights.append([player, from, to, rise_s, 0.0])


func _process(delta: float) -> void:
	var speed := GameClock.clock.speed_multiplier()
	_follow_flights(delta * speed, speed <= 0.0)
	fade_cheer(delta * speed, speed <= 0.0)
	if _pending.is_empty():
		return
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
	if key == &"cheer":
		# nas vivas, o último campo é o nível (0 a 1), não dB
		_swell_cheer(at, volume_db)
		return
	if not _audible:
		return
	var pool := _claps if key == &"applause" else _bangs
	if pool.is_empty():
		return
	var player := pool[0]
	for candidate: AudioStreamPlayer3D in pool:
		if not candidate.playing:
			player = candidate
			break
	player.global_position = at
	player.volume_db = volume_db
	player.pitch_scale = _rng.randf_range(0.9, 1.1) * (ECHO_PITCH if key == &"echo" else 1.0)
	player.play()


## Fase 87: as vivas sobem até level, vindas da praça em at; se estavam caladas, começam num ponto qualquer da gravação.
func _swell_cheer(at: Vector3, level: float) -> void:
	cheer_level = maxf(cheer_level, level)
	if not _audible:
		return
	for player: AudioStreamPlayer3D in _cheers:
		if player == null:
			continue
		player.global_position = at
		if not player.playing:
			player.play(_rng.randf_range(0.0, maxf(player.stream.get_length() - 4.0, 0.0)))
	_mix_cheers()


## Fase 88: quanto da faixa forte vai no nível (0 só a calma, 1 só a forte).
static func cheer_mix(level: float) -> float:
	return smoothstep(CHEER_MIX_FROM, CHEER_MIX_TO, level)


## Fase 87: as vivas somem devagar (CHEER_FADE_PER_S de jogo); caladas, as vozes param; com o jogo parado, param também.
## Desde a Fase 88, ao baixar, a faixa forte dá lugar à calma.
func fade_cheer(game_delta: float, paused: bool) -> void:
	if cheer_level <= 0.0:
		return
	cheer_level = maxf(cheer_level - CHEER_FADE_PER_S * game_delta, 0.0)
	if cheer_level < CHEER_SILENT:
		cheer_level = 0.0
	if not _audible:
		return
	for player: AudioStreamPlayer3D in _cheers:
		if player != null:
			player.stream_paused = paused
			if cheer_level == 0.0:
				player.stop()
	if cheer_level > 0.0:
		_mix_cheers()


## O volume de cada faixa pelo nível e pela mistura (as duas somam o nível, em potência igual).
func _mix_cheers() -> void:
	var mix := cheer_mix(cheer_level)
	var shares := [sqrt(1.0 - mix), sqrt(mix)]
	for index: int in _cheers.size():
		var player := _cheers[index]
		if player != null:
			var share: float = shares[index]
			player.volume_db = CHEER_DB + linear_to_db(maxf(cheer_level * share, 0.0001))


## Fase 86: leva cada assobio junto do foguete (a mesma subida da FestivalView.rocket_point, sem o balanço) e o cala no
## estouro; com o jogo parado, o assobio para também.
func _follow_flights(game_delta: float, paused: bool) -> void:
	var left: Array[Array] = []
	for flight: Array in _flights:
		var player: AudioStreamPlayer3D = flight[0]
		if player != null:
			player.stream_paused = paused
		var from: Vector3 = flight[1]
		var to: Vector3 = flight[2]
		var rise_s: float = flight[3]
		var elapsed: float = flight[4]
		elapsed += game_delta
		if elapsed >= rise_s:
			if player != null:
				player.stop()
			continue
		flight[4] = elapsed
		var t := elapsed / rise_s
		if player != null:
			player.global_position = from.lerp(to, 1.0 - (1.0 - t) * (1.0 - t))
		left.append(flight)
	_flights = left


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


## Fase 86: o assobio do foguete: um tom que sobe (de 900 a 2.600 Hz, mais depressa no começo) com um tremor, o chiado
## da pólvora por baixo, entrando depressa e sumindo no fim.
static func whistle_stream() -> AudioStreamWAV:
	var count := roundi(WHISTLE_S * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 86
	var phase := 0.0
	var hiss := 0.0
	for i: int in count:
		var t := float(i) / count
		var pitch := lerpf(900.0, 2600.0, 1.0 - (1.0 - t) * (1.0 - t)) * (1.0 + 0.012 * sin(TAU * 7.0 * t * WHISTLE_S))
		phase += TAU * pitch / RATE
		hiss += (rng.randf_range(-1.0, 1.0) - hiss) * 0.6
		var envelope := minf(t / 0.06, 1.0) * minf((1.0 - t) / 0.12, 1.0)
		samples[i] = (sin(phase) * 0.7 + hiss * 0.35) * envelope
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
