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
## Fase 32: no máximo tantos quadros a mais esperando quem segura a cortina (grupo WarmUp.HOLD_GROUP).
const MAX_HOLD_FRAMES := 60
const TEXT_COLOR := Color(0.93, 0.87, 0.72)

## Troca sempre direta (testes que montam telas por conta própria).
var instant: bool = false
var busy: bool = false

## Fase 42: dicas do jogo novo (chaves LOADING_TIP_1 a LOADING_TIP_<TIPS>), sorteadas a cada geração.
const TIPS := 8

var _curtain := ColorRect.new()
var _label := Label.new()
## Fase 42: a barra do progresso de verdade (a geração do arquipélago em threads) e a dica embaixo.
var _bar := ProgressBar.new()
var _tip := Label.new()


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
	_bar.name = "Progress"
	_bar.set_anchors_preset(Control.PRESET_CENTER)
	_bar.custom_minimum_size = Vector2(520, 14)
	_bar.position = Vector2(-260, 56)
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.visible = false
	_curtain.add_child(_bar)
	_tip.name = "Tip"
	_tip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.custom_minimum_size = Vector2(1100, 0)
	_tip.position = Vector2(-550, -120)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.add_theme_color_override(&"font_color", TEXT_COLOR.darkened(0.15))
	_tip.visible = false
	_curtain.add_child(_tip)


## A troca é direta (sem cortina)?
func is_instant() -> bool:
	return instant or DisplayServer.get_name() == "headless" or OS.get_environment("SOCIETY_SEM_TRANSICAO") == "1"


## Fase 43: as animações de interface e de obra ficam paradas — sem tela (como is_instant) ou com "reduzir movimento"
## nas opções (contadores, pulso de ganho, squash da obra, afundar da demolição, esmaecer dos avisos, zoom suave).
func still() -> bool:
	return is_instant() or Settings.reduce_motion


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
	# Fase 32: a primeira vez de cada material (WarmUp) termina no escuro
	var held := 0
	while held < MAX_HOLD_FRAMES and get_tree().get_first_node_in_group(WarmUp.HOLD_GROUP) != null:
		await get_tree().process_frame
		held += 1
	_label.visible = false
	var lighten := create_tween()
	lighten.tween_property(_curtain, ^"color:a", 0.0, FADE_S)
	await lighten.finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	finished.emit()


## Fase 42: a cortina em volta do jogo novo — escurece, gera o arquipélago em threads mostrando o progresso de verdade
## (barra e porcentagem) e uma dica, e só então chama a troca (que usa o job.result()). Direta (sem tela, testes): gera
## de uma vez e troca.
func change_with_job(job: ArchipelagoJob, swap: Callable, message_key: String = "") -> void:
	if busy:
		return
	if is_instant():
		job.start(false)
		swap.call()
		finished.emit()
		return
	busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_label.text = tr(message_key) if not message_key.is_empty() else ""
	_label.visible = not message_key.is_empty()
	_tip.text = tr("LOADING_TIP_%d" % (randi() % TIPS + 1))
	_tip.visible = true
	_bar.value = 0.0
	_bar.visible = true
	var darken := create_tween()
	darken.tween_property(_curtain, ^"color:a", 1.0, FADE_S)
	await darken.finished
	job.start(true)
	while not job.poll():
		_show_progress(message_key, job.progress())
		await get_tree().process_frame
	_show_progress(message_key, 1.0)
	await get_tree().process_frame
	_bar.visible = false
	# montar as vistas da partida ainda é na thread principal (~5 s no arquipélago cheio): o texto diz o que é
	_label.text = tr("LOADING_BUILDING")
	await get_tree().process_frame
	# o resto (montar a partida no escuro e clarear) é a troca de sempre, com a cortina já escura
	await _finish_swap(swap)


func _show_progress(message_key: String, value: float) -> void:
	_bar.value = value
	if not message_key.is_empty():
		_label.text = "%s %d%%" % [tr(message_key), roundi(value * 100.0)]


## A troca com a cortina já escura: monta a cena nova, espera ela assentar e quem segura a cortina, e clareia.
func _finish_swap(swap: Callable) -> void:
	busy = true
	swap.call()
	for frame: int in SETTLE_FRAMES:
		await get_tree().process_frame
	var held := 0
	while held < MAX_HOLD_FRAMES and get_tree().get_first_node_in_group(WarmUp.HOLD_GROUP) != null:
		await get_tree().process_frame
		held += 1
	_label.visible = false
	_tip.visible = false
	var lighten := create_tween()
	lighten.tween_property(_curtain, ^"color:a", 0.0, FADE_S)
	await lighten.finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	finished.emit()


## A barra e a dica (testes).
func progress_bar() -> ProgressBar:
	return _bar


func tip_label() -> Label:
	return _tip


## A cortina agora: o quanto está escura (0 a 1) e se come a entrada (testes).
func curtain_alpha() -> float:
	return _curtain.color.a


func blocks_input() -> bool:
	return _curtain.mouse_filter == Control.MOUSE_FILTER_STOP


## Fase 44: recolhe as prévias do jogo novo que ficaram rodando depois que o diálogo fechou.
func _process(_delta: float) -> void:
	ArchipelagoPreview.reap()


func _input(event: InputEvent) -> void:
	if busy and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
