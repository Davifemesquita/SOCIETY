# Balanceamento — partida do jogador-robô

Gerado por `tools/balance_report.tscn` em 2026-10-15T16:25:27. O robô (`tools/auto_player.gd`) joga 4 h numa ilha plana de
350×350 (a terra do arquipélago inteiro, no lugar das colônias),
dificuldade normal, pagando cada prédio, esperando material e desbloqueio, com carroças e armazéns;
corrige faltas pondo o produtor na frente da fila e pausa fábrica com o estoque cheio.

- Pior saldo: **-8326** aos 181 min (limite para construir: -10000).
- Prédios no fim: 2051; casas: 998.

| min | Camponeses | Operários | Artesãos | Engenheiros | Investidores | casas | saldo | renda/min | manutenção/min | próximo da fila | parado por |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | 219 | 249 | 0 | 0 | 0 | 41 | 50347 | 382 | 345 | sawmill | REASON_NO_MATERIALS |
| 30 | 704 | 590 | 0 | 0 | 0 | 107 | 28312 | 1113 | 1225 | lumberjack | REASON_NO_MATERIALS |
| 45 | 950 | 1745 | 0 | 0 | 0 | 212 | 16428 | 2575 | 1895 | brickworks | REASON_NO_MATERIALS |
| 60 | 1217 | 2478 | 127 | 0 | 0 | 269 | 94 | 3879 | 3450 | furnace | RESERVE |
| 75 | 1364 | 2259 | 548 | 0 | 0 | 276 | 2451 | 4723 | 3915 | furnace | RESERVE |
| 90 | 1564 | 1799 | 1158 | 0 | 0 | 296 | 2705 | 5901 | 4605 | furnace | RESERVE |
| 105 | 2105 | 1725 | 1377 | 0 | 0 | 365 | 1608 | 6614 | 5335 | furnace | WORKFORCE |
| 120 | 1972 | 2096 | 1362 | 0 | 0 | 367 | 2685 | 6937 | 5690 | cannery | RESERVE |
| 135 | 2092 | 2661 | 1634 | 0 | 0 | 414 | 1959 | 8421 | 7260 | cannery | RESERVE |
| 150 | 2312 | 3410 | 2057 | 696 | 0 | 519 | 20050 | 12601 | 8318 | sewing_machine_factory | REASON_NO_MATERIALS |
| 165 | 2956 | 3506 | 2361 | 737 | 0 | 615 | 19703 | 14791 | 10820 | champagne_cellar | REASON_NO_MATERIALS |
| 180 | 3321 | 4680 | 2364 | 729 | 0 | 699 | -6527 | 16144 | 14310 |  |  |
| 195 | 3834 | 5175 | 2023 | 1334 | 0 | 782 | 735 | 19665 | 16190 |  |  |
| 210 | 4325 | 6631 | 1433 | 2054 | 0 | 914 | 35495 | 23980 | 17975 |  |  |
| 225 | 4803 | 7499 | 1435 | 2040 | 84 | 998 | 25200 | 26066 | 21440 | lamp_factory | REASON_NO_MATERIALS |
| 240 | 4926 | 7579 | 1469 | 1621 | 734 | 998 | 43187 | 29684 | 23055 |  |  |
## O que a partida mostra (15/10/2026, robô ampliado)

- **As cinco classes em 4 horas**: operários aos ~15 min, artesãos aos ~60, engenheiros aos ~150 e
  investidores aos ~225, com 16 mil moradores no fim. A renda fica 1,2× a 1,4× a manutenção na maior
  parte da partida; o aperto é a entrada das fábricas dos engenheiros (lâmpada, relógio, champanhe,
  vidro), perto de −8 mil aos 180 min, com o limite em −10 mil. Nenhum número dos dados mudou.
- **O que mudou no robô** para medir as classes altas:
  - ilha plana de **350×350**, a terra do arquipélago inteiro (ele não coloniza): na de 250 as
    fazendas acabavam antes dos artesãos terem sabão (a criação de porcos é a cadeia que mais pede
    terra);
  - mais ruas de casas, de fazendas e uma de produção no sul;
  - a fila termina com as fábricas dos engenheiros e dos investidores;
  - **várias faltas por rodada** (até 3 bens, cada um com a sua pausa) e **até 3 obras por rodada**, a
    primeira que já dá para fazer entre as 8 da frente: uma fábrica esperando gente de uma classe não
    trava mais a de outra;
  - **freios de jogador**: o mesmo produtor não é pedido de novo antes de 2 min da última obra dele (a
    fábrica nova leva uns ciclos para aparecer no estoque), e no vermelho com a renda abaixo da
    manutenção não entra fábrica nova, só casa.
- Sem os freios, o robô ampliado erguia cinco saboarias em dois minutos e afundava a −50 mil: o ritmo
  de construção, não os números, decide se o meio da partida aperta.
