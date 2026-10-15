class_name InputActions
extends RefCounted
## Atalhos padrão do jogo, registrados no InputMap ao iniciar. Teclas de letra usam a
## posição física (funciona igual em ABNT2 e US). O jogador troca as teclas nas opções
## (Settings.key_bindings); as de depuração (F1, F2, F7, F8) e o Esc do menu não se trocam.

const KEYS: Dictionary[StringName, Array] = {
	&"camera_pan_left": [KEY_A, KEY_LEFT],
	&"camera_pan_right": [KEY_D, KEY_RIGHT],
	&"camera_pan_forward": [KEY_W, KEY_UP],
	&"camera_pan_back": [KEY_S, KEY_DOWN],
	&"camera_rotate_left": [KEY_Q],
	&"camera_rotate_right": [KEY_E],
	&"camera_center_selected": [KEY_F],
	&"build_rotate": [KEY_R],
	&"build_cancel": [KEY_ESCAPE],
	&"build_road": [KEY_T],
	&"build_demolish": [KEY_DELETE, KEY_X],
	&"time_pause": [KEY_SPACE],
	&"time_speed_1": [KEY_1],
	&"time_speed_2": [KEY_2],
	&"time_speed_3": [KEY_3],
	&"game_quicksave": [KEY_F5],
	&"game_quickload": [KEY_F9],
	&"game_statistics": [KEY_TAB],
	&"game_routes": [KEY_B],
	&"game_missions": [KEY_J],
	&"game_rivals": [KEY_K],
	&"game_specialists": [KEY_L],
	&"game_menu": [KEY_ESCAPE],
	&"debug_grid": [KEY_F1],
	&"debug_roads": [KEY_F2],
	&"debug_advance_hours": [KEY_F7],
	&"debug_cheat_resources": [KEY_F8],
}

## Ações que não aparecem na tela de remapear.
const FIXED: Array[StringName] = [&"build_cancel", &"game_menu", &"debug_grid", &"debug_roads",
		&"debug_advance_hours", &"debug_cheat_resources"]


static func register_defaults() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		_set_keys(action, PackedInt32Array(KEYS[action]))


## Ações que o jogador pode trocar, na ordem da lista.
static func remappable() -> Array[StringName]:
	var actions: Array[StringName] = []
	for action: StringName in KEYS:
		if not FIXED.has(action):
			actions.append(action)
	return actions


## Põe as teclas do jogador (ou as padrão) no InputMap.
static func apply_bindings(bindings: Dictionary[StringName, PackedInt32Array]) -> void:
	for action: StringName in remappable():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_set_keys(action, bindings[action] if bindings.has(action) else PackedInt32Array(KEYS[action]))


static func _set_keys(action: StringName, keycodes: PackedInt32Array) -> void:
	InputMap.action_erase_events(action)
	for keycode: int in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode as Key
		InputMap.action_add_event(action, event)


## Nome da tecla física no teclado do jogador (ABNT2 mostra a letra que está nela).
static func key_name(physical_keycode: int) -> String:
	var label := DisplayServer.keyboard_get_label_from_physical(physical_keycode as Key)
	return OS.get_keycode_string(label if label != KEY_NONE else physical_keycode as Key)
