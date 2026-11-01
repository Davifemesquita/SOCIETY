# Plano da Fase 230 — Sinal no trilho

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_230_234.md` (sinal, cormorão e castanha, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`RailSignalView.ends`, `place_of`): em cada ponta de linha do trilho da Fase 70 — a célula de trilho com um só vizinho
  de trilho pelos lados (a chegada ao poço e à usina), achada pelo `find` do array —, `ASIDE_M` à direita de quem chega e `BACK_M`
  antes da ponta, no chão; o +z do sinal para fora da linha e o −x para quem chega (base de mão direita).
- **O sinal** (`signal_mesh`, `glass_mesh`): o poste de madeira com o chapéu de ferro, a escada de ferro do lado de quem chega, o
  braço vermelho com a faixa branca nas duas faces, erguido a `ARM_TILT` (via livre), para fora da linha, o contrapeso e a armação
  da lanterna; o vidro aceso à noite no material dos lampiões da rua (`shaders/night_glow.gdshader`). Dois MultiMesh.

## Como testar

- `tests/world/test_phase230_rail_signals.gd`: uma linha com curva só tem as duas pontas, cada uma com o lado para onde a linha
  segue; o sinal fica na célula da ponta, ao lado da linha, de mão direita, virado para fora; a vista desenha um por ponta e o
  poste fica de pé.
- Captura: `tools/capture_phase230.tscn` (o poço e a usina a petróleo ligados pelo trilho na ilha plana; `sinal_de_perto.png`,
  `sinal_e_linha.png`, `sinal_de_noite.png`).
