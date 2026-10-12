extends Node
## Fonte da verdade do tempo. Converte cada quadro em ticks fixos de simulação
## e avisa quem roda a simulação pelo sinal ticked, um por tick.

signal ticked(tick_index: int)

var clock: TickClock


func _init() -> void:
	clock = TickClock.new(GameConfig.get_default())


func _process(delta: float) -> void:
	step(delta)


## Avança o tempo real de um quadro e emite um ticked por tick devido.
func step(real_delta: float) -> int:
	var due := clock.advance(real_delta)
	var first := clock.tick_count - due + 1
	for i: int in due:
		ticked.emit(first + i)
	return due


func set_speed(index: int) -> void:
	if clock.set_speed(index):
		EventBus.time_speed_changed.emit(clock.speed_index, clock.is_paused())


func toggle_pause() -> void:
	clock.toggle_pause()
	EventBus.time_speed_changed.emit(clock.speed_index, clock.is_paused())
