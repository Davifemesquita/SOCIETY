# Plano da Fase 338 — Capim na beira

**Estado: feita em 07/11/2026**, a quarta do roteiro `docs/plano_fases_335_339.md` (estrada no jeito do Anno). Fora da vila, o Anno tem
capim alto e escuro junto da estrada; a nossa encostava no capim baixo.

## O plano

- **Arquivos**: `presentation/scatter_view.gd` (a peça nova), o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: mudar o sorteio das peças de antes; o capim entrar na vila ou na rua.
- **Como testar**: o teste novo (com uma estrada de campo posta na grade), o da Fase 167 e a captura.

## O que entrou

- **`ScatterView.Kind.VERGE_GRASS`**, no fim do enum, das `PLANTS` e da lista `NEAR_ROAD`: a touceira de capim alto da Fase 167 (a mesma
  malha), sem a exigência da mancha dela, com chance `VERGE_GRASS_CHANCE` (55%) e mais escura (`VERGE_GRASS_SHADE`, 0,62 a 0,82 no lugar
  de 0,82 a 1,12). Quase no meio da célula, para não entrar na rua.
- **Só fora da vila**: a lista `NEAR_ROAD` só vale na célula sem casa nem fábrica do lado (perto delas valem as listas da vila), e só nas
  temperadas.

## Medida

Uma peça a mais no recheio, só junto das estradas de campo: sem custo à parte (medido no fim do roteiro).

## Como testar

- `tests/world/test_phase338_verge_grass.gd`: a peça no fim do enum e da lista, entre as plantas e mais escura; numa estrada de terra
  posta na grade de cada ilha, o capim só junto dela e só nas temperadas.
- Captura: `tools/capture_phase330.tscn -- <pasta>` (em `F:\ferramentas\capturas\fase338\depois\`). A vila da captura quase não tem
  estrada de campo (as ruas encostam em casa, fábrica ou fazenda), e o capim da beira quase não aparece nela.
