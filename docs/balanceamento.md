# Balanceamento — partida do jogador-robô

Gerado por `tools/balance_report.tscn` em 2026-10-24T13:43:36. O robô (`tools/auto_player.gd`) joga 4 h numa ilha plana de
350×350 (a terra do arquipélago inteiro, no lugar das colônias),
dificuldade normal, pagando cada prédio, esperando material e desbloqueio, com carroças e armazéns;
corrige faltas pondo o produtor na frente da fila e pausa fábrica com o estoque cheio.

- Pior saldo: **-7654** aos 178 min (limite para construir: -10000).
- Prédios no fim: 2128; casas: 1071.

| min | Camponeses | Operários | Artesãos | Engenheiros | Investidores | casas | saldo | renda/min | manutenção/min | próximo da fila | parado por |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | 219 | 249 | 0 | 0 | 0 | 41 | 50347 | 382 | 345 | sawmill | REASON_NO_MATERIALS |
| 30 | 704 | 590 | 0 | 0 | 0 | 107 | 28312 | 1113 | 1225 | lumberjack | REASON_NO_MATERIALS |
| 45 | 950 | 1745 | 0 | 0 | 0 | 212 | 16428 | 2575 | 1895 | brickworks | REASON_NO_MATERIALS |
| 60 | 1217 | 2478 | 127 | 0 | 0 | 269 | 94 | 3879 | 3450 | furnace | RESERVE |
| 75 | 1364 | 2259 | 548 | 0 | 0 | 276 | 2451 | 4723 | 3915 | furnace | RESERVE |
| 90 | 1564 | 1799 | 1158 | 0 | 0 | 296 | 2705 | 5901 | 4605 | furnace | RESERVE |
| 105 | 2105 | 1725 | 1377 | 0 | 0 | 365 | 1608 | 6614 | 5335 | furnace | WORKFORCE |
| 120 | 2004 | 2115 | 1462 | 0 | 0 | 367 | 2486 | 7278 | 5850 | window_works | RESERVE |
| 135 | 2094 | 2654 | 1167 | 436 | 0 | 407 | 1554 | 9073 | 6485 | furnace | RESERVE |
| 150 | 2181 | 2873 | 2373 | 407 | 0 | 480 | 9550 | 11513 | 9045 | weavery | WORKFORCE |
| 165 | 2911 | 3589 | 2485 | 475 | 0 | 626 | 2465 | 13855 | 11645 | rendering_works | WORKFORCE |
| 180 | 3159 | 4778 | 2582 | 493 | 0 | 682 | -4102 | 15592 | 13340 | pig_farm | WORKFORCE |
| 195 | 3770 | 5806 | 1809 | 1442 | 0 | 793 | 243 | 21655 | 16125 |  |  |
| 210 | 4361 | 5974 | 1318 | 2112 | 0 | 881 | 13348 | 24159 | 18580 | coal_mine | WORKFORCE |
| 225 | 4393 | 7268 | 1732 | 2501 | 92 | 963 | 33653 | 28514 | 21410 |  |  |
| 240 | 5291 | 7284 | 1331 | 3042 | 92 | 1071 | 51242 | 31834 | 24475 | brickworks | WORKFORCE |

## Para onde vai a manutenção (moedas/min)

Prédios de produção pelo que fazem: bem que alguma classe consome, bem intermediário das cadeias ou material de
construção (custo de prédio ou de subir de classe); os serviços; armazéns, entreposto, píer e navios. "Ociosas" é a
parte da manutenção da produção que vai para fábricas abaixo de 50% de produtividade (já contada nas colunas).

| min | bens de consumo | intermediários | material | serviços | logística e navios | ociosas (<50%) | renda Camponeses | renda Operários | renda Artesãos | renda Engenheiros | renda Investidores |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | 95 | 70 | 30 | 60 | 90 | 45 | 132 | 250 | 0 | 0 | 0 |
| 30 | 255 | 360 | 90 | 340 | 180 | 60 | 423 | 690 | 0 | 0 | 0 |
| 45 | 500 | 605 | 150 | 400 | 240 | 60 | 563 | 2013 | 0 | 0 | 0 |
| 60 | 960 | 1000 | 190 | 910 | 390 | 350 | 700 | 2916 | 263 | 0 | 0 |
| 75 | 1260 | 1085 | 190 | 930 | 450 | 565 | 812 | 2710 | 1200 | 0 | 0 |
| 90 | 1290 | 1405 | 390 | 980 | 540 | 605 | 929 | 2376 | 2596 | 0 | 0 |
| 105 | 1610 | 1785 | 290 | 1020 | 630 | 775 | 1251 | 2277 | 3087 | 0 | 0 |
| 120 | 1860 | 1655 | 590 | 1070 | 675 | 885 | 1188 | 2777 | 3313 | 0 | 0 |
| 135 | 2180 | 1910 | 480 | 1210 | 705 | 1230 | 1236 | 3466 | 2764 | 1607 | 0 |
| 150 | 3000 | 2780 | 985 | 1470 | 810 | 1215 | 1218 | 3405 | 5437 | 1453 | 0 |
| 165 | 3850 | 3540 | 1290 | 1960 | 1005 | 1290 | 1579 | 4469 | 5641 | 2166 | 0 |
| 180 | 4660 | 4695 | 795 | 1960 | 1230 | 1510 | 1745 | 5427 | 5929 | 2491 | 0 |
| 195 | 5380 | 5470 | 1215 | 2650 | 1410 | 1090 | 2119 | 7328 | 4147 | 8061 | 0 |
| 210 | 5490 | 6680 | 1315 | 3520 | 1575 | 1380 | 2469 | 7706 | 3025 | 10959 | 0 |
| 225 | 6220 | 7280 | 1495 | 4690 | 1725 | 1620 | 2436 | 8530 | 3979 | 12942 | 628 |
| 240 | 6770 | 7940 | 1795 | 6080 | 1890 | 2000 | 3002 | 9416 | 3037 | 15756 | 622 |

## Obras de cada intervalo

Prédios novos nos 15 min até a linha, pelo mesmo grupo da manutenção, e as moedas que custaram (quantos (moedas));
as casas à parte (a subida de classe paga material, não moedas).

| min | casas | bens de consumo | intermediários | material | serviços | logística e navios | total |
|---|---|---|---|---|---|---|---|
| 15 | 41 (2050) | 4 (850) | 13 (860) | 2 (400) | 3 (900) | 3 (1800) | 6860 |
| 30 | 66 (3300) | 4 (1300) | 30 (3450) | 4 (800) | 8 (5200) | 6 (2400) | 16450 |
| 45 | 105 (5250) | 4 (1800) | 18 (3360) | 4 (800) | 3 (900) | 4 (1600) | 13710 |
| 60 | 57 (2850) | 11 (3550) | 50 (5030) | 4 (2000) | 12 (9900) | 10 (4000) | 27330 |
| 75 | 7 (350) | 5 (3000) | 29 (1860) | 0 (0) | 1 (300) | 4 (1600) | 7110 |
| 90 | 20 (1000) | 3 (1800) | 37 (3590) | 4 (3200) | 1 (1000) | 6 (2400) | 12990 |
| 105 | 69 (3450) | 4 (1300) | 49 (6330) | 2 (1600) | 2 (600) | 6 (2400) | 15680 |
| 120 | 2 (100) | 3 (5400) | 6 (8400) | 1 (2000) | 1 (1000) | 3 (1200) | 18100 |
| 135 | 40 (2000) | 6 (11000) | 0 (0) | 1 (2500) | 4 (2600) | 2 (800) | 18900 |
| 150 | 73 (3650) | 11 (7700) | 22 (7780) | 5 (3400) | 7 (4900) | 7 (2800) | 30230 |
| 165 | 146 (7300) | 14 (11300) | 69 (9650) | 4 (6700) | 14 (9100) | 13 (5200) | 49250 |
| 180 | 56 (2800) | 13 (13050) | 75 (16920) | 0 (0) | 0 (0) | 15 (6000) | 38770 |
| 195 | 111 (5550) | 11 (12600) | 68 (11380) | 1 (200) | 15 (15100) | 12 (4800) | 49630 |
| 210 | 88 (4400) | 2 (1200) | 76 (24870) | 2 (1600) | 6 (25300) | 11 (4400) | 61770 |
| 225 | 82 (4100) | 13 (9050) | 59 (10310) | 5 (2800) | 15 (30800) | 10 (4000) | 61060 |
| 240 | 108 (5400) | 10 (21950) | 70 (7850) | 3 (6000) | 11 (39600) | 11 (4400) | 85200 |

## O que a partida mostra (24/10/2026, Fase 27)

As três tabelas acima saem do mesmo `tools/balance_report.tscn`; a planilha (`tools/godot.sh planilha`) traz, em
`classes.csv`, a manutenção da cadeia que abastece um morador e quantas vezes o imposto a paga (`BalanceMath`, com o
consumo dividido entre os bens da categoria, como a seção 4 manda).

| classe | imposto/morador | cadeia básica | imposto ÷ básica | cadeia com luxo | imposto ÷ com luxo |
|---|---|---|---|---|---|
| camponeses | 0,6 | 0,22 | 2,79 | 0,35 | 1,73 |
| operários | 1,2 | 0,60 | 1,99 | 0,82 | 1,47 |
| artesãos | 2,4 | 1,28 | 1,87 | 1,48 | 1,62 |
| engenheiros | 4,0 | 1,29 | 3,10 | 1,82 | 2,20 |
| investidores | 7,0 | 2,08 | 3,36 | 2,92 | 2,39 |

- **Os números estão sãos.** Toda classe paga a cadeia da própria cesta com folga, e na partida a renda de cada classe
  bate com o imposto da tabela (aos 120 min: camponeses 1.188, operários 2.777, artesãos 3.313 moedas/min) e a
  manutenção das cadeias de consumo e intermediárias (3.515) fica abaixo do que a conta prevê para aquela população
  (~4.600): não há fábrica sobrando.
- **O meio da partida é lento, não quebrado.** Dos 60 aos 135 min (operários e artesãos) a renda fica 1,12 a 1,4 vez
  a manutenção. O que come a margem: os serviços (~1.000/min: escola, igreja, mercados, taverna, teatro), a logística
  (~400 a 700), o material de construção (~200 a 600) e as fábricas abaixo de 50% de produtividade (até 1.230/min, um
  quinto da manutenção, à espera de entrada ou de gente). O dinheiro não some: a tabela das obras mostra o robô
  gastando de 7 a 19 mil moedas a cada 15 min, quase tudo o que entra, boa parte em matéria-prima e fazendas
  contra falta (para os artesãos que crescem).
- **A fundição é o portão.** Ela faz o aço das vigas (material dos engenheiros), dos enlatados e das máquinas de
  costura, e espera dinheiro na frente da fila de 60 a 105 min: com o caixa em ~2.500 e a obra custando 1.500 mais a
  reserva do robô, as obras urgentes chegam antes. O robô agora junta para a obra da frente quando ela espera só
  dinheiro há 90 s (`AutoPlayer.SAVE_FRONT_AFTER_S`; as urgentes ainda passam): os engenheiros chegam aos 135 min
  (antes 150), o pior saldo fica em −7.654 (antes −8.326) e a cidade termina com 1.071 casas (antes 998) e 31.834
  moedas/min (antes 29.684); em troca, aos 240 min há 92 investidores (antes 734) e 3.042 engenheiros (antes 1.621).
- **Nenhum número dos dados mudou.** O imposto das cinco classes, a manutenção e as cadeias dos operários são da
  especificação (seção 4 e seção 5); as das classes altas são nossas e já pagam com folga.

Se o meio da partida tiver de ser mais folgado, é decisão de produto. As alavancas, da mais leve à mais forte:

1. **Dica na interface**: a fábrica parada ainda paga a manutenção inteira (pausada, metade, seção 5). Um aviso de
   "fábrica ociosa custando X/min" ajuda o jogador a pausar ou demolir; não mexe em número.
2. **Serviços nossos mais baratos**: teatro (120/min) e universidade (200/min) são nossos; o raio deles (30 células)
   também.
3. **Material de construção mais barato para os artesãos**: a fundição e as vigas são da especificação, mas o custo
   das fábricas dos artesãos (2.000 a 2.500 moedas) é nosso.
4. **Imposto ou manutenção da especificação**: só com a decisão do dono do produto.

## Beleza (Fase 16)

A beleza vai de 0 a 1 por casa e soma até `happiness_per_beauty` (12) de felicidade; o imposto anda de 0,5× a 1,5× com
a felicidade, então beleza cheia vale +12% do imposto da casa. Um quarteirão de dez casas de camponeses (6 moedas/min
cada) cercado de árvores plantadas até a beleza 1 custa umas 240 moedas e devolve ~7 moedas/min: paga-se em ~35 min.
Nos artesãos (2,4/morador) o retorno é quatro vezes mais rápido, mas a estátua e o coreto custam caro e pedem tijolo e
viga. É um ganho de capricho, abaixo do luxo (25 de felicidade). O jogador-robô não constrói decoração: a linha do
tempo do balanceamento não muda.
