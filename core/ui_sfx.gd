extends Node
## Autoload UiSfx (Fase 43): os sons da interface em qualquer tela (o menu também, não só a partida). Todo botão que
## entra na árvore ganha o clique ao apertar e um toque leve ao passar o mouse (o mesmo clique, mais agudo e baixo, no
## máximo um a cada HOVER_GAP_MS), no barramento Interface. A interface não precisa saber do áudio. Sem tela, só conta.

const CLICK := "res://assets/audio/sfx/ui_click.ogg"
const HOVER_GAP_MS := 60
const HOVER_VOLUME_DB := -14.0
const HOVER_PITCH := 1.6

## Quantas vezes cada som tocou (testes).
var played: Dictionary[StringName, int] = {}

var _click: AudioStream
var _player := AudioStreamPlayer.new()
var _hover_player := AudioStreamPlayer.new()
var _audible: bool = false
var _last_hover: int = -100000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audible = DisplayServer.get_name() != "headless"
	if ResourceLoader.exists(CLICK):
		_click = load(CLICK) as AudioStream
	for player: AudioStreamPlayer in [_player, _hover_player]:
		player.bus = &"Interface"
		player.stream = _click
		add_child(player)
	_hover_player.volume_db = HOVER_VOLUME_DB
	_hover_player.pitch_scale = HOVER_PITCH
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.pressed.is_connected(click):
		return
	button.pressed.connect(click)
	button.mouse_entered.connect(hover.bind(button))


func click() -> void:
	played[&"click"] = played.get(&"click", 0) + 1
	if _audible and _click != null:
		_player.play()


## Fase 44: o fim da partida — a fanfarra do marco na vitória; na derrota, o alerta mais grave e lento.
const VICTORY := "res://assets/audio/sfx/milestone.ogg"
const DEFEAT := "res://assets/audio/sfx/alert.ogg"
const DEFEAT_PITCH := 0.7

var _cue_player := AudioStreamPlayer.new()


func end_of_game(won: bool) -> void:
	var key := &"victory" if won else &"defeat"
	played[key] = played.get(key, 0) + 1
	if not _audible:
		return
	var path := VICTORY if won else DEFEAT
	if not ResourceLoader.exists(path):
		return
	if _cue_player.get_parent() == null:
		_cue_player.bus = &"Interface"
		add_child(_cue_player)
	_cue_player.stream = load(path) as AudioStream
	_cue_player.pitch_scale = 1.0 if won else DEFEAT_PITCH
	_cue_player.play()


func hover(button: BaseButton) -> void:
	if button.disabled:
		return
	var now := Time.get_ticks_msec()
	if now - _last_hover < HOVER_GAP_MS:
		return
	_last_hover = now
	played[&"hover"] = played.get(&"hover", 0) + 1
	if _audible and _click != null:
		_hover_player.play()
