class_name AdvisorDialogue
extends RefCounted
## Adaptador do Dialogue Manager (seção 13): a única peça que conhece o addon. Lê um bloco de
## ui/advisor/advisor.dialogue e devolve as falas, já traduzidas pelo addon (cada fala do arquivo é
## uma chave do strings.csv). O
## addon é usado só por get_node/call: sem ele, o conselheiro fica calado e o jogo segue.

const DIALOGUE_PATH := "res://ui/advisor/advisor.dialogue"
const MANAGER := ^"/root/DialogueManager"


## Falas do bloco title, em ordem; vazio se o bloco ou o addon não existem.
static func lines(tree: SceneTree, title: String) -> Array[String]:
	var result: Array[String] = []
	var manager := tree.root.get_node_or_null(MANAGER)
	if manager == null or not ResourceLoader.exists(DIALOGUE_PATH):
		return result
	var resource: Resource = load(DIALOGUE_PATH)
	var cues: Variant = resource.get(&"cues")
	if cues is Dictionary:
		var known: Dictionary = cues
		if not known.has(title):
			return result
	var raw: Variant = await manager.call(&"get_next_dialogue_line", resource, title)
	while raw is Object:
		var line: Object = raw
		var text: Variant = line.get(&"text")
		if text is String:
			result.append(text)
		raw = await manager.call(&"get_next_dialogue_line", resource, line.get(&"next_id"))
	return result
