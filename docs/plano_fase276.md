# Plano da Fase 276 — Copas na medida

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_275_279.md`. A mata era um tapete contínuo de bolhas
facetadas, sem nenhum vão:

- o carvalho tinha copa de ~7,8 m de largura, a faia de ~5,8 m e o pinheiro de ~5 m;
- a `TreeView` desenhava até duas árvores por célula de 2 m.

No Anno, cada árvore se lê, com o capim e a sombra entre elas.

## O que entrou

- **Copas mais estreitas, da mesma altura** (`TreeModel`):
  - carvalho de 4,9 m de largura e 7,1 de altura (galhos mais curtos, massas menores, a forquilha a 2,8 m);
  - faia de 3,7 por 8,7 m;
  - pinheiro de ~4,2 por 10,6 m, com as massas menores e mais juntas do tronco.
- **Uma árvore por célula na mata temperada, e só em parte das células** (`TreeView`):
  - no máximo `TEMPERATE_PER_CELL` (1) por célula, desenhada em parte delas (`draws_tree`): `DRAWN_SHARE_EDGE` (50%) na
    beira, onde a célula tem uma árvore só; `DRAWN_SHARE` (65%) nas de duas; `DRAWN_SHARE_DEEP` (80%) no miolo;
  - o miolo fecha mais que a beira;
  - as ilhas tropicais seguem com até `DRAWN_PER_CELL` (2);
  - a simulação continua contando todas as árvores (o lenhador e a regra da mata não mudam).
- **Mais variação de tamanho**: `tree_scale` vai de `SCALE_MIN` (0,65) a 1,25 (era de 0,75 a 1,25).
- **Os sorteios das árvores desenhadas numa célula saem de `TreeView.drawn_seeds`**, que também dá os tocos da clareira do
  lenhador (`StumpView.stump_places`, agora com a ilha tropical ou não). Toco só onde havia árvore desenhada.

## Como testar

- `tests/world/test_phase276_crowns.gd`:
  - as copas mais estreitas e da mesma altura;
  - nas temperadas, no máximo uma árvore por célula e de 50 a 80% das células de mata; nas tropicais, as de antes;
  - o tamanho de 0,65 a 1,25;
  - a vista desenhando exatamente o que a regra diz.
- `test_phase140_clearing.gd` e `test_phase148_lumber_yard.gd` contam os tocos pelo `drawn_seeds`.
- `test_tree_model.gd` confere o carvalho mais largo que a faia: ele deixou de ser mais largo que alto.
- Captura: `tools/capture_phase275.tscn -- <pasta>` (as vistas do ciclo da mata).
