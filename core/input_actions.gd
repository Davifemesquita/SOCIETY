class_name InputActions
extends RefCounted
## Atalhos padrão do jogo, registrados no InputMap ao iniciar. Teclas de letra usam a
## posição física (funciona igual em ABNT2 e US). A tela de remapear entra na Fase 7.

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
	&"debug_grid": [KEY_F1],
	&"debug_roads": [KEY_F2],
	&"game_statistics": [KEY_TAB],
	&"debug_cheat_resources": [KEY_F8],
}


static func register_defaults() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode: int in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode as Key
			InputMap.action_add_event(action, event)
