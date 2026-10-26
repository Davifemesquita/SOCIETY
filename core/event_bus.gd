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
## A construção derrubou árvores na área (células da ilha).
signal trees_changed(island_id: int, area: Rect2i)
## O mundo inteiro foi trocado (jogo novo ou carregado): a apresentação refaz tudo.
signal world_replaced()

## Economia: a simulação emite durante o tick.
## Estado de produção, pausa ou bloqueio de upgrade de um prédio mudou.
signal building_state_changed(building_id: int)
signal house_upgraded(building_id: int)
## Um bem de consumo começou a faltar na ilha (avisado uma vez por queda).
signal good_shortage(island_id: int, good: StringName)

## Navios e comércio (Fase 6).
## Navio comprado, mandado, posto em rota ou carga mexida à mão: a interface refaz o painel.
signal ships_changed()
## Rotas criadas, editadas ou apagadas.
signal routes_changed()
## Um marco de população foi atingido (o número de marcos atingidos até agora).
signal milestone_reached(count: int)
## O navio do comerciante negociou numa ilha (moedas que o jogador recebeu e pagou).
signal trader_visited(island_id: int, earned: float, spent: float)
## Um entreposto foi fundado numa ilha a partir de um navio (colonização).
signal island_colonized(island_id: int)

## Metas guiadas (Fase 8): a meta de índice index foi cumprida (e a seguinte, se houver, começou).
signal goal_completed(index: int)

## Interface (Fase 10): uma notificação apareceu (o ícone diz o tipo; o áudio toca o som dela).
signal notice_shown(icon: String)

## Eventos e encomendas (Fase 11).
## Um evento começou ou acabou (island_id -1 = o arquipélago todo).
signal world_event_started(def_id: StringName, island_id: int)
signal world_event_ended(def_id: StringName, island_id: int)
## O comerciante ofereceu uma encomenda; uma aceita foi cumprida (prêmio em moedas) ou venceu.
signal mission_offered(mission_id: int)
signal mission_completed(def_id: StringName, bonus: int)
## A oferta que não foi respondida ou a encomenda aceita que passou do prazo (accepted diz qual).
signal mission_expired(def_id: StringName, accepted: bool)
## Encomenda aceita, recusada ou entregue em parte: a janela refaz a lista.
signal missions_changed()

## Companhias rivais (Fase 11): uma fundou colônia numa ilha; a postura dela mudou (RivalState.Stance);
## presente, acordo, guerra ou paz pedidos pelo jogador (a janela refaz).
signal rival_colonized(rival_id: StringName, island_id: int)
signal rival_stance_changed(rival_id: StringName, stance: int)
signal rivals_changed()

## Combate naval (Fase 11): um navio atirou em outro; um navio afundou (dono e onde, para a vista).
signal ship_fired(attacker_id: int, target_id: int)
signal ship_sunk(ship_id: int, owner: int, position: Vector2)

## Especialistas (Fase 11): a oferta da volta chegou; a lista ou um posto mudou.
signal specialists_offered()
signal specialists_changed()

## Riscos (seção 8): fogo num prédio; o fogo acabou (apagado, ou o prédio se perdeu: lost, já fora
## do mundo, com o tipo e a ilha para o aviso); doença numa casa e a cura dela.
signal fire_started(building_id: int)
signal fire_ended(building_id: int, lost: bool)
signal building_lost(building_id: int, def_id: StringName, island_id: int)
signal outbreak_started(house_id: int)
signal outbreak_ended(house_id: int)

## Estaleiro: o navio encomendado ficou pronto e está no porto da ilha.
signal ship_built(ship_id: int)

## Objetivo da partida (Fase 12): cumprido; prazo vencido sem cumprir. Uma conquista ganha agora.
signal match_won()
signal match_lost()
signal achievement_unlocked(achievement_id: StringName)
## Fase 49: as plantas mudaram (desenhada, apagada, construída, desfeita).
signal plans_changed()
