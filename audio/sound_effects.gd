class_name SoundEffects
extends Node
## Efeitos (seção 11): construir, demolir, estrada, cliques, alertas, chegada de navio, marco, meta e
## comércio, no barramento Effects (cliques no Interface), cada um com um tempo mínimo entre uma vez
## e outra. E as fábricas trabalhando com som posicional: as mais perto do ponto da câmera ganham uma
## voz (no máximo work_voices), que bate o som do trabalho delas de tempos em tempos.

const SOUNDS := {
	&"build": ["res://assets/audio/sfx/build_1.ogg", "res://assets/audio/sfx/build_2.ogg"],
	&"demolish": ["res://assets/audio/sfx/demolish_1.ogg", "res://assets/audio/sfx/demolish_2.ogg"],
	&"road": ["res://assets/audio/sfx/road.ogg"],
	&"click": ["res://assets/audio/sfx/ui_click.ogg"],
	&"open": ["res://assets/audio/sfx/ui_open.ogg"],
	&"error": ["res://assets/audio/sfx/ui_error.ogg"],
	&"alert": ["res://assets/audio/sfx/alert.ogg"],
	&"ship": ["res://assets/audio/sfx/ship_arrived.ogg"],
	&"milestone": ["res://assets/audio/sfx/milestone.ogg"],
	&"goal": ["res://assets/audio/sfx/goal.ogg"],
	&"coins": ["res://assets/audio/sfx/coins.ogg"],
	&"wood": ["res://assets/audio/sfx/work_wood_1.ogg", "res://assets/audio/sfx/work_wood_2.ogg"],
	&"metal": ["res://assets/audio/sfx/work_metal_1.ogg", "res://assets/audio/sfx/work_metal_2.ogg"],
}
## Som de cada notificação (pelo ícone).
const NOTICE_SOUNDS := {
	"notice_shortage": &"alert", "notice_stopped": &"alert", "notice_storage_full": &"alert",
	"notice_ship_arrived": &"ship", "notice_milestone": &"milestone", "notice_colonized": &"goal",
	"notice_trader": &"coins",
}
const POOL_SIZE := 6
const REFRESH_SECONDS := 1.0

## Quantas vezes cada efeito tocou (os testes conferem sem precisar ouvir).
var played: Dictionary[StringName, int] = {}

var _config: GameConfig
var _simulation: Simulation
var _camera: StrategyCamera
var _streams: Dictionary[StringName, Array] = {}
var _pool: Array[AudioStreamPlayer] = []
var _ui: AudioStreamPlayer
var _last_played: Dictionary[StringName, int] = {}
var _voices: Array[AudioStreamPlayer3D] = []
## Prédio de cada voz (0 = livre) e quanto falta para ela bater de novo.
var _voice_buildings: PackedInt32Array = PackedInt32Array()
var _voice_timers: PackedFloat32Array = PackedFloat32Array()
var _refresh_left: float = 0.0
var _rng := RandomNumberGenerator.new()
var _audible: bool = true


func setup(config: GameConfig, simulation: Simulation, camera: StrategyCamera) -> void:
	_config = config
	_simulation = simulation
	_camera = camera
	_audible = DisplayServer.get_name() != "headless"
	for key: StringName in SOUNDS:
		var list: Array[AudioStream] = []
		var paths: Array = SOUNDS[key]
		for path: String in paths:
			list.append(load(path) as AudioStream)
		_streams[key] = list
	for i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Effects"
		add_child(player)
		_pool.append(player)
	_ui = AudioStreamPlayer.new()
	_ui.bus = &"Interface"
	add_child(_ui)
	for i: int in config.work_voices:
		var voice := AudioStreamPlayer3D.new()
		voice.bus = &"Effects"
		voice.unit_size = 12.0
		voice.max_distance = config.work_sound_radius_m * 1.5
		add_child(voice)
		_voices.append(voice)
	_voice_buildings.resize(config.work_voices)
	_voice_timers.resize(config.work_voices)
	EventBus.building_placed.connect(func(_id: int) -> void: play(&"build"))
	EventBus.building_removed.connect(func(_id: int) -> void: play(&"demolish"))
	EventBus.roads_changed.connect(func(_island: int) -> void: play(&"road"))
	EventBus.goal_completed.connect(func(_index: int) -> void: play(&"goal"))
	EventBus.notice_shown.connect(_on_notice)
	EventBus.world_replaced.connect(_clear_voices)
	# todo botão que entra na árvore ganha o clique (a interface não precisa saber do áudio)
	get_tree().node_added.connect(_on_node_added)
	_rng.seed = 1840


## Toca o efeito (uma das variantes), se ele não tocou há menos de sfx_cooldown_s.
func play(key: StringName) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_played.get(key, -100000) < _config.sfx_cooldown_s * 1000.0:
		return
	_last_played[key] = now
	played[key] = played.get(key, 0) + 1
	if not _audible:
		return
	var variants: Array = _streams[key]
	var stream: AudioStream = variants[_rng.randi() % variants.size()]
	var target := _ui if key == &"click" or key == &"open" else _free_player()
	target.stream = stream
	target.pitch_scale = _rng.randf_range(0.95, 1.05)
	target.play()


## Vozes de fábrica em uso agora.
func voice_count() -> int:
	return _voice_buildings.size() - _voice_buildings.count(0)


func _free_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _pool:
		if not player.playing:
			return player
	return _pool[0]


func _on_notice(icon: String) -> void:
	var key: StringName = NOTICE_SOUNDS.get(icon, &"")
	if key != &"":
		play(key)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button != null and not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play(&"click")


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		refresh_voices()
	for i: int in _voices.size():
		if _voice_buildings[i] == 0:
			continue
		_voice_timers[i] -= delta
		if _voice_timers[i] <= 0.0:
			_voice_timers[i] = _rng.randf_range(_config.work_sound_interval_s.x, _config.work_sound_interval_s.y)
			var record := _simulation.world.building(_voice_buildings[i])
			if record == null:
				_voice_buildings[i] = 0
				continue
			var variants: Array = _streams[_simulation.def_of(record).work_sound]
			_voices[i].stream = variants[_rng.randi() % variants.size()]
			if _audible:
				_voices[i].play()


## Dá voz às fábricas produzindo mais perto do ponto da câmera (as outras ficam caladas).
func refresh_voices() -> void:
	var focus := _camera.rig.focus if _camera != null else Vector3.ZERO
	var radius_sq := _config.work_sound_radius_m * _config.work_sound_radius_m
	var world := _simulation.world
	var near: Array[Vector2] = []
	for record: BuildingRecord in world.buildings.values():
		var def := _simulation.def_of(record)
		if def.work_sound == &"" or record.state != BuildingRecord.State.PRODUCING:
			continue
		var center := world.island(record.island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation))
		var gap := Vector2(center.x - focus.x, center.z - focus.z).length_squared()
		if gap <= radius_sq:
			near.append(Vector2(gap, record.id))
	near.sort()
	for i: int in _voices.size():
		var building_id := int(near[i].y) if i < near.size() else 0
		if building_id != _voice_buildings[i]:
			_voice_buildings[i] = building_id
			_voice_timers[i] = _rng.randf_range(0.0, _config.work_sound_interval_s.y)
			if building_id != 0:
				var record := world.building(building_id)
				var def := _simulation.def_of(record)
				_voices[i].global_position = world.island(record.island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation)) \
						+ Vector3(0.0, def.height_m * 0.5, 0.0)


func _clear_voices() -> void:
	for i: int in _voice_buildings.size():
		_voice_buildings[i] = 0
