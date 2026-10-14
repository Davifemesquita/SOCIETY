class_name GoalPanel
extends VBoxContainer
## Metas guiadas na tela (Fase 8): a meta da vez com o progresso, e a fala do conselheiro (retrato,
## texto e "continuar") quando a partida começa e quando uma meta é cumprida. As falas vêm do
## AdvisorDialogue; o botão do retrato repete a fala da meta atual.

var _simulation: Simulation
var _goal_row := PanelContainer.new()
var _goal_title := Label.new()
var _goal_progress := Label.new()
var _speech := PanelContainer.new()
var _speech_text := Label.new()
var _next_button: Button
## Falas que ainda vão aparecer (chaves de tradução).
var _queue: Array[String] = []
var _refresh_left: float = 0.0


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 6)
	_build_goal_row()
	_build_speech()
	EventBus.goal_completed.connect(_on_goal_completed)
	EventBus.world_replaced.connect(_on_world_replaced)
	_on_world_replaced()


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = 0.5
		refresh()


## Título e progresso da meta da vez; sem meta, o painel diz que a partida está livre.
func refresh() -> void:
	var world := _simulation.world
	var goal := GoalSystem.current(world, _simulation.data)
	if goal == null:
		_goal_title.text = tr("GOAL_ALL_DONE")
		_goal_progress.text = ""
		return
	_goal_title.text = title_of(goal)
	if world.milestones_reached < goal.after_milestone:
		_goal_progress.text = tr("GOAL_WAITS_MILESTONE") % Fmt.integer(_simulation.config.population_milestones[goal.after_milestone - 1])
		return
	var done := GoalSystem.progress(world, _simulation.data, _simulation.config, _simulation.derived_state(), goal)
	_goal_progress.text = tr("GOAL_PROGRESS") % [Fmt.integer(mini(done, goal.amount)), Fmt.integer(goal.amount),
			Fmt.integer(goal.reward_money)]


## Título da meta, com a quantidade quando o texto a pede.
static func title_of(goal: GoalDef) -> String:
	var text := TranslationServer.translate(goal.title_key())
	return text % Fmt.integer(goal.amount) if text.contains("%s") else text


## Fala do conselheiro em andamento (o texto traduzido), ou vazio.
func speech_text() -> String:
	return _speech_text.text if _speech.visible else ""


## O conselheiro fala os blocos de advisor.dialogue, nesta ordem (acrescenta à fila).
func speak(titles: Array[String]) -> void:
	for title: String in titles:
		var lines := await AdvisorDialogue.lines(get_tree(), title)
		_queue.append_array(lines)
	if not _speech.visible:
		advance()


## Próxima fala da fila, ou fecha a fala quando ela acaba.
func advance() -> void:
	if _queue.is_empty():
		_speech.visible = false
		return
	var key: String = _queue.pop_front()
	_speech_text.text = tr(key)
	_speech.visible = true


func speak_current() -> void:
	var goal := GoalSystem.current(_simulation.world, _simulation.data)
	speak([String(goal.id) if goal != null else "all_done"])


func _build_goal_row() -> void:
	_goal_row.name = "Goal"
	_goal_row.theme_type_variation = &"NoticePanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	_goal_row.add_child(row)
	var advisor := UiKit.icon_button("action_advisor", "GOAL_ADVISOR_TIP", speak_current)
	advisor.name = "Advisor"
	row.add_child(advisor)
	row.add_child(UiKit.icon_rect(Icons.action("goal"), 28))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	_goal_title.theme_type_variation = &"HeaderLabel"
	_goal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_title.custom_minimum_size.x = 300
	column.add_child(_goal_title)
	_goal_progress.theme_type_variation = &"DimLabel"
	column.add_child(_goal_progress)
	row.add_child(column)
	add_child(_goal_row)


func _build_speech() -> void:
	_speech.name = "Speech"
	_speech.theme_type_variation = &"MenuPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	_speech.add_child(row)
	var portrait := UiKit.icon_rect(Icons.portrait("advisor"), 96)
	portrait.custom_minimum_size = Vector2(80, 100)
	portrait.tooltip_text = "PORTRAIT_ADVISOR"
	row.add_child(portrait)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	column.add_child(UiKit.label("PORTRAIT_ADVISOR", &"HeaderLabel"))
	_speech_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech_text.custom_minimum_size.x = 340
	column.add_child(_speech_text)
	_next_button = UiKit.button("GOAL_CONTINUE", "action_confirm", advance, "GOAL_CONTINUE_TIP")
	_next_button.name = "Continue"
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	column.add_child(_next_button)
	row.add_child(column)
	_speech.visible = false
	add_child(_speech)


func _on_goal_completed(index: int) -> void:
	var goals := _simulation.data.goals
	if index < 0 or index >= goals.size():
		return
	# o aviso chega no meio do tick: a fala (que lê o Dialogue Manager) fica para depois dele
	var titles: Array[String] = [String(goals[index].id) + "_done", String(goals[index + 1].id) if index + 1 < goals.size() else "all_done"]
	speak.call_deferred(titles)
	refresh.call_deferred()


## Partida nova: o conselheiro apresenta a primeira meta. Partida carregada: só o painel.
func _on_world_replaced() -> void:
	_queue.clear()
	_speech.visible = false
	refresh()
	if _simulation.world.tick == 0 and _simulation.world.goals_done == 0:
		speak_current()
