# Plano da Fase 288 — Papoulas soltas

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_285_289.md`. Os canteiros de papoulas (Fase 156) saíam
como pontos vermelhos em linhas regulares: cada célula do canteiro levava a mesma touceira redonda quase no meio dela, do mesmo
tamanho.

## O que entrou

- **`ScatterView`**:
  - o canteiro de cada célula anda mais do meio (`POPPY_SPREAD`, 0,75 do desvio sorteado; era 0,3);
  - fica menor perto da borda do canteiro: de `POPPY_EDGE_SCALE` (0,5) na borda a 1 no meio, pela força dele (`poppy_strength`,
    o mesmo ruído dos canteiros, de 0 no limite a 1);
  - no meio do canteiro ganha até `POPPY_EXTRAS` (3) touceiras pequenas a mais (`_poppy_extras`, de `POPPY_EXTRA_SCALE` 0,3 a
    0,55 do tamanho), em lugares e giros soltos dentro da célula.
- **As touceiras a mais têm sorteio próprio**, pelo hash aritmético da célula. O sorteio das outras peças da célula não muda,
  como manda a regra do recheio. O desvio e o tamanho do canteiro de antes só mudam de escala: o sorteio continua o mesmo.

## Como testar

- `tests/world/test_phase288_loose_poppies.gd`:
  - a força de 0 a 1, zero fora do canteiro, perto de 0 na borda e perto de 1 no meio;
  - os canteiros na célula deles, boa parte longe do meio, de vários tamanhos, com mais de uma touceira nas células do meio;
  - as outras peças seguem.
- `test_phase156_poppies.gd` (os canteiros na célula do canteiro, acima da areia) seguiu passando.
- Captura: `tools/capture_phase285.tscn -- <pasta>` (as papoulas em `04_papoulas.png`).
