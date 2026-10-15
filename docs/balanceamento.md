# Balanceamento — partida do jogador-robô

Gerado por `tools/balance_report.tscn` em 2026-10-15T15:28:15. O robô (`tools/auto_player.gd`) joga na ilha plana,
dificuldade normal, pagando cada prédio, esperando material e desbloqueio, com carroças e armazéns;
corrige faltas pondo o produtor na frente da fila e pausa fábrica com o estoque cheio.

- Pior saldo: **1472** aos 112 min (limite para construir: -10000).
- Prédios no fim: 935; casas: 488.

| min | Camponeses | Operários | Artesãos | Engenheiros | Investidores | casas | saldo | renda/min | manutenção/min | próximo da fila | parado por |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | 209 | 147 | 0 | 0 | 0 | 33 | 51863 | 273 | 305 | sawmill | REASON_NO_MATERIALS |
| 30 | 615 | 307 | 0 | 0 | 0 | 85 | 35847 | 707 | 860 | sawmill | REASON_NO_MATERIALS |
| 45 | 588 | 999 | 0 | 0 | 0 | 122 | 36466 | 1454 | 920 | sawmill | REASON_NO_MATERIALS |
| 60 | 706 | 1213 | 0 | 0 | 0 | 152 | 35660 | 1725 | 1380 | lumberjack |  |
| 75 | 996 | 2709 | 0 | 0 | 0 | 259 | 22158 | 3791 | 2460 | sawmill | REASON_NO_MATERIALS |
| 90 | 1292 | 3022 | 560 | 0 | 0 | 315 | 11533 | 5536 | 4170 | furnace | REASON_NO_MATERIALS |
| 105 | 1681 | 1788 | 1836 | 0 | 0 | 383 | 18250 | 6798 | 4595 | soap_factory | WORKFORCE |
| 120 | 1871 | 2456 | 2440 | 0 | 0 | 424 | 13748 | 9047 | 6465 |  |  |
| 135 | 2350 | 2657 | 2524 | 0 | 0 | 488 | 38250 | 9926 | 7375 |  |  |
| 150 | 2336 | 2753 | 2599 | 0 | 0 | 488 | 68166 | 10318 | 7640 | weavery | WORKFORCE |
| 165 | 2374 | 2778 | 2630 | 0 | 0 | 488 | 109236 | 10472 | 7750 | butcher | WORKFORCE |
| 180 | 2374 | 2778 | 2632 | 0 | 0 | 488 | 154173 | 10478 | 7690 | butcher | WORKFORCE |
## O que a partida mostra (15/10/2026)

- **O aperto de dinheiro era um defeito da subida de classe, não dos números.** A casa só subia
  cheia, e só enche com 100% de atendimento; a categoria conta como atendida a partir de 90%
  (`need_met_threshold`). Com o peixe em 95%, o painel ficava todo verde e nenhuma casa subia, para
  sempre: a população parava, a renda também, e a manutenção das cadeias já construídas comia o
  saldo. Agora a casa sobe ao chegar aos moradores que o atendimento dela permite. A especificação só
  pede "categorias básicas cobertas e materiais"; a casa cheia era regra nossa.
- Com a correção: pior saldo **+1,5 mil** (antes −7,6 mil), renda 1,4× a manutenção aos 120 min (antes
  1,1×), artesãos aos 90 min (antes 75 min, mas parados até os 150). Os números da especificação e
  os nossos ficaram como estavam: a redução da manutenção da escola e do armazém, testada antes da
  correção, deixou de ser necessária.
- **O robô também esperava parado** quando faltava operário ou artesão para a próxima fábrica: só
  construía casa nova faltando camponês. Agora constrói para qualquer classe (a casa nasce camponesa
  e sobe).
- **Depois dos 135 min o limite é do robô**: as quatro ruas de casas (488 casas) enchem e a fila de
  construção acaba; o caixa só acumula. Engenheiros e investidores continuam fora do alcance dele;
  a quinta classe segue provada pela partida roteirizada (`tests/sim/test_phase8_criteria.gd`).
- **Roupa de lã continua o gargalo de escala** (uma tecelagem para 500 moradores, número da
  especificação), mas não trava mais a subida: a casa sobe com a roupa a 95%.
