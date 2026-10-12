class_name CommandContext
extends RefCounted
## O que um comando enxerga: o mundo, as definições e a configuração.
## free_build é trapaça de desenvolvimento (benchmark, testes): ignora custo e desbloqueio.

var world: WorldState
var data: GameData
var config: GameConfig
var free_build: bool = false


func _init(state: WorldState, game_data: GameData, game_config: GameConfig, free: bool) -> void:
	world = state
	data = game_data
	config = game_config
	free_build = free
