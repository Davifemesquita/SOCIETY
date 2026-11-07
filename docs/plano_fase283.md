# Plano da Fase 283 — Rio escuro

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_280_284.md`. Os rios estreitos ficavam cobertos de espuma
branca de margem a margem. Toda a água deles fica perto da terra: as bandas, a espuma da beira e a espuma por profundidade do
Ocean valiam no rio inteiro. Os nenúfares da Fase 274 sumiam nela. No Anno, o rio é água escura e calma, com a margem de seixos
cinzentos.

## O que entrou

- **O canal estreito** (`shaders/water.gdshader`, `channel`): pelo mapa da costa, a água em que nenhum dos quatro pontos a
  `channel_probe_m` (12 m) em volta fica a mais de `channel_open_m` (10 m) da terra.
  - Pega o rio e a enseada fina; a praia aberta não.
  - As sondas só rodam perto da terra (`shore_m` abaixo de `channel_open_m`). Rodando em toda a água, custavam +0,2 ms de GPU.
- **Na água do canal**:
  - a cor escura `river_color` (com o `water_light` da Fase 282);
  - nem bandas nem espuma do Ocean;
  - a espuma da beira a 20%;
  - menos reflexo do céu (`SPECULAR`).
- **O cascalho** (`shaders/terrain.gdshader`, `gravel`, ligado pela `TerrainView` só nas temperadas): a lama da margem e do leito
  junto da água vira cascalho cinza.
  - É a textura de rocha `gravel_scale` vezes menor, com o relevo dela, escura e brilhante até `gravel_wet_m` acima da água.
  - Acima de `gravel_top_m` (2,5 m) volta à lama de antes: a borda de cima do barranco, o leito seco da cabeceira e as
    manchas no planalto.
  - Pela curvatura do vale, o cascalho saía em manchas cinza no meio do capim; por isso ficou só a altura.
  - A laterita das tropicais (Fase 170) não muda.
- **A captura** procura o rio com água (o leito abaixo de -0,5 m) e mostra também o leito seco (`05b_leito_seco.png`).
- **O antes e depois** foi tirado de um worktree no commit anterior (`F:\repos\society_ref`).

## Como testar

- `tests/world/test_phase283_dark_river.gd`:
  - os uniformes nos dois shaders compilados (com tela);
  - o canal com a cor do rio, sem as bandas e a espuma e com menos reflexo, com a sonda olhando mais longe que a largura dele;
  - o cascalho ligado nas temperadas e desligado nas tropicais.
- Captura: `tools/capture_phase280.tscn -- <pasta>` (o rio em `05_rio.png`, o leito seco em `05b_leito_seco.png`).
