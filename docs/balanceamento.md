# Balanceamento — partida do jogador-robô

Gerado por `tools/balance_report.tscn` em 2026-10-14T14:48:19. O robô (`tools/auto_player.gd`) joga na ilha plana,
dificuldade normal, pagando cada prédio, esperando material e desbloqueio, com carroças e armazéns;
corrige faltas pondo o produtor na frente da fila e pausa fábrica com o estoque cheio.

- Pior saldo: **-7614** aos 90 min (limite para construir: -10000).
- Prédios no fim: 880; casas: 488.

| min | Camponeses | Operários | Artesãos | Engenheiros | Investidores | casas | saldo | renda/min | manutenção/min | próximo da fila | parado por |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | 453 | 11 | 0 | 0 | 0 | 49 | 47381 | 283 | 325 | weavery | REASON_NO_MATERIALS |
| 30 | 209 | 367 | 0 | 0 | 0 | 49 | 51083 | 493 | 380 | soap_factory | REASON_NO_MATERIALS |
| 45 | 501 | 902 | 0 | 0 | 0 | 115 | 40892 | 1295 | 885 | sawmill | REASON_NO_MATERIALS |
| 60 | 809 | 1825 | 0 | 0 | 0 | 191 | 29119 | 2538 | 1850 | lumberjack |  |
| 75 | 1517 | 2200 | 239 | 0 | 0 | 287 | -1920 | 4048 | 3760 | butcher | REASON_NO_MATERIALS |
| 90 | 1391 | 2520 | 386 | 0 | 0 | 287 | -7395 | 4996 | 4535 | weavery | WORKFORCE |
| 105 | 1388 | 2516 | 424 | 0 | 0 | 287 | -2178 | 4816 | 4565 | pig_farm | WORKFORCE |
| 120 | 1435 | 2515 | 446 | 0 | 0 | 294 | 1000 | 5217 | 4750 | pig_farm | WORKFORCE |
| 135 | 1604 | 2535 | 449 | 0 | 0 | 309 | 1849 | 5371 | 4880 | pig_farm | WORKFORCE |
| 150 | 1717 | 2159 | 1001 | 0 | 0 | 318 | -2436 | 6277 | 5620 | weavery | WORKFORCE |
| 165 | 2406 | 2797 | 1280 | 0 | 0 | 448 | 2358 | 8116 | 6338 | furnace | RESERVE |
| 180 | 2442 | 3013 | 1850 | 0 | 0 | 488 | 3912 | 9046 | 7880 | cannery |  |

## O que a partida mostra (14/10/2026)

- **O dinheiro não trava um jogador cuidadoso**: o pior saldo fica em −7,6 mil (limite −10 mil), no
  meio da partida, quando a indústria pesada (fundição, vigas, minas) entra antes de haver artesãos
  para consumir o aço. Pausar a fábrica com o estoque cheio (metade da manutenção) é o que segura.
- **Manutenção e imposto andam colados** (no fim, 9,0 mil de renda contra 7,9 mil de manutenção por
  minuto). Os números das cadeias de base (manutenção e imposto) são os da tabela da especificação;
  não foram mexidos. Se a partida tiver de folgar, os candidatos são, nesta ordem: a manutenção da
  fundição e da oficina de vigas (100 cada), a felicidade base (50, que dá imposto × 1,0) e o
  intervalo do comerciante.
- **Roupa de lã é o gargalo de escala**: 0,004 t/min por morador (uma tecelagem para 500 pessoas) faz
  a população de 5 mil pedir 10 tecelagens e 10 fazendas de ovelhas.
- **Ritmo**: operários aos ~20 min, artesãos aos ~75 min; engenheiros não chegam em 3 h com este
  robô, que joga em fila e corrige uma falta por vez. A quinta classe é alcançável (critério da Fase
  8, `tests/sim/test_phase8_criteria.gd`), mas pede um jogador mais rápido que o robô.
