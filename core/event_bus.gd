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

## Mundo: a simulação emite depois de aplicar um comando.
signal building_placed(building_id: int)
signal building_removed(building_id: int)
signal roads_changed(island_id: int)
## O mundo inteiro foi trocado (jogo novo ou carregado): a apresentação refaz tudo.
signal world_replaced()
