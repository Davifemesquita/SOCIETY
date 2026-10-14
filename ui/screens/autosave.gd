class_name Autosave
extends Node
## Salvamento automático (seção 12): a cada Settings.autosave_minutes de jogo (contados nos ticks da
## partida: com o jogo pausado não salva), grava no mais antigo dos autosave_slots slots
## "autosave_N", que se revezam. O "Continuar" do menu pega o save mais recente, que pode ser este.

const SLOT_PREFIX := "autosave_"

var _game: GameScreen
var _config: GameConfig
var _last_tick: int = 0


func setup(game: GameScreen, config: GameConfig) -> void:
	_game = game
	_config = config
	_last_tick = game.simulation.world.tick
	EventBus.world_replaced.connect(func() -> void: _last_tick = _game.simulation.world.tick)


func _process(_delta: float) -> void:
	if Settings.autosave_minutes <= 0.0:
		return
	var interval := roundi(Settings.autosave_minutes * 60.0 * _config.ticks_per_second)
	if _game.simulation.world.tick - _last_tick >= interval:
		save_now()


## Grava agora no slot da vez; devolve o slot usado (vazio se falhou).
func save_now() -> String:
	_last_tick = _game.simulation.world.tick
	var slot := next_slot(SaveSystem.list_slots(), _config.autosave_slots)
	var number := slot.trim_prefix(SLOT_PREFIX)
	return slot if _game.save_game(slot, tr("SAVE_AUTOSAVE_NAME") % number, "MSG_AUTOSAVED") else ""


## O slot livre, ou o mais antigo dos automáticos (a lista vem do mais novo para o mais velho).
static func next_slot(existing: PackedStringArray, slots: int) -> String:
	for n: int in range(1, slots + 1):
		if not existing.has(SLOT_PREFIX + str(n)):
			return SLOT_PREFIX + str(n)
	for index: int in range(existing.size() - 1, -1, -1):
		if existing[index].begins_with(SLOT_PREFIX):
			return existing[index]
	return SLOT_PREFIX + "1"
