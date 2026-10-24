# Balanceamento — partida do jogador-robô

Gerado por `tools/balance_report.tscn` em 2026-10-24T14:53:17. O robô (`tools/auto_player.gd`) joga 4 h numa ilha plana de
350×350 (a terra do arquipélago inteiro, no lugar das colônias),
dificuldade normal, pagando cada prédio, esperando material e desbloqueio, com carroças e armazéns;
corrige faltas pondo o produtor na frente da fila e pausa fábrica com o estoque cheio.

- Pior saldo: **-745** aos 116 min (limite para construir: -10000).
- Prédios no fim: 2081; casas: 1023.

| min | Camponeses | Operários | Artesãos | Engenheiros | Investidores | casas | saldo | renda/min | manutenção/min | próximo da fila | parado por |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | 219 | 249 | 0 | 0 | 0 | 41 | 50442 | 423 | 345 | sawmill | REASON_NO_MATERIALS |
| 30 | 704 | 590 | 0 | 0 | 0 | 107 | 29290 | 1228 | 1225 | lumberjack | REASON_NO_MATERIALS |
| 45 | 950 | 1745 | 0 | 0 | 0 | 212 | 20657 | 2911 | 1895 | brickworks | REASON_NO_MATERIALS |
| 60 | 1268 | 2560 | 108 | 0 | 0 | 269 | 5740 | 4521 | 3765 | furnace | REASON_NO_MATERIALS |
| 75 | 1465 | 1899 | 989 | 0 | 0 | 289 | 1859 | 5669 | 4795 | pig_farm | WORKFORCE |
| 90 | 1945 | 1879 | 1064 | 0 | 0 | 350 | 1739 | 6434 | 5095 | steel_beam_works | WORKFORCE |
| 105 | 1905 | 2459 | 1065 | 0 | 0 | 361 | 3274 | 7306 | 6325 | sewing_machine_factory | RESERVE |
| 120 | 2110 | 2450 | 926 | 343 | 0 | 406 | 1938 | 8870 | 6685 | lamp_factory | RESERVE |
| 135 | 2315 | 3282 | 2015 | 498 | 0 | 508 | 26418 | 12554 | 8632 | sewing_machine_factory | REASON_NO_MATERIALS |
| 150 | 2774 | 3930 | 2340 | 548 | 0 | 601 | 21560 | 15272 | 11060 | furnace | REASON_NO_MATERIALS |
| 165 | 3039 | 4830 | 2475 | 607 | 0 | 689 | 10925 | 16731 | 13970 |  |  |
| 180 | 3421 | 6159 | 2465 | 666 | 0 | 778 | 3612 | 19479 | 16770 |  |  |
| 195 | 3988 | 6928 | 1976 | 1233 | 0 | 883 | 6247 | 22898 | 17745 |  |  |
| 210 | 4504 | 8012 | 1577 | 1713 | 0 | 1007 | 51460 | 26485 | 20825 |  |  |
| 225 | 4744 | 8321 | 1595 | 1580 | 271 | 1023 | 103229 | 28882 | 22392 |  |  |
| 240 | 4772 | 8337 | 1607 | 1290 | 681 | 1023 | 156499 | 30300 | 24108 |  |  |

## Para onde vai a manutenção (moedas/min)

Prédios de produção pelo que fazem: bem que alguma classe consome, bem intermediário das cadeias ou material de
construção (custo de prédio ou de subir de classe); os serviços; armazéns, entreposto, píer e navios. "Ociosas" é a
parte da manutenção da produção que vai para fábricas abaixo de 50% de produtividade (já contada nas colunas).

| min | bens de consumo | intermediários | material | serviços | logística e navios | ociosas (<50%) | renda Camponeses | renda Operários | renda Artesãos | renda Engenheiros | renda Investidores |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | 95 | 70 | 30 | 60 | 90 | 45 | 132 | 291 | 0 | 0 | 0 |
| 30 | 255 | 360 | 90 | 340 | 180 | 60 | 423 | 805 | 0 | 0 | 0 |
| 45 | 500 | 605 | 150 | 400 | 240 | 60 | 563 | 2348 | 0 | 0 | 0 |
| 60 | 930 | 1075 | 430 | 910 | 420 | 545 | 742 | 3551 | 228 | 0 | 0 |
| 75 | 1460 | 1505 | 390 | 930 | 510 | 545 | 871 | 2659 | 2138 | 0 | 0 |
| 90 | 1450 | 1805 | 240 | 1000 | 600 | 1185 | 1157 | 2894 | 2384 | 0 | 0 |
| 105 | 1820 | 2275 | 490 | 1050 | 690 | 835 | 1130 | 3788 | 2388 | 0 | 0 |
| 120 | 2000 | 2170 | 670 | 1110 | 735 | 525 | 1250 | 3767 | 2443 | 1410 | 0 |
| 135 | 2770 | 2765 | 788 | 1470 | 840 | 1012 | 1324 | 4953 | 4540 | 1737 | 0 |
| 150 | 3790 | 3475 | 965 | 1840 | 990 | 1340 | 1587 | 5803 | 5297 | 2585 | 0 |
| 165 | 4730 | 4590 | 1250 | 2260 | 1140 | 1680 | 1709 | 6268 | 5619 | 3135 | 0 |
| 180 | 5800 | 5830 | 1160 | 2630 | 1350 | 1730 | 1944 | 8097 | 5710 | 3728 | 0 |
| 195 | 6410 | 5530 | 920 | 3340 | 1545 | 3070 | 2269 | 9167 | 4562 | 6901 | 0 |
| 210 | 6780 | 7050 | 1295 | 3990 | 1710 | 2160 | 2548 | 10685 | 3628 | 9623 | 0 |
| 225 | 7250 | 7810 | 792 | 4740 | 1800 | 3302 | 2720 | 12276 | 3691 | 8279 | 1917 |
| 240 | 7245 | 8160 | 1458 | 5340 | 1905 | 2148 | 2744 | 12310 | 3732 | 6811 | 4703 |

## Obras de cada intervalo

Prédios novos nos 15 min até a linha, pelo mesmo grupo da manutenção, e as moedas que custaram (quantos (moedas));
as casas à parte (a subida de classe paga material, não moedas).

| min | casas | bens de consumo | intermediários | material | serviços | logística e navios | total |
|---|---|---|---|---|---|---|---|
| 15 | 41 (2050) | 4 (850) | 13 (860) | 2 (400) | 3 (900) | 3 (1800) | 6860 |
| 30 | 66 (3300) | 4 (1300) | 30 (3450) | 4 (800) | 8 (5200) | 6 (2400) | 16450 |
| 45 | 105 (5250) | 4 (1800) | 18 (3360) | 4 (800) | 3 (900) | 4 (1600) | 13710 |
| 60 | 57 (2850) | 10 (3400) | 55 (6540) | 7 (4400) | 12 (9900) | 12 (4800) | 31890 |
| 75 | 20 (1000) | 10 (4900) | 45 (4920) | 1 (800) | 1 (300) | 6 (2400) | 14320 |
| 90 | 61 (3050) | 4 (2400) | 37 (4490) | 0 (0) | 2 (1300) | 6 (2400) | 13640 |
| 105 | 11 (550) | 2 (1200) | 45 (9420) | 1 (2000) | 1 (1000) | 6 (2400) | 16570 |
| 120 | 45 (2250) | 7 (10500) | 5 (330) | 1 (1900) | 3 (900) | 3 (1200) | 17080 |
| 135 | 102 (5100) | 7 (3200) | 29 (4740) | 5 (3400) | 9 (6900) | 7 (2800) | 26140 |
| 150 | 93 (4650) | 10 (22900) | 43 (8240) | 8 (8100) | 11 (6800) | 10 (4000) | 54690 |
| 165 | 88 (4400) | 15 (13500) | 43 (17030) | 0 (0) | 5 (14300) | 10 (4000) | 53230 |
| 180 | 89 (4450) | 21 (10850) | 58 (16690) | 2 (400) | 11 (6800) | 14 (5600) | 44790 |
| 195 | 105 (5250) | 12 (5750) | 90 (13500) | 1 (200) | 10 (22900) | 13 (5200) | 52800 |
| 210 | 124 (6200) | 9 (4300) | 69 (6950) | 0 (0) | 12 (18500) | 11 (4400) | 40350 |
| 225 | 16 (800) | 9 (4300) | 46 (6120) | 0 (0) | 5 (30000) | 6 (2400) | 43620 |
| 240 | 0 (0) | 4 (9200) | 38 (4290) | 2 (4000) | 4 (24000) | 7 (2800) | 44290 |

## Folga do meio da partida (24/10/2026, Fase 28)

Decisão do dono do produto depois do diagnóstico da Fase 27 ("pode fazer tudo"): as quatro alavancas, uma por vez,
medindo o robô a cada passo. Meta: o caixa não travar no meio da partida, engenheiros por volta dos 110 a 120 min,
investidores não antes de ~200 min e o pior saldo acima de −5.000.

| | Fase 27 | só os nossos números | e o imposto dos operários |
|---|---|---|---|
| pior saldo | −7.654 aos 178 min | −5.020 aos 135 min | **−745 aos 116 min** |
| fundição na frente esperando dinheiro | 60 a 105 min | 60 a 105 min | não espera |
| primeiros engenheiros | ~135 min | ~150 min | **~120 min** |
| primeiros investidores | ~225 min | ~210 min | ~225 min |
| renda ÷ manutenção, 60 a 105 min | 1,12 a 1,28 | 1,12 a 1,28 | 1,16 a 1,26 |
| renda aos 240 min | 31.834/min | 30.761/min | 30.300/min |

O que mudou:

1. **Fábrica ociosa à vista** (sem número): a dica do saldo soma as fábricas abaixo de 50% de produtividade e o que
   custam por minuto, e o painel da fábrica mostra a manutenção em laranja com o que ela pagaria pausada
   (`GameConfig.idle_productivity`, `Simulation.idle_upkeep`).
2. **Serviços nossos**: teatro 120 → 90 e universidade 200 → 150 moedas/min de manutenção.
3. **Custo de construção (nosso; a tabela da especificação só traz a manutenção)**: vidraria 2.000 → 1.500;
   janelaria, máquinas de costura e conservas 2.500 → 1.900; destilaria de rum 1.500 → 1.100; fundição 1.500 → 1.200.
4. **Imposto dos operários 1,2 → 1,4** (a especificação diz 1,2; decisão do dono do produto). É a classe que segura o
   meio da partida: os operários passam a pagar a cesta básica 2,33 vezes e a com luxo 1,71 (antes 1,99 e 1,47).

O passo 3 sozinho folgou o fim (o pior saldo foi de −7.654 a −5.020) mas não o meio: a fundição é o portão do aço e
vem antes das fábricas dos artesãos. Foi o imposto dos operários que tirou a trava: com ~950 moedas/min a mais de renda aos 75
min, a fundição sai entre 60 e 75 min e os engenheiros chegam 15 min antes que na Fase 27. A razão renda ÷ manutenção do meio da
partida ficou parecida, porque o caixa a mais vira obra mais cedo, e a cidade cresce em vez de esperar. Os 156 mil
moedas aos 240 min são do robô sem nada na fila; na Fase 27 eram 51 mil.

## O diagnóstico (24/10/2026, Fase 27, antes da Fase 28)

Os números desta seção são da partida da Fase 27, antes das mudanças acima.

As três tabelas acima saem do mesmo `tools/balance_report.tscn`; a planilha (`tools/godot.sh planilha`) traz, em
`classes.csv`, a manutenção da cadeia que abastece um morador e quantas vezes o imposto a paga (`BalanceMath`, com o
consumo dividido entre os bens da categoria, como a seção 4 manda).

| classe | imposto/morador | cadeia básica | imposto ÷ básica | cadeia com luxo | imposto ÷ com luxo |
|---|---|---|---|---|---|
| camponeses | 0,6 | 0,22 | 2,79 | 0,35 | 1,73 |
| operários | 1,2 (hoje 1,4) | 0,60 | 1,99 (hoje 2,33) | 0,82 | 1,47 (hoje 1,71) |
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

As alavancas que o diagnóstico apontou, da mais leve à mais forte (todas aplicadas na Fase 28):

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
