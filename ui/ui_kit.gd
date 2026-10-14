class_name UiKit
extends RefCounted
## Peças repetidas da interface, todas no Theme único: botão com ícone e dica, rótulo por
## variação do Theme e o cabeçalho das janelas (título e fechar). Todo botão leva ícone (critério
## da Fase 7) e dica; o texto é chave de tradução (o Godot traduz sozinho).


## Botão com ícone e texto. tooltip_key vazio usa o próprio texto como dica.
static func button(text_key: String, icon_name: String, action: Callable = Callable(), tooltip_key: String = "") -> Button:
	var result := Button.new()
	result.text = text_key
	result.icon = Icons.get_icon(icon_name)
	result.focus_mode = Control.FOCUS_NONE
	result.tooltip_text = tooltip_key if not tooltip_key.is_empty() else text_key
	if action.is_valid():
		result.pressed.connect(action)
	return result


## Botão só de ícone; a dica diz o que ele faz.
static func icon_button(icon_name: String, tooltip_key: String, action: Callable = Callable()) -> Button:
	var result := Button.new()
	result.theme_type_variation = &"IconButton"
	result.icon = Icons.get_icon(icon_name)
	result.focus_mode = Control.FOCUS_NONE
	result.tooltip_text = tooltip_key
	if action.is_valid():
		result.pressed.connect(action)
	return result


static func label(text: String, variation: StringName = &"") -> Label:
	var result := Label.new()
	result.text = text
	result.theme_type_variation = variation
	return result


## Ícone pequeno ao lado de um texto (estado, bem, classe).
static func icon_rect(texture: Texture2D, side: int = 24) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(side, side)
	rect.mouse_filter = Control.MOUSE_FILTER_PASS
	return rect


## Linha de ícone + rótulo (o rótulo é devolvido no índice 1 dos filhos).
static func icon_line(texture: Texture2D, text: String = "", side: int = 24) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	row.add_child(icon_rect(texture, side))
	var text_label := label(text)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_label)
	return row


## Cabeçalho de janela: título à esquerda e o botão de fechar à direita.
static func header(title_key: String, close: Callable, title: Label = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	var heading := title if title != null else label(title_key, &"TitleLabel")
	if title != null:
		heading.theme_type_variation = &"TitleLabel"
		if not title_key.is_empty():
			heading.text = title_key
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	var close_button := icon_button("action_close", "UI_CLOSE", close)
	close_button.name = "Close"
	row.add_child(close_button)
	return row


## Tira os filhos já fora da árvore (o nome fica livre para o novo de mesmo nome) e libera.
static func clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
