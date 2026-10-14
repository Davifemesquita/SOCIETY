class_name Modal
extends Control
## Fundo escurecido que segura uma janela no meio da tela e bloqueia o clique no que está atrás.
## O Esc (ou o fechar da janela) fecha; o Esc é lido em _input, antes dos atalhos da partida. A janela de dentro avisa pelo sinal closed dela, se tiver.

signal closed()

var content: Control


## Abre a janela por cima de tudo em parent.
static func open(parent: Node, window: Control) -> Modal:
	var modal := Modal.new()
	modal.name = "Modal_" + window.name
	modal.content = window
	parent.add_child(modal)
	return modal


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.02, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(content)
	if content.has_signal(&"closed"):
		content.connect(&"closed", close)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key: InputEventKey = event
		if key.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			# a janela que grava ao fechar (opções) fecha pelo próprio caminho
			if content.has_method(&"close"):
				content.call(&"close")
			else:
				close()


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	get_parent().remove_child(self)
	queue_free()

