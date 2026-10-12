extends Node
## Barramento de eventos tipados. A simulação emite; interface, áudio e 3D só escutam.
## Os sinais são emitidos por outros scripts, por isso o aviso de sinal sem uso fica desligado.

@warning_ignore_start("unused_signal")

## A velocidade do jogo mudou. speed_index é TickClock.PAUSED quando pausado.
signal time_speed_changed(speed_index: int, paused: bool)
signal game_saved(slot: String)
signal game_loaded(slot: String)
signal save_failed(slot: String, reason: String)
signal settings_changed()
