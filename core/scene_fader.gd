extends CanvasLayer
## Autoload SceneFader (Fase 30): a troca de tela escurece em FADE_S, mostra o que está sendo montado ("Gerando o
## arquipélago…", "Carregando…"), troca a cena e clareia. A cena nova monta tudo no _ready, de forma síncrona: o
## escuro cobre esse tempo. Enquanto a cortina aparece, ela come o mouse e o teclado, para um atalho apertado no escuro
## não cair na tela que está saindo.
## Sem tela (headless), com SOCIETY_SEM_TRANSICAO=1 (posto pelo tools/godot.sh testes) ou com `instant`, a troca é
## direta: os testes e o benchmark não esperam animação.

signal finished

const FADE_S := 0.35
## Quadros depois da troca antes de clarear: a cena nova entra no fim do quadro da troca e faz o _ready no seguinte.
const SETTLE_FRAMES := 2
const TEXT_COLOR := Color(0.93, 0.87, 0.72)

## Troca sempre direta (testes que montam telas por conta própria).
var instant: bool = false
var busy: bool = false

var _curtain := ColorRect.new()
var _label := Label.new()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain.name = "Curtain"
	_curtain.color = Color(0.0, 0.0, 0.0, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)
	_label.name = "Message"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.theme_type_variation = &"BigLabel"
	_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	_label.visible = false
	_curtain.add_child(_label)


## A troca é direta (sem cortina)?
func is_instant() -> bool:
	return instant or DisplayServer.get_name() == "headless" or OS.get_environment("SOCIETY_SEM_TRANSICAO") == "1"


## Troca para a cena em "path", escurecendo antes e clareando depois; "message_key" é a chave do texto que aparece no
## escuro (vazio, nenhum).
func change_to(path: String, message_key: String = "") -> void:
	await change_with(func() -> void: get_tree().change_scene_to_file(path), message_key)


## A cortina em volta de uma troca qualquer ("swap"): escurece, chama a troca, espera a tela nova montar e clareia.
## Separada da troca de cena para o teste poder rodar a cortina sem trocar a cena do executor de testes.
func change_with(swap: Callable, message_key: String = "") -> void:
	if busy:
		return
	if is_instant():
		swap.call()
		finished.emit()
		return
	busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_label.text = tr(message_key) if not message_key.is_empty() else ""
	_label.visible = not message_key.is_empty()
	var darken := create_tween()
	darken.tween_property(_curtain, ^"color:a", 1.0, FADE_S)
	await darken.finished
	# um quadro com o texto na tela antes da montagem síncrona da cena nova
	await get_tree().process_frame
	swap.call()
	for frame: int in SETTLE_FRAMES:
		await get_tree().process_frame
	_label.visible = false
	var lighten := create_tween()
	lighten.tween_property(_curtain, ^"color:a", 0.0, FADE_S)
	await lighten.finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	finished.emit()


## A cortina agora: o quanto está escura (0 a 1) e se come a entrada (testes).
func curtain_alpha() -> float:
	return _curtain.color.a


func blocks_input() -> bool:
	return _curtain.mouse_filter == Control.MOUSE_FILTER_STOP


func _input(event: InputEvent) -> void:
	if busy and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
