# Plano da Fase 318 — Espuma nas pedras do rio

**Estado: feita em 04/11/2026**, a quarta do roteiro `docs/plano_fases_315_319.md` (garganta do rio). No Anno, a água faz espuma
branca em volta das pedras do rio. No Society, o anel da Fase 293 sumia no rio: ele só vale longe da linha d'água (a mais de
`shore_line_m`, 3 m), e num rio estreito tudo fica perto dela. Os matacões da Fase 122 e os blocos da Fase 317 ficavam na água
parada.

## O plano

- **Arquivos**: `shaders/water.gdshader` e o teste novo.
- **Risco**: sem o corte da linha d'água, a margem rasa inteira viraria espuma. O anel continua pela diferença de profundidade, que
  cresce devagar no raso da margem, e o fio da margem (`river_foam_line_m`) fica de fora.
- **Como testar**: o teste do shader, a captura dos matacões da Fase 122 antes e depois e o benchmark.

## O que entrou

- **`shaders/water.gdshader`**, no bloco da espuma por profundidade, logo depois do anel da Fase 293, só no canal (`channel`):
  - o mesmo anel, até `rock_foam_m` × `river_foam_reach` (1,6) de diferença de profundidade;
  - sem o corte da linha d'água: só fica de fora a faixa de `river_foam_line_m` (0,6 m) junto da margem;
  - borbulhando mais depressa que o do mar;
  - somado por `max`, desligável por `river_foam`.

## Medida

71,8 FPS (317: 72,7), GPU 13,0 ms (317: 12,8). Objetos, draw calls e primitivas iguais. Neutra.

## Como testar

- `tests/world/test_phase318_river_foam.gd`: o anel do rio depois do do mar, só no canal, mais largo, com o fio da margem bem mais
  estreito que o corte do mar e somado por `max`; o shader compilando com os uniformes novos (com tela). O `test_phase293_rock_foam` e
  o `test_phase283_dark_river` seguem passando.
- Captura: `tools/capture_phase122.tscn -- <pasta>` (`rio_de_perto.png`); antes (`river_foam` em 0) e depois em
  `F:\ferramentas\capturas\fase318\rio_antes\` e `rio_depois\`. Na garganta funda do `tools/capture_phase317.tscn` a água quase não
  aparece.
