# Fase 386 — Invariantes

**09/11/2026.** Primeira do roteiro `docs/plano_fases_386_405.md` (de bonito a jogável), bloco A (rede de segurança).

## O quê

`WorldInvariants.check(world, data)` (`sim/world_invariants.gd`) lê o mundo e devolve a lista do que está errado. Quando está
tudo certo, a lista vem vazia. Cada linha é um texto curto para o relatório. A conferência só lê: não mexe na partida nem no save.

O que ela confere:

- o dinheiro é número; o tick não é negativo; há uma economia por ilha;
- o estoque de cada ilha é número e não é negativo;
- cada prédio:
  - o tipo existe, a ilha existe e o lote cabe na ilha;
  - na casa: a classe existe, moradores e imposto são números não negativos e a felicidade fica entre 0 e 100;
  - as entradas e a saída são números não negativos, o progresso fica entre 0 e 1 e a produtividade é número;
- a ocupação bate com os prédios nos dois sentidos: nenhuma célula tem dois prédios, e toda célula marcada é de um prédio que a
  cobre;
- cada carroça:
  - a casa dela existe;
  - a carga é número não negativo;
  - a posição fica dentro do caminho, as células do caminho ficam dentro da ilha e o armazém do destino existe;
- cada navio:
  - o tipo existe e a rota dele existe;
  - os porões batem (bens e toneladas), as toneladas são números não negativos e casco e posição são números;
- as paradas das rotas ficam em ilhas que existem;
- nenhum navio está em expedição e no mapa ao mesmo tempo;
- especialista, fogo, doença e encomenda de estaleiro apontam para prédios que existem (a encomenda, para um estaleiro);
- nenhuma rival fica numa ilha que não existe ou que tem entreposto do jogador.

Fica de fora o estoque acima da capacidade. Demolir o entreposto maior baixa a capacidade, e o que já estava guardado fica: o jogo
não joga carga fora.

O teste do critério das 3 horas (`tests/sim/test_phase10_criteria.gd`) passa a conferir os invariantes a cada meia hora. As Fases
387 (o robô no jogo de verdade) e 388 (o embaralhador de comandos) vão usá-la a cada passo.

"Carroça e navio presos além do limite" não cabe numa leitura de um tick só: passa para a Fase 387, que acompanha o mundo ao longo
do tempo.

## Como testar

- `tests/sim/test_phase386_invariants.gd`: o mundo montado e 200 ticks de partida passam, e o arquipélago da semente 1840 também.
  Cada erro plantado é pego: dinheiro NaN, estoque negativo, ocupação fora do lugar, fogo e armazém que não existem, moradores
  infinitos.
- A pasta `tests/sim` inteira.

## Estado

- Feita em 09/11/2026.
