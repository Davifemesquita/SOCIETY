# Plano da Fase 187 — Placa na encruzilhada

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_185_189.md` (hera, estaca e arco-íris, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SignpostView.junctions`): em cada célula de estrada de terra com três ou quatro estradas em volta pelos lados (o T
  e o cruzamento), sem casa a até `TOWN_CELLS` células (fora das vilas); nada no paralelepípedo nem na ilha plana. O poste fica a
  `POST_OFFSET_M` do meio da célula, do lado sem estrada (no T) ou no canto entre duas delas (no cruzamento).
- **A placa** (`post_mesh`, `arm_mesh`): o poste quadrado com o chapéu em pirâmide e uma tábua por estrada, cada uma numa altura
  (`ARM_HEIGHTS_M`), apontando a estrada, com a ponta em seta e os riscos escuros de uma inscrição (sem texto). Dois MultiMesh
  (`GameScreen.signpost_view`), refeitos quando as estradas mudam, na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase187_signposts.gd`: o cruzamento ganha o poste com quatro tábuas apontando as estradas, cada uma numa
  altura; o T põe o poste no lado sem estrada; nada na estrada reta, perto de casa, no paralelepípedo nem na ilha plana.
- Captura: `tools/capture_phase187.tscn` (um cruzamento e um T no campo da ilha principal, com a câmera posta à mão).
