# Plano da Fase 279 — Folhas recortadas

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_275_279.md`. De perto, as copas eram bolas lisas, de
contorno redondo e cor chapada. No Anno, a copa se lê como cachos de folhas, com o contorno recortado.

## O que entrou

- **O corpo da folhagem foi para `shaders/foliage.gdshaderinc`.**
  - O `foliage.gdshader` de sempre só o inclui; continuam nele as plantações, o capim, as árvores de longe e o coqueiro.
  - O novo `shaders/tree_foliage.gdshader` define `LEAF_DETAIL` e inclui o mesmo corpo.
  - Ficou num shader à parte porque o `discard` tira a profundidade antecipada. Só as copas de perto pagam por ele.
- **Com `LEAF_DETAIL`**: os cachos de folhas em células sorteadas no espaço do modelo, de `leaf_size` (0,45 m).
  - A busca é a de oito células em volta (`leaf_cells`, sorteio inteiro, sem `sin`).
  - O meio do cacho fica mais claro (`leaf_light`) e o vão, mais escuro (`leaf_dark`).
  - A normal estufa para fora do meio de cada cacho (`leaf_bulge`), e cada um ganha o lado da luz e o da sombra.
  - Na borda da copa, onde a superfície fica de lado para a câmera, os vãos são recortados (`leaf_cut`).
  - Tudo some de `leaf_far_m` × 0,6 a `leaf_far_m` (90 m) da câmera. As árvores de longe (o nível de detalhe a partir de
    200 m) ficam iguais.
- **`TreeModel._material`**: as árvores de perto (carvalho, faia, pinheiro, abeto, bétula e a folhosa tropical) ficam no
  `TREE_SHADER`; as de longe e o coqueiro, no `FOLIAGE_SHADER`. O coqueiro tem folhas finas, e o recorte de lado as desfiaria.
- **A primeira versão**, de cachos pequenos e contrastados sem o estufado, saía como bolinhas claras sobre fundo escuro.

## Medida

A GPU subiu 0,3 a 0,4 ms em duas rodadas (12,2 e 12,1 ms, contra 11,8 na Fase 278), abaixo do limite de 0,5 ms do roteiro.
Por isso o recorte vale em todos os níveis gráficos. O ciclo da mata fecha com a GPU onde estava antes dele (12,0 ms na Fase
274), porque a Fase 276 tirou 0,5 ms.

## Como testar

- `tests/presentation/test_phase279_leaves.gd`:
  - as árvores de perto no shader das folhas, as de longe e o coqueiro no de sempre;
  - o shader das folhas compilando com os uniformes dele (com tela) e o de sempre sem eles;
  - o `discard` só dentro do bloco `LEAF_DETAIL`.
- `test_tree_model.gd` e `test_phase275_spruce.gd` esperam o `TREE_SHADER` nas árvores de perto.
- `test_phase256_canopy.gd` lê o corpo no `.gdshaderinc` e compara a cor das folhas do alto e de baixo pela média: com a copa
  menor da Fase 276, o vértice mais baixo pode ser de um tufo.
- Captura: `tools/capture_phase275.tscn -- <pasta>` (as vistas do ciclo da mata).
