class_name RailSystem
extends RefCounted
## Ferrovia (Fase 70): a cada tick, o trilho leva o bem dos poços ligados (DerivedState.rail_feeds) até a usina, até a
## usina guardar rail_input_buffer_t toneladas; o poço sem trilho enche a saída e para (saída cheia), como qualquer
## produção. Sem carroça: o trem é instantâneo nesta versão.


static func run(world: WorldState, config: GameConfig, derived: DerivedState) -> void:
	for receiver_id: int in derived.rail_feeds:
		var receiver := world.building(receiver_id)
		if receiver == null:
			continue
		var senders: Array = derived.rail_feeds[receiver_id]
		for sender: DerivedState.ProductionEntry in senders:
			var good := sender.def.output
			var held: float = receiver.input_buffer.get(good, 0.0)
			var room := config.rail_input_buffer_t - held
			if room <= 0.0:
				continue
			var moved := minf(room, sender.record.output_buffer)
			if moved <= 0.0:
				continue
			sender.record.output_buffer -= moved
			receiver.input_buffer[good] = held + moved
