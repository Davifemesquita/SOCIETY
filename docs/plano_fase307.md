# Plano da Fase 307 — Sub-bosque

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_305_309.md`. No Anno há samambaias e arbustos debaixo
das árvores; no Society, o recheio pulava as células de mata.

## O que entrou

- **`ScatterView`**: `Kind.FOREST_FERN` (sete frondes recortadas, ~0,7 m) e `Kind.UNDERBRUSH` (duas massas achatadas, ~0,6 m), no
  fim do enum, entre as `PLANTS` (balançam) e fora das `SHADOWED` (são milhares). Ficam **fora das listas de regras**: as células de
  mata, que o laço pulava, ganham `_understory`, com um sorteio aritmético próprio (`FireflyView.cell_hash`): a samambaia em
  `UNDERSTORY_FERN_CHANCE` (40%) e o arbusto em `UNDERSTORY_BRUSH_CHANCE` (18%) das células, soltos pela célula. O recheio das
  outras células não muda.
- Só nas temperadas; as tropicais já têm a bananeira e a samambaia na beira (Fase 60).
- O roteiro pedia só debaixo das árvores desenhadas; ficou em toda célula de mata (as vãs da Fase 276 também), porque o sorteio das
  árvores desenhadas é um `hash()` de Array por célula, caro no laço, e a samambaia no vão entre as árvores fica bem.

## Medida

71,6 FPS, GPU 12,9 ms (306: 12,8). Neutra.

## Como testar

- `tests/world/test_phase307_understory.gd`: o fim do enum e fora das regras; samambaias e arbustos só nas células de mata das
  temperadas; nada nas tropicais.
- Captura do ciclo: `tools/capture_phase305.tscn -- <pasta>`; os recortes entre os troncos estão em
  `F:\ferramentas\capturas\fase307\sub_bosque_antes.png` e `sub_bosque_depois.png`.
