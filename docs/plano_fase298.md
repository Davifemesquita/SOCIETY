# Plano da Fase 298 — Mar escuro de longe

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_295_299.md`. O azul-petróleo das temperadas (Fase 280) era
o mesmo perto e longe; no Anno, o mar de longe é azul-marinho.

## O que entrou

- **`shaders/water.gdshader`**, de `far_sea_from_m` (200 m) a `far_sea_to_m` (700 m) da câmera:
  - a cor do fundo (`deep_color`, temperada e tropical) escurece até `far_sea_dark` (0,45) dela;
  - o reflexo do céu cai até `far_sea_specular` (0,4) dele.
- **O roteiro pedia o contrário**: deixar o reflexo do céu mais nítido de longe. Feito assim, o mar de longe ficava ainda mais claro.
- **Laboratório**: `CAPTURA_MAR=longe` no `tools/capture_phase295.tscn` (o mar ao longe com a câmera deitada, em cada combinação de
  `FAR_VARIANTS`). Ele mostrou que o horizonte claro vem do reflexo do céu no ângulo raso e da névoa, e não só da cor do fundo.
  - Tirar a cor de Fresnel do material do Ocean (um azul claro opaco) não escurece o horizonte e faz aparecerem listras: ela
    fica.
  - O efeito desta fase se vê mais no mar de cima (a 420 m) que no horizonte.

## Medida

GPU 12,6 ms (297: 12,5). Neutra.

## Como testar

- `tests/world/test_phase298_far_sea.gd`:
  - o fundo escurecendo pela distância antes de virar a cor da tela;
  - o reflexo caindo de longe;
  - o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase295.tscn -- <pasta>` (`03_mar_de_cima.png`, `04_mar_ao_longe.png`); `CAPTURA_MAR=longe` para o
  laboratório.
