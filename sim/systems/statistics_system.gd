class_name StatisticsSystem
extends RefCounted
## Último sistema do tick (seção 12): a cada history_interval_s de jogo, uma amostra do histórico
## das estatísticas (gráficos). Determinístico: depende só do tick.


static func run(world: WorldState, data: GameData, config: GameConfig, derived: DerivedState) -> void:
	var every := maxi(1, roundi(config.history_interval_s * config.ticks_per_second))
	if world.tick % every == 0:
		world.history.record(world, data, derived, config.history_samples)
