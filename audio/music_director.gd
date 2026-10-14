class_name MusicDirector
extends Node
## Música adaptativa (seção 11): três climas (calma, progresso, alerta), cada um uma lista de faixas
## em domínio público tocando em sequência (AudioStreamPlaylist), trocados com fade por um
## AudioStreamInteractive no barramento Music. O clima sai do AudioMix pelo que aconteceu na partida.

const TRACKS := {
	AudioMix.Mood.CALM: ["res://assets/audio/music/music_calm_satie.ogg", "res://assets/audio/music/music_calm_chopin.ogg"],
	AudioMix.Mood.PROGRESS: ["res://assets/audio/music/music_progress_kaiserwalzer.ogg", "res://assets/audio/music/music_progress_kuenstlerleben.ogg"],
	AudioMix.Mood.ALERT: ["res://assets/audio/music/music_alert_chopin.ogg"],
}
const CLIP_NAMES: Array[StringName] = [&"calm", &"progress", &"alert"]

var mood: AudioMix.Mood = AudioMix.Mood.CALM

var _config: GameConfig
var _simulation: Simulation
var _player := AudioStreamPlayer.new()
var _check_left: float = 0.0
## Segundos reais desde a última falta e desde o último marco ou meta (alto = há muito tempo).
var _since_shortage: float = INF
var _since_progress: float = INF


func setup(config: GameConfig, simulation: Simulation) -> void:
	_config = config
	_simulation = simulation
	_player.name = "Music"
	_player.bus = &"Music"
	_player.stream = build_stream(config.music_fade_seconds)
	add_child(_player)
	EventBus.good_shortage.connect(func(_island: int, _good: StringName) -> void: _since_shortage = 0.0)
	EventBus.milestone_reached.connect(func(_count: int) -> void: _since_progress = 0.0)
	EventBus.goal_completed.connect(func(_index: int) -> void: _since_progress = 0.0)
	EventBus.world_replaced.connect(func() -> void:
		_since_shortage = INF
		_since_progress = INF)
	if DisplayServer.get_name() != "headless":
		_player.play()


## Os três climas num AudioStreamInteractive: qualquer um passa para qualquer outro no fim do compasso
## (bpm 60: um tempo por segundo) com fade cruzado.
static func build_stream(fade_seconds: float) -> AudioStreamInteractive:
	var interactive := AudioStreamInteractive.new()
	interactive.clip_count = CLIP_NAMES.size()
	for index: int in CLIP_NAMES.size():
		var playlist := AudioStreamPlaylist.new()
		var paths: Array = TRACKS[index]
		playlist.stream_count = paths.size()
		playlist.loop = true
		playlist.fade_time = fade_seconds
		for track: int in paths.size():
			var path: String = paths[track]
			playlist.set_list_stream(track, load(path) as AudioStream)
		interactive.set_clip_name(index, CLIP_NAMES[index])
		interactive.set_clip_stream(index, playlist)
	interactive.initial_clip = 0
	interactive.add_transition(AudioStreamInteractive.CLIP_ANY, AudioStreamInteractive.CLIP_ANY,
			AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BEAT, AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS, fade_seconds)
	return interactive


func _process(delta: float) -> void:
	_since_shortage += delta
	_since_progress += delta
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = _config.music_check_seconds
	var wanted := AudioMix.mood(_config, _simulation.world.money, _since_shortage, _since_progress)
	if wanted != mood:
		mood = wanted
		var playback := _player.get_stream_playback() as AudioStreamPlaybackInteractive
		if playback != null:
			playback.switch_to_clip_by_name(CLIP_NAMES[mood])
