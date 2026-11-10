# Fase 387 — O robô no jogo de verdade

**10/11/2026.** Segunda do roteiro `docs/plano_fases_386_405.md` (de bonito a jogável), bloco A (rede de segurança).

## O quê

`TerrainAutoPlayer` (`tools/terrain_auto_player.gd`) é o jogador-robô da Fase 10 jogando o jogo novo do menu. Ele joga
a ilha principal do arquipélago v4 da semente, com eventos, rivais e riscos ligados. As decisões são as do `AutoPlayer`:
a fila de obras, as faltas, a mão de obra e as travas de subida. Muda só o lugar de cada obra:

- **Lote:** em anéis em volta do entreposto, ou do último mercado para as casas. O lote tem de caber pelo terreno, os
  módulos da fazenda têm de caber no raio, e o lenhador precisa de três vezes o mínimo de árvores no raio.
- **Estrada até a rede:** pelo mapa de distâncias da rede inteira, uma busca em largura saindo de todas as estradas
  pelas células onde a estrada cabe. Se o caminho passa pelo próprio lote, uma busca só daquele lote desvia dele.
- **Armazém:** o prédio que fica sem armazém ao alcance ganha um num lote cuja frente encosta numa estrada a até 30
  células dele **pela rede**. Se continuar sem, tenta de novo depois de 2 minutos.

Guarda o que um jogador sentiria:

- o que não coube;
- o que ficou preso mais de 3 minutos (carroça bloqueada, navio com rota parado, prédio sem estrada, sem armazém ou sem
  árvore), marcando o que ainda está preso no fim;
- os invariantes da Fase 386 quebrados, conferidos a cada rodada;
- os erros do log.

`tools/real_game_report.tscn` joga 2 horas em cada semente (1840, 7 e 2024) e grava `docs/jogo_real.md`.

## O que a partida mostrou

1. **O terreno não ilha a vila.** Nas sementes 1840, 7, 2024, 99 e 12345, quase toda a terra onde cabe estrada é um
   bloco só (18 a 25 mil células), e o entreposto fica nele. Os blocos soltos têm no máximo 50 células.
2. **O relevo pede estradas longas.** A estrada contorna os barrancos. Com a ligação limitada a 70 células, nenhum dos
   300 lotes de tecelagem conferidos na semente 1840 chegava à rede. Isso não muda o jogo, mas o jogador vai sentir: o
   lote mais perto em linha reta quase nunca é o mais perto pela estrada. Entra na Fase 393 (litoral de trabalho) e na
   399 (causa em cadeia).
3. **O alcance do armazém conta pela estrada.** O armazém posto ao lado de um prédio, do outro lado de um barranco,
   fica a mais de 40 células pela estrada e não serve. O aviso "sem acesso a armazém" não diz isso ao jogador: vai para
   a Fase 397 (avisos que faltam) e a 399.
4. **Trava do sabão (do robô, não do jogo).** O sabão é necessidade básica dos operários, mas a cadeia dele (fábrica de
   sebo e de sabão) só libera com 80 operários. O robô só erguia casa nova com o básico atendido e travava a subida das
   casas dos camponeses pela mão de obra, então parava em 40 a 54 operários (sementes 1840 e 2024). O robô do terreno
   agora pula a necessidade cuja cadeia ainda não liberou. Um jogador ergueria mais casas, mas a Fase 392 (subida
   explicada) precisa dizer que a necessidade ainda não tem como ser atendida.
5. **Lenhador sem mata.** A regra aceita o lenhador em qualquer chão, e ele fica parado sem árvore no raio. O jogador
   pode cair nisso também. Vai para a Fase 397: avisar já na prévia da obra.
6. **Dívida.** Em duas das três sementes o robô termina no vermelho (−12.535 na 1840 e −22.006 na 7), sem nenhum aviso
   do jogo. O que fica preso no fim são quase só prédios sem armazém que o robô não pode pagar. Vai para a Fase 394.
7. **Nenhum invariante quebrado e nenhum erro no log** nas três sementes em 2 horas, com eventos, rivais e riscos
   ligados.

Antes dos consertos do robô, as sementes paravam em 86 a 421 camponeses. Agora, às 2 horas:

| Semente | Camponeses | Operários | Artesãos | Dinheiro |
|---|---|---|---|---|
| 1840 | 1.100 | 2.221 | 151 | −12.535 |
| 7 | 908 | 1.541 | 146 | −22.006 |
| 2024 | 1.205 | 1.197 | 868 | 1.824 |

## Como testar

- `tests/sim/test_phase387_terrain_player.gd`:
  - na semente 1840, 30 minutos passam dos 80 operários, com lenhador e tábuas e sem invariante quebrado;
  - o mapa de distâncias alcança mais de 70 células.
- `godot --headless --path . res://tools/real_game_report.tscn -- docs/jogo_real.md [minutos] [sementes]` (~2 min por
  semente em 2 horas de jogo).

## Estado

- Feita em 10/11/2026.
