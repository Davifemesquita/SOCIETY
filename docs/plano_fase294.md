# Plano da Fase 294 — Abetos na rocha

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_290_294.md`. As encostas íngremes do Society só tinham o
pinheiro-anão (Fase 207) e o cascalho (Fase 162). No Anno, os abetos sobem pela rocha.

## O que entrou

- **`ScatterView.Kind.CLIFF_SPRUCE`**:
  - no fim do enum e no fim das listas `OPEN`, `NEAR_FOREST` e `NEAR_SEA`, então o sorteio das peças de antes não muda;
  - entre as `SHADOWED` (faz sombra).
- **Onde**: só nas temperadas e nas células de desnível `CLIFF_SPRUCE_MIN_RELIEF_M` (2 m, mais íngremes que as do pinheiro-anão),
  com a chance `CLIFF_SPRUCE_CHANCE` (0,12).
- **Como**:
  - de pé, perto do meio da célula, com o pé enterrado 0,25 m como o pinheiro-anão;
  - de `CLIFF_SPRUCE_SCALE` (0,4) × 0,8 a 1,25 do abeto da Fase 275: de 2,8 a 4,5 m.
- **A malha** é o abeto de perto (variante 1), com o material dele: o vento das copas e as folhas recortadas da Fase 279.
  - A malha de longe, de três camadas, saía como um cipreste fino.
  - São poucos: 38 numa ilha de 120 células no teste.
- As pedrinhas nas saliências, previstas no roteiro como parte do recheio, já vinham do cascalho da Fase 162.

## Medida

GPU 12,6 ms (293: 12,5); um objeto e um draw call a mais no quadro com tudo visível. Neutra.

## Como testar

- `tests/world/test_phase294_cliff_spruce.gd`:
  - a peça no fim do enum e das três listas, com sombra;
  - os abetos só nas encostas íngremes das temperadas, de pé, no tamanho;
  - nenhum nas tropicais;
  - a malha do abeto de perto com o material das árvores.
- Captura: `tools/capture_phase290.tscn -- <pasta>` (o barranco em `03_` e a encosta em `06_`).
